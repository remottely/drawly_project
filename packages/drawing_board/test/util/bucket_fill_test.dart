import 'package:drawing_board/drawing_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bucketFill', () {
    test('fills entire empty canvas', () {
      final result = bucketFill(
        start: const Offset(0, 0),
        strokes: const [],
        canvasSize: const Size(5, 5),
        maxPixels: 100,
      );
      expect(result.length, 25);
    });

    test('respects simple border', () {
      final border = NormalStroke(
        points: const [
          Offset(0, 0),
          Offset(4, 0),
          Offset(4, 4),
          Offset(0, 4),
          Offset(0, 0),
        ],
        color: Colors.black,
      );

      final result = bucketFill(
        start: const Offset(2, 2),
        strokes: [border],
        canvasSize: const Size(5, 5),
        maxPixels: 100,
      );

      expect(result.every((p) => p.dx > 0 && p.dx < 4 && p.dy > 0 && p.dy < 4),
          isTrue);
    });
  });
}
