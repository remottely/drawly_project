import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:drawly_design_system/drawly_design_system.dart';

import 'package:drawing_board/src/domain/models/stroke.dart';

/// Flood fill algorithm used for [BucketStroke] rendering.
///
/// The algorithm converts every stroke on the canvas into an in-memory pixel
/// map, then performs a breadth first search starting from [start]. Pixels are
/// visited using an eight-way neighbourhood so that filled areas look square
/// instead of "diamond" shaped.
///
/// [strokes] should contain all strokes currently drawn on the canvas. The
/// resulting list contains all filled pixel coordinates relative to the logical
/// [canvasSize].
///
/// The [maxPixels] argument prevents unbounded growth on open canvases.
List<Offset> bucketFill({
  required Offset start,
  required List<Stroke> strokes,
  required Size canvasSize,
  int? maxPixels,
}) {
  // Normalize the starting point to the pixel grid using floor instead of
  // rounding to avoid shifting the fill by a whole pixel. Rounding caused the
  // fill to drift down-right when the user tapped near the top or left edge of
  // a pixel.
  final startPoint = Offset(start.dx.floorToDouble(), start.dy.floorToDouble());
  final width = canvasSize.width.ceil();
  final height = canvasSize.height.ceil();
  final pixelLimit = maxPixels ?? width * height;

  // Build an in-memory pixel map for all strokes. Each line segment is
  // interpolated so the fill algorithm can rely on continuous borders.
  final canvasMap = <Offset, Color>{};

  void plotPixel(Offset center, Stroke stroke) {
    final radius = stroke.size / 2;
    final bound = radius.ceil();
    final color = stroke.color.applyOpacity(stroke.opacity);
    for (var dx = -bound; dx <= bound; dx++) {
      for (var dy = -bound; dy <= bound; dy++) {
        if (Offset(dx.toDouble(), dy.toDouble()).distance <= radius) {
          final p = Offset(
            (center.dx + dx).roundToDouble(),
            (center.dy + dy).roundToDouble(),
          );
          canvasMap[p] = color;
        }
      }
    }
  }

  Iterable<Offset> _expandedPoints(Stroke stroke) {
    if (stroke is CircleStroke && stroke.points.length >= 2) {
      final first = stroke.points.first;
      final last = stroke.points.last;
      final center = Offset((first.dx + last.dx) / 2, (first.dy + last.dy) / 2);

      final radiusX = (last.dx - first.dx).abs() / 2;
      final radiusY = (last.dy - first.dy).abs() / 2;

      // Approximate the circumference of the ellipse to decide how many
      // segments are needed for a smooth outline.
      final circumference = 2 * pi *
          sqrt((pow(radiusX, 2) + pow(radiusY, 2)) / 2);
      final segments = max(circumference.ceil(), 12);

      final pts = <Offset>[];
      for (var i = 0; i <= segments; i++) {
        final angle = 2 * pi * i / segments;
        final x = center.dx + radiusX * cos(angle);
        final y = center.dy + radiusY * sin(angle);
        pts.add(Offset(x, y));
      }

      if (stroke.filled) {
        for (var x = (center.dx - radiusX).floor();
            x <= (center.dx + radiusX).ceil();
            x++) {
          for (var y = (center.dy - radiusY).floor();
              y <= (center.dy + radiusY).ceil();
              y++) {
            final nx = (x - center.dx) / (radiusX == 0 ? 1 : radiusX);
            final ny = (y - center.dy) / (radiusY == 0 ? 1 : radiusY);
            if (nx * nx + ny * ny <= 1) {
              pts.add(Offset(x.toDouble(), y.toDouble()));
            }
          }
        }
      }

      return pts;
    }

    if (stroke is SquareStroke && stroke.points.length >= 2) {
      final rect = Rect.fromPoints(stroke.points.first, stroke.points.last);
      final pts = <Offset>[rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft, rect.topLeft];
      if (stroke.filled) {
        for (var x = rect.left.floor(); x <= rect.right.ceil(); x++) {
          for (var y = rect.top.floor(); y <= rect.bottom.ceil(); y++) {
            pts.add(Offset(x.toDouble(), y.toDouble()));
          }
        }
      }
      return pts;
    }

    if (stroke is PolygonStroke && stroke.points.length >= 2) {
      final first = stroke.points.first;
      final last = stroke.points.last;
      final center = Offset((first.dx + last.dx) / 2, (first.dy + last.dy) / 2);
      final radius = (first - last).distance / 2;
      final pts = <Offset>[];
      final angleStep = 2 * pi / stroke.sides;
      const startAngle = -pi / 2;
      for (var i = 0; i <= stroke.sides; i++) {
        final angle = startAngle + i * angleStep;
        final x = center.dx + radius * cos(angle);
        final y = center.dy + radius * sin(angle);
        pts.add(Offset(x, y));
      }
      if (stroke.filled) {
        Rect bounds = Rect.fromPoints(first, last).inflate(radius);
        for (var x = bounds.left.floor(); x <= bounds.right.ceil(); x++) {
          for (var y = bounds.top.floor(); y <= bounds.bottom.ceil(); y++) {
            final p = Offset(x.toDouble(), y.toDouble());
            if (_pointInPolygon(p, pts)) {
              pts.add(p);
            }
          }
        }
      }
      return pts;
    }

    if (stroke is LineStroke) {
      return stroke.points;
    }

    return stroke.points;
  }

  bool _pointInPolygon(Offset point, List<Offset> polygon) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].dx, yi = polygon[i].dy;
      final xj = polygon[j].dx, yj = polygon[j].dy;
      final intersect = ((yi > point.dy) != (yj > point.dy)) &&
          (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi + 0.0) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  for (final stroke in strokes) {
    if (stroke is BucketStroke) {
      for (final p in stroke.fillPixels) {
        plotPixel(p, stroke);
      }
      continue;
    }

    final points = List<Offset>.from(_expandedPoints(stroke));
    if (points.isEmpty) continue;

    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final steps = max((p1 - p2).distance.ceil(), 1);
      for (var s = 0; s <= steps; s++) {
        final t = s / steps;
        final x = p1.dx + (p2.dx - p1.dx) * t;
        final y = p1.dy + (p2.dy - p1.dy) * t;
        plotPixel(Offset(x, y), stroke);
      }
    }

    if (points.length == 1) {
      plotPixel(points.first, stroke);
    }
  }

  Color? getColor(Offset p) {
    // Use floor to map arbitrary coordinates onto the pixel grid. This keeps
    // lookups consistent with the starting point normalization.
    final normalized = Offset(p.dx.floorToDouble(), p.dy.floorToDouble());
    return canvasMap[normalized];
  }

  bool inBounds(Offset p) =>
      p.dx >= 0 && p.dy >= 0 && p.dx < width && p.dy < height;

  final baseColor = getColor(startPoint);
  final visited = <Offset>{};
  final queue = Queue<Offset>()..add(startPoint);
  final fill = <Offset>[];

  while (queue.isNotEmpty && visited.length < pixelLimit) {
    final current = queue.removeFirst();
    final normalized = Offset(
      current.dx.floorToDouble(),
      current.dy.floorToDouble(),
    );
    if (!visited.add(normalized)) continue;
    if (!inBounds(normalized)) continue;

    final color = getColor(normalized);
    if (baseColor == null && color != null) continue;
    if (baseColor != null && color != baseColor) continue;

    fill.add(normalized);
    canvasMap[normalized] = const Color(0x00000000); // mark as filled

    queue.addAll([
      Offset(normalized.dx + 1, normalized.dy),
      Offset(normalized.dx - 1, normalized.dy),
      Offset(normalized.dx, normalized.dy + 1),
      Offset(normalized.dx, normalized.dy - 1),
      Offset(normalized.dx + 1, normalized.dy + 1),
      Offset(normalized.dx + 1, normalized.dy - 1),
      Offset(normalized.dx - 1, normalized.dy + 1),
      Offset(normalized.dx - 1, normalized.dy - 1),
    ]);
  }
  // Expand the fill area slightly to avoid visible unpainted borders when
  // using thick strokes. This compensates for anti-aliasing differences
  // between the canvas and the pixel map used by the fill algorithm.
  final expanded = <Offset>{...fill};
  const expansionIterations = 2;
  for (var i = 0; i < expansionIterations; i++) {
    final additions = <Offset>{};
    for (final p in expanded) {
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          final candidate = Offset(p.dx + dx, p.dy + dy);
          if (!inBounds(candidate)) continue;
          if (canvasMap[candidate] != null) continue;
          additions.add(candidate);
        }
      }
    }
    expanded.addAll(additions);
  }

  return expanded.toList();
}
