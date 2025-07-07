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
      );

      expect(result.every((p) => p.dx > 0 && p.dx < 4 && p.dy > 0 && p.dy < 4),
          isTrue);
    });

    test('fills diagonally connected area', () {
      final block1 = NormalStroke(points: const [Offset(1, 0)], color: Colors.black);
      final block2 = NormalStroke(points: const [Offset(0, 1)], color: Colors.black);

      final result = bucketFill(
        start: const Offset(0, 0),
        strokes: [block1, block2],
        canvasSize: const Size(3, 3),
      );

      expect(result.length, 7);
      expect(result.contains(const Offset(1, 0)), isFalse);
      expect(result.contains(const Offset(0, 1)), isFalse);
    });
  });
}
