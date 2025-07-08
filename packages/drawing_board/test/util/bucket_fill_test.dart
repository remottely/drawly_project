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

    test('uses previous bucket fills when computing new fill', () {
      final firstFill = bucketFill(
        start: const Offset(0, 0),
        strokes: const [],
        canvasSize: const Size(3, 3),
      );

      final bucket = BucketStroke(
        points: const [Offset(0, 0)],
        color: Colors.red,
        fillPixels: firstFill,
      );

      final result = bucketFill(
        start: const Offset(2, 2),
        strokes: [bucket],
        canvasSize: const Size(3, 3),
      );

      expect(result.length, 9);
    });

    test('respects circle border', () {
      final circle = CircleStroke(
        points: const [Offset(1, 1), Offset(3, 3)],
        color: Colors.black,
      );

      final result = bucketFill(
        start: const Offset(2, 2),
        strokes: [circle],
        canvasSize: const Size(5, 5),
      );

      final center = const Offset(2, 2);
      final radiusX = (circle.points.last.dx - circle.points.first.dx).abs() / 2;
      final radiusY = (circle.points.last.dy - circle.points.first.dy).abs() / 2;

      bool insideEllipse(Offset p) {
        final nx = (p.dx - center.dx) / (radiusX == 0 ? 1 : radiusX);
        final ny = (p.dy - center.dy) / (radiusY == 0 ? 1 : radiusY);
        return nx * nx + ny * ny < 1;
      }

      expect(result.every(insideEllipse), isTrue);
    });

    test('fills area up to thick border without gaps', () {
      final border = NormalStroke(
        points: const [
          Offset(0, 0),
          Offset(9, 0),
          Offset(9, 9),
          Offset(0, 9),
          Offset(0, 0),
        ],
        color: Colors.black,
        size: 4,
      );

      final result = bucketFill(
        start: const Offset(5, 5),
        strokes: [border],
        canvasSize: const Size(10, 10),
      );

      for (var x = 3; x <= 6; x++) {
        for (var y = 3; y <= 6; y++) {
          expect(result.contains(Offset(x.toDouble(), y.toDouble())), isTrue);
        }
      }
    });

    test('fractional start does not shift filled area', () {
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
        start: const Offset(1.7, 1.8),
        strokes: [border],
        canvasSize: const Size(5, 5),
      );

      for (var x = 1; x <= 3; x++) {
        for (var y = 1; y <= 3; y++) {
          expect(result.contains(Offset(x.toDouble(), y.toDouble())), isTrue);
        }
      }
    });
  });
}
