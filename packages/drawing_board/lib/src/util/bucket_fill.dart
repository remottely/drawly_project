import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import '../domain/models/stroke.dart';

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
  int maxPixels = 20000,
}) {
  final startPoint = Offset(start.dx.floorToDouble(), start.dy.floorToDouble());
  final width = canvasSize.width.floor();
  final height = canvasSize.height.floor();

  // Build an in-memory pixel map for all strokes. Each line segment is
  // interpolated so the fill algorithm can rely on continuous borders.
  final canvasMap = <Offset, Color>{};

  void plotPixel(Offset center, Stroke stroke) {
    final radius = stroke.size.ceil();
    for (var dx = -radius; dx <= radius; dx++) {
      for (var dy = -radius; dy <= radius; dy++) {
        final p = Offset(
          (center.dx + dx).floorToDouble(),
          (center.dy + dy).floorToDouble(),
        );
        canvasMap[p] = stroke.color;
      }
    }
  }

  for (final stroke in strokes) {
    if (stroke.points.isEmpty) continue;
    for (var i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];
      final steps = max((p1 - p2).distance.ceil(), 1);
      for (var s = 0; s <= steps; s++) {
        final t = s / steps;
        final x = p1.dx + (p2.dx - p1.dx) * t;
        final y = p1.dy + (p2.dy - p1.dy) * t;
        plotPixel(Offset(x, y), stroke);
      }
    }

    if (stroke.points.length == 1) {
      plotPixel(stroke.points.first, stroke);
    }
  }

  Color? getColor(Offset p) {
    final normalized = Offset(p.dx.floorToDouble(), p.dy.floorToDouble());
    return canvasMap[normalized];
  }

  bool inBounds(Offset p) =>
      p.dx >= 0 && p.dy >= 0 && p.dx < width && p.dy < height;

  final baseColor = getColor(startPoint);
  final visited = <Offset>{};
  final queue = Queue<Offset>()..add(startPoint);
  final fill = <Offset>[];

  while (queue.isNotEmpty && visited.length < maxPixels) {
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
    canvasMap[normalized] = Color(0); // mark as filled

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

  return fill;
}
