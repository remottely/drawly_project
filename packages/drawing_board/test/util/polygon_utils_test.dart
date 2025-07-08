import 'package:drawing_board/src/util/polygon_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui';

void main() {
  const canvasSize = Size(500, 500 / (16 / 9));

  test('clamps radius to canvas bounds', () {
    const first = Offset(0, 0);
    const last = Offset(canvasSize.width, canvasSize.height);

    final radius = calculateClampedPolygonRadius(
      firstPoint: first,
      lastPoint: last,
      canvasSize: canvasSize,
    );

    expect(radius, equals(canvasSize.height / 2));
  });
}
