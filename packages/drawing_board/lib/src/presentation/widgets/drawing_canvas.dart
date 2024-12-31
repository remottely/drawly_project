import 'dart:developer' as developer;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:drawing_board/src/src.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    required this.rxAllStrokes,
    required this.rxCurrentStroke,
    required this.options,
    // this.onDrawingStrokeChanged,
    required this.canvasGlobalKey,
    required this.username,
    required this.roomName,
    super.key,
    this.rxBackgroundImage,
  })  : assert(
          username.length >= 3,
          'The username must be at least 3 characters long',
        ),
        assert(
          roomName.length >= 3,
          'The roomName must be at least 3 characters long',
        );

  final ValueNotifier<List<Stroke>> rxAllStrokes;
  final ValueNotifier<ui.Image?>? rxBackgroundImage;
  final CurrentStrokeValueNotifier rxCurrentStroke;
  final DrawingCanvasOptions options;
  // final Function(Stroke?)? onDrawingStrokeChanged;
  final GlobalKey canvasGlobalKey;
  final String username;
  final String roomName;

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

abstract class DrawingCanvasViewModel extends State<DrawingCanvas> {
  CurrentStrokeValueNotifier get rxCurrentStroke => widget.rxCurrentStroke;
  ValueNotifier<List<Stroke>> get rxAllStrokes => widget.rxAllStrokes;

  final double _canvasSize = 500;

  final rxIsShowGrid = ValueNotifier<bool>(false);
  Color get strokeColor => widget.options.strokeColor;
  double get size => widget.options.size;
  double get opacity => widget.options.opacity;
  DrawingTool get currentTool => widget.options.currentTool;

  late final void Function(dynamic) _onConnectEvent;
  late final void Function(dynamic) _onDrawDrawingEvent;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  @override
  void dispose() {
    SocketManager.instance.offEvent('connect', _onConnectEvent);
    SocketManager.instance.offEvent('drawing:draw', _onDrawDrawingEvent);
    super.dispose();
  }

  void _initializeSocket() {
    _onConnectEvent = (_) {
      rxAllStrokes.value = [];
    };
    _onDrawDrawingEvent = (data) {
      developer.log('Draw event received: $data');
      final newStrokes = (data as Map<String, dynamic>)['strokes'];
      try {
        final receivedStrokes = (newStrokes as List<dynamic>)
            .map(
              (e) => Stroke.fromJson(
                Map<String, dynamic>.from(e as Map<String, dynamic>),
              ),
            )
            .toList();

        rxAllStrokes.value = List<Stroke>.from(rxAllStrokes.value)
          ..addAll(
            receivedStrokes
                .where((stroke) => !rxAllStrokes.value.contains(stroke)),
          );
      } catch (e, stackTrace) {
        developer.log(
          'Error processing draw event: $e',
          error: e,
          stackTrace: stackTrace,
        );
      }
    };

    SocketManager.instance.onEvent('connect', _onConnectEvent);
    SocketManager.instance.onEvent('drawing:draw', _onDrawDrawingEvent);
  }

  double _calculateScale(BoxConstraints constraints) {
    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;

    final canvasWidth = availableWidth;
    final canvasHeight = availableWidth / (16 / 9);

    if (canvasHeight > availableHeight) {
      return availableHeight / (9 * (_canvasSize / 16));
    } else {
      return canvasWidth / _canvasSize;
    }
  }

  bool _isInsideCanvas(Offset point) {
    final canvasWidth = _canvasSize;
    final canvasHeight = _canvasSize / (16 / 9);

    return point.dx >= 0 &&
        point.dx <= canvasWidth &&
        point.dy >= 0 &&
        point.dy <= canvasHeight;
  }

  void _sendBufferedPoints() {
    if (rxCurrentStroke.value == null) return;

    final payload = RoomDrawingDTO(
      roomName: widget.roomName,
      strokes: [rxCurrentStroke.value!],
    ).toJson();

    SocketManager.instance.emit('drawing:draw', payload);

    rxCurrentStroke.clear();
  }
}

class _DrawingCanvasState extends DrawingCanvasViewModel {
  @override
  Widget build(BuildContext context) {
    rxIsShowGrid.value = widget.options.showGrid;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = _calculateScale(constraints);

        return Transform.scale(
          scale: scale,
          child: Center(
            child: DrawlyContainer(
              color: widget.options.backgroundColor,
              width: _canvasSize,
              height: _canvasSize / (16 / 9),
              child: MouseRegion(
                cursor: widget.options.currentTool.cursor,
                child: Listener(
                  onPointerDown: (details) {
                    final localPosition = details.localPosition;
                    if (_isInsideCanvas(localPosition)) {
                      rxCurrentStroke.startStroke(
                        localPosition,
                        color: strokeColor,
                        size: size / scale,
                        opacity: opacity,
                        type: currentTool.strokeType,
                        sides: widget.options.polygonSides,
                        filled: widget.options.fillShape,
                      );
                      // widget.onDrawingStrokeChanged?
                      // .call(rxCurrentStroke.value);
                    }
                  },
                  onPointerMove: (details) {
                    final localPosition = details.localPosition;
                    if (_isInsideCanvas(localPosition)) {
                      rxCurrentStroke.addPoint(localPosition);
                      // widget.onDrawingStrokeChanged?
                      // .call(rxCurrentStroke.value);
                    }
                  },
                  onPointerUp: (_) {
                    if (rxCurrentStroke.hasStroke) {
                      _sendBufferedPoints();
                      // widget.onDrawingStrokeChanged?.call(null);
                    }
                  },
                  child: RepaintBoundary(
                    key: widget.canvasGlobalKey,
                    child: CustomPaint(
                      isComplex: true,
                      painter: _DrawingCanvasPainter(
                        rxAllStrokes: rxAllStrokes,
                        rxCurrentStroke: rxCurrentStroke,
                        backgroundColor: widget.options.backgroundColor,
                        rxIsShowGrid: rxIsShowGrid,
                        rxBackgroundImage: widget.rxBackgroundImage,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DrawingCanvasPainter extends CustomPainter {
  _DrawingCanvasPainter({
    this.rxAllStrokes,
    this.rxCurrentStroke,
    this.backgroundColor = Colors.white,
    this.rxIsShowGrid,
    this.rxBackgroundImage,
  }) : super(
          repaint: Listenable.merge(
            [
              rxAllStrokes,
              rxCurrentStroke,
              rxIsShowGrid,
              rxBackgroundImage,
            ],
          ),
        );
  final ValueNotifier<List<Stroke>>? rxAllStrokes;
  final CurrentStrokeValueNotifier? rxCurrentStroke;
  final Color backgroundColor;
  final ValueNotifier<bool>? rxIsShowGrid;
  final ValueNotifier<ui.Image?>? rxBackgroundImage;

  @override
  void paint(Canvas canvas, Size size) {
    if (rxBackgroundImage != null) {
      final backgroundImage = rxBackgroundImage!.value;

      if (backgroundImage != null) {
        canvas.drawImageRect(
          backgroundImage,
          Rect.fromLTWH(
            0,
            0,
            backgroundImage.width.toDouble(),
            backgroundImage.height.toDouble(),
          ),
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint(),
        );
      }
    }

    final allStrokes = List<Stroke>.from(rxAllStrokes?.value ?? []);

    if (rxCurrentStroke?.hasStroke ?? false) {
      allStrokes.add(rxCurrentStroke!.value!);
    }

    for (final stroke in allStrokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color.withOpacity(stroke.opacity)
        ..strokeWidth = stroke.size
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke is NormalStroke) {
        if (stroke.points.length == 1) {
          final center = stroke.points.first;
          final radius = stroke.size / 2;
          canvas.drawCircle(center, radius, paint..style = PaintingStyle.fill);
        } else {
          final path = Path()
            ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
          for (var i = 1; i < stroke.points.length; i++) {
            path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
          }
          canvas.drawPath(path, paint);
        }
      }

      if (stroke is EraserStroke) {
        final eraserPaint = Paint()
          ..color = backgroundColor
          ..strokeWidth = stroke.size
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        final path = Path()
          ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (var i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        canvas.drawPath(path, eraserPaint);
      }

      if (stroke is LineStroke) {
        if (stroke.points.length >= 2) {
          final firstPoint = stroke.points.first;
          final lastPoint = stroke.points.last;
          canvas.drawLine(firstPoint, lastPoint, paint);
        }
      }

      if (stroke is CircleStroke) {
        if (stroke.points.length >= 2) {
          final firstPoint = stroke.points.first;
          final lastPoint = stroke.points.last;
          final rect = Rect.fromPoints(firstPoint, lastPoint);
          paint.style =
              stroke.filled ? PaintingStyle.fill : PaintingStyle.stroke;
          canvas.drawOval(rect, paint);
        }
      }

      if (stroke is SquareStroke) {
        if (stroke.points.length >= 2) {
          final firstPoint = stroke.points.first;
          final lastPoint = stroke.points.last;
          final rect = Rect.fromPoints(firstPoint, lastPoint);
          paint.style =
              stroke.filled ? PaintingStyle.fill : PaintingStyle.stroke;
          canvas.drawRect(rect, paint);
        }
      }

      if (stroke is PolygonStroke) {
        if (stroke.points.length >= 2) {
          final firstPoint = stroke.points.first;
          final lastPoint = stroke.points.last;
          final center = Offset(
            (firstPoint.dx + lastPoint.dx) / 2,
            (firstPoint.dy + lastPoint.dy) / 2,
          );
          final radius = (firstPoint - lastPoint).distance / 2;
          final path = Path();
          final angleStep = (2 * pi) / stroke.sides;
          const startAngle = -pi / 2;

          path.moveTo(
            center.dx + radius * cos(startAngle),
            center.dy + radius * sin(startAngle),
          );

          for (var i = 1; i <= stroke.sides; i++) {
            final angle = startAngle + i * angleStep;
            final x = center.dx + radius * cos(angle);
            final y = center.dy + radius * sin(angle);
            path.lineTo(x, y);
          }

          path.close();
          paint.style =
              stroke.filled ? PaintingStyle.fill : PaintingStyle.stroke;
          canvas.drawPath(path, paint);
        }
      }
    }

    if (rxIsShowGrid?.value ?? false) {
      _drawGrid(size, canvas);
    }
  }

  void _drawGrid(Size size, Canvas canvas) {
    const gridStrokeWidth = 1.0;
    const gridSpacing = 50.0;
    const subGridSpacing = 10.0;
    const subGridStrokeWidth = 0.5;

    final gridPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..strokeWidth = gridStrokeWidth;

    final subGridPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..strokeWidth = subGridStrokeWidth;

    for (var y = 0.0; y <= size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var x = 0.0; x <= size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (var y = 0.0; y <= size.height; y += gridSpacing) {
      for (var subY = y;
          subY < y + gridSpacing && subY <= size.height;
          subY += subGridSpacing) {
        canvas.drawLine(
          Offset(0, subY),
          Offset(size.width, subY),
          subGridPaint,
        );
      }
    }

    for (var x = 0.0; x <= size.width; x += gridSpacing) {
      for (var subX = x;
          subX < x + gridSpacing && subX <= size.width;
          subX += subGridSpacing) {
        canvas.drawLine(
          Offset(subX, 0),
          Offset(subX, size.height),
          subGridPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
