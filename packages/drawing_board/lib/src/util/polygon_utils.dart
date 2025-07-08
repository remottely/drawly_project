import 'dart:math' as math;
import 'dart:ui';

/// Computes a polygon radius that never exceeds the canvas boundaries.
///
/// [firstPoint] and [lastPoint] are the stroke points used to draw the shape.
/// [canvasSize] is the logical size of the drawing canvas.
/// The returned radius is clamped so that the resulting polygon is fully
/// contained within the canvas rectangle.
double calculateClampedPolygonRadius({
  required Offset firstPoint,
  required Offset lastPoint,
  required Size canvasSize,
}) {
  final center = Offset(
    (firstPoint.dx + lastPoint.dx) / 2,
    (firstPoint.dy + lastPoint.dy) / 2,
  );

  final tentativeRadius = (firstPoint - lastPoint).distance / 2;

  final maxRadius = math.min(
    math.min(center.dx, canvasSize.width - center.dx),
    math.min(center.dy, canvasSize.height - center.dy),
  );

  return math.min(tentativeRadius, maxRadius);
}
