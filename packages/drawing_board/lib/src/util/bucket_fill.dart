import 'dart:collection';
import 'dart:ui';

import '../domain/models/stroke.dart';

/// Flood fill algorithm used for BucketStroke rendering.
///
/// [start] is the starting pixel tapped by the user.
/// [strokes] contains all strokes currently drawn on the canvas.
/// [canvasSize] is the logical canvas size.
/// [maxPixels] limits how many pixels will be processed to avoid
/// unbounded loops on open shapes.
List<Offset> bucketFill({
  required Offset start,
  required List<Stroke> strokes,
  required Size canvasSize,
  int maxPixels = 20000,
}) {
  final startPoint = Offset(start.dx.floorToDouble(), start.dy.floorToDouble());
  final width = canvasSize.width.floor();
  final height = canvasSize.height.floor();

  // Map each drawn pixel to its color.
  final canvasMap = <Offset, Color>{};
  for (final stroke in strokes) {
    for (final point in stroke.points) {
      final p = Offset(point.dx.floorToDouble(), point.dy.floorToDouble());
      canvasMap[p] = stroke.color;
    }
  }

  Color? getColor(Offset p) =>
      canvasMap[Offset(p.dx.floorToDouble(), p.dy.floorToDouble())];

  bool inBounds(Offset p) =>
      p.dx >= 0 && p.dy >= 0 && p.dx < width && p.dy < height;

  final baseColor = getColor(startPoint);
  final visited = <Offset>{};
  final queue = Queue<Offset>()..add(startPoint);
  final fill = <Offset>[];

  while (queue.isNotEmpty && visited.length < maxPixels) {
    final current = queue.removeFirst();
    if (!visited.add(current)) continue;
    if (!inBounds(current)) continue;

    final color = getColor(current);
    if (baseColor == null && color != null) continue;
    if (baseColor != null && color != baseColor) continue;

    fill.add(current);
    canvasMap[current] = Color(0); // mark as filled

    queue.addAll([
      Offset(current.dx + 1, current.dy),
      Offset(current.dx - 1, current.dy),
      Offset(current.dx, current.dy + 1),
      Offset(current.dx, current.dy - 1),
    ]);
  }

  return fill;
}
