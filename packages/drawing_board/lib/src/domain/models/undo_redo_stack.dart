import 'package:drawing_board/src/src.dart';
import 'package:flutter/material.dart';

class UndoRedoStack {
  UndoRedoStack({
    required this.rxAllStrokes,
    required this.rxCurrentStroke,
  }) {
    _strokeCount = rxAllStrokes.value.length;
    rxAllStrokes.addListener(_strokesCountListener);
    _rxCanRedo = ValueNotifier(_redoStack.isNotEmpty);
  }

  final ValueNotifier<List<Stroke>> rxAllStrokes;
  final ValueNotifier<Stroke?> rxCurrentStroke;
  List<Stroke>? _redoStackInternal;
  List<Stroke> get _redoStack => _redoStackInternal ??= [];

  late final ValueNotifier<bool> _rxCanRedo;
  ValueNotifier<bool> get rxCanRedo => _rxCanRedo;

  late int _strokeCount;

  bool _isRedoing = false;

  void _strokesCountListener() {
    if (!_isRedoing && rxAllStrokes.value.length > _strokeCount) {
      _redoStack.clear();
      _rxCanRedo.value = false;
      _strokeCount = rxAllStrokes.value.length;
    }
  }

  void clear() {
    _strokeCount = 0;
    rxAllStrokes.value = [];
    _redoStackInternal?.clear();
    rxCurrentStroke.value = null;
    _rxCanRedo.value = false;
  }

  void undo() {
    if (rxAllStrokes.value.isNotEmpty) {
      _strokeCount--;
      final allStrokes = List<Stroke>.from(rxAllStrokes.value);
      _redoStack.add(allStrokes.removeLast());
      rxAllStrokes.value = allStrokes;
      _rxCanRedo.value = _redoStack.isNotEmpty;
      rxCurrentStroke.value = null;
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _isRedoing = true;

      final allStrokes = List<Stroke>.from(rxAllStrokes.value)
        ..add(_redoStack.removeLast());
      rxAllStrokes.value = allStrokes;
      _rxCanRedo.value = _redoStack.isNotEmpty;
      _strokeCount++;

      _isRedoing = false;
    }
  }

  void dispose() {
    rxAllStrokes.removeListener(_strokesCountListener);
  }
}
