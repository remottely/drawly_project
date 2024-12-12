import 'package:drawing_board/src/src.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UndoRedoStack Tests', () {
    late ValueNotifier<List<Stroke>> rxAllStrokes;
    late ValueNotifier<Stroke?> rxCurrentStroke;
    late UndoRedoStack undoRedoStack;

    setUp(() {
      rxAllStrokes = ValueNotifier([]);
      rxCurrentStroke = ValueNotifier(null);
      undoRedoStack = UndoRedoStack(
        rxAllStrokes: rxAllStrokes,
        rxCurrentStroke: rxCurrentStroke,
      );
    });

    test('Initial State', () {
      expect(rxAllStrokes.value, isEmpty);
      expect(rxCurrentStroke.value, isNull);
      expect(undoRedoStack.rxCanRedo.value, isFalse);
    });

    test('Add Stroke and Undo', () {
      final stroke = NormalStroke(points: [Offset.zero]);
      rxAllStrokes.value = [stroke];

      undoRedoStack.undo();
      expect(rxAllStrokes.value, isEmpty);
      expect(undoRedoStack.rxCanRedo.value, isTrue);
    });

    test('Redo Operation', () {
      final stroke = NormalStroke(points: [Offset.zero]);
      rxAllStrokes.value = [stroke];

      // First, perform an undo
      undoRedoStack.undo();
      expect(rxAllStrokes.value, isEmpty);
      expect(undoRedoStack.rxCanRedo.value, isTrue);

      // Now, test the redo functionality
      undoRedoStack.redo();
      expect(rxAllStrokes.value, isNotEmpty);
      expect(rxAllStrokes.value.length, equals(1));
      expect(undoRedoStack.rxCanRedo.value, isFalse);
    });

    test('Clear Operation', () {
      undoRedoStack.clear();
      expect(rxAllStrokes.value, isEmpty);
      expect(rxCurrentStroke.value, isNull);
      expect(undoRedoStack.rxCanRedo.value, isFalse);
    });
  });
}
