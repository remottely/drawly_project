import 'package:drawing_board/src/src.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class DrawingCanvasOptions {
  const DrawingCanvasOptions({
    this.strokeColor = AppColors.blackAccent,
    this.size = 10,
    this.opacity = 1,
    this.currentTool = DrawingTool.pencil,
    this.backgroundColor = AppColors.lightAccent,
    this.showGrid = false,
    this.polygonSides = 3,
    this.fillShape = false,
  });

  final Color strokeColor;
  final double size;
  final double opacity;
  final DrawingTool currentTool;
  final Color backgroundColor;
  final bool showGrid;
  final int polygonSides;
  final bool fillShape;

  DrawingCanvasOptions copyWith({
    Color? strokeColor,
    double? size,
    double? opacity,
    DrawingTool? currentTool,
    Color? backgroundColor,
    bool? showGrid,
    int? polygonSides,
    bool? fillShape,
  }) {
    return DrawingCanvasOptions(
      strokeColor: strokeColor ?? this.strokeColor,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      currentTool: currentTool ?? this.currentTool,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showGrid: showGrid ?? this.showGrid,
      polygonSides: polygonSides ?? this.polygonSides,
      fillShape: fillShape ?? this.fillShape,
    );
  }
}
