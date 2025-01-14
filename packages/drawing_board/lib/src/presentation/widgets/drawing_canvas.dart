import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:drawing_board/src/src.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

const double _canvasSize = 500;

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
    // this.rxBackgroundImage,
  })  : assert(
          username.length >= 3,
          'The username must be at least 3 characters long',
        ),
        assert(
          roomName.length >= 3,
          'The roomName must be at least 3 characters long',
        );

  final ValueNotifier<List<Stroke>> rxAllStrokes;
  // final ValueNotifier<ui.Image?>? rxBackgroundImage;
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

  final int _bufferDelay = 50;

  final rxIsShowGrid = ValueNotifier<bool>(false);
  Color get strokeColor => widget.options.strokeColor;
  double get size => widget.options.size;
  double get opacity => widget.options.opacity;
  DrawingTool get currentTool => widget.options.currentTool;

  late final void Function(dynamic) _onConnectEvent;
  late final void Function(dynamic) _onAllStrokesDrawingEvent;
  late final void Function(dynamic) _onStrokeStartDrawingEvent;
  late final void Function(dynamic) _onStrokeLastPointsDrawingEvent;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _startDrawingPointsBuffer();
  }

  @override
  void dispose() {
    SocketManager.instance.offEvent('connect', _onConnectEvent);
    SocketManager.instance
        .offEvent('drawing:stroke:all', _onAllStrokesDrawingEvent);
    SocketManager.instance
        .offEvent('drawing:stroke:start', _onStrokeStartDrawingEvent);
    SocketManager.instance
        .offEvent('drawing:stroke:lastPoints', _onStrokeLastPointsDrawingEvent);
    super.dispose();
  }

  void _initializeSocket() {
    _onConnectEvent = (_) {
      rxAllStrokes.value = [];
    };

    _onAllStrokesDrawingEvent = (data) {
      try {
        final allStrokes = (data as Map<String, dynamic>)['strokes'];
        final receivedAllStrokes = (allStrokes as List<dynamic>)
            .map(
              (e) => Stroke.fromJson(
                Map<String, dynamic>.from(e as Map<String, dynamic>),
              ),
            )
            .toList();

        rxAllStrokes.value = List<Stroke>.from(rxAllStrokes.value)
          ..addAll(
            receivedAllStrokes
                .where((stroke) => !rxAllStrokes.value.contains(stroke)),
          );
      } catch (e, stackTrace) {
        developer.log(
          'Error processing drawing:stroke:all event: $e',
          error: e,
          stackTrace: stackTrace,
        );
      }
    };

    _onStrokeStartDrawingEvent = (data) {
      try {
        final newStroke = (data as Map<String, dynamic>)['stroke'];
        final receivedStroke = Stroke.fromJson(
          Map<String, dynamic>.from(newStroke as Map<String, dynamic>),
        );

        rxAllStrokes.value = List<Stroke>.from(rxAllStrokes.value)
          ..add(receivedStroke);
      } catch (e, stackTrace) {
        developer.log(
          'Error processing drawing:stroke:start event: $e',
          error: e,
          stackTrace: stackTrace,
        );
      }
    };

    _onStrokeLastPointsDrawingEvent = (data) {
      try {
        final strokeLastPoints =
            (data as Map<String, dynamic>)['strokeLastPoints'];
        final receivedStrokeLastPoints = (strokeLastPoints as List<dynamic>)
            .map(
              (point) => Offset(
                (point as Map<String, dynamic>)['dx'] as double,
                point['dy'] as double,
              ),
            )
            .toList();

        rxAllStrokes.value = List<Stroke>.from(rxAllStrokes.value)
          ..last.points.addAll(
                receivedStrokeLastPoints.where(
                  (point) => !rxAllStrokes.value.last.points.contains(point),
                ),
              );
      } catch (e, stackTrace) {
        developer.log(
          'Error processing drawing:stroke:lastPoints event: $e',
          error: e,
          stackTrace: stackTrace,
        );
      }
    };

    SocketManager.instance.onEvent('connect', _onConnectEvent);
    SocketManager.instance
        .onEvent('drawing:stroke:all', _onAllStrokesDrawingEvent);
    SocketManager.instance
        .onEvent('drawing:stroke:start', _onStrokeStartDrawingEvent);
    SocketManager.instance
        .onEvent('drawing:stroke:lastPoints', _onStrokeLastPointsDrawingEvent);
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

  bool _isPointInsideCanvas(Offset point) {
    const canvasWidth = _canvasSize;
    const canvasHeight = _canvasSize / (16 / 9);

    return point.dx >= 0 &&
        point.dx <= canvasWidth &&
        point.dy >= 0 &&
        point.dy <= canvasHeight;
  }

  /// Starts a periodic timer to send points to the server
  void _startDrawingPointsBuffer() {
    Timer.periodic(Duration(milliseconds: _bufferDelay), (_) {
      _sendBufferedDrawingPoints();
    });
  }

  void _sendDrawingPointsStart() {
    if (rxCurrentStroke.value == null) return;

    final payload = RoomDrawingStartStrokeDTO(
      roomName: widget.roomName,
      stroke: rxCurrentStroke.value!,
    ).toJson();

    SocketManager.instance.emit('drawing:stroke:start', payload);
  }

  void _sendDrawingPointsEnd() {
    if (rxCurrentStroke.value?.points == null) return;

    rxCurrentStroke.clear();
  }

  void _sendBufferedDrawingPoints() {
    if (rxCurrentStroke.value?.points == null ||
        rxCurrentStroke.value!.points.isEmpty) return;

    final payload = RoomDrawingStrokePointsDTO(
      roomName: widget.roomName,
      strokeLastPoints: rxCurrentStroke.value!.points,
    ).toJson();

    SocketManager.instance.emit('drawing:stroke:lastPoints', payload);
    rxCurrentStroke.value!.points.clear();
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
                    if (_isPointInsideCanvas(localPosition)) {
                      // rxCurrentStroke.startStroke(
                      //   localPosition,
                      //   color: strokeColor,
                      //   size: size / scale, // TODO: NOW
                      //   opacity: opacity,
                      //   type: currentTool.strokeType,
                      //   sides: widget.options.polygonSides,
                      //   filled: widget.options.fillShape,
                      // );
                      // _sendDrawingPointsStart();
                      // // rxAllStrokes.value = List<Stroke>.from(rxAllStrokes.value)
                      // //   ..last.points.add(localPosition);
                      // // widget.onDrawingStrokeChanged?
                      // // .call(rxCurrentStroke.value);
                      // if (currentTool.isBucket) {
                      //   // chatgpt: quero mudar a logica, preciso q vc crie um objeto q contorne tudo q estiver no canvas, for da mesma cor e nao tiver limites entre outras cores, assim comoo é feito com o bucket de qualquer sistema
                      //   _applyBucketFill(localPosition, scale);
                      // } else {
                      rxCurrentStroke.startStroke(
                        localPosition,
                        color: strokeColor,
                        size: size / scale, // TODO: NOW
                        opacity: opacity,
                        type: currentTool.strokeType,
                        sides: widget.options.polygonSides,
                        filled: widget.options.fillShape,
                      );
                      _sendDrawingPointsStart();
                      // rxAllStrokes.value = List<Stroke>.from(rxAllStrokes.value)
                      //   ..last.points.add(localPosition);
                      // widget.onDrawingStrokeChanged?
                      // .call(rxCurrentStroke.value);
                      // }
                    }
                  },
                  onPointerMove: (details) {
                    final localPosition = details.localPosition;
                    if (_isPointInsideCanvas(localPosition)) {
                      if (currentTool.isBucket) {
                        return;
                      } else {
                        rxCurrentStroke.addPoint(localPosition);
                      }
                      // widget.onDrawingStrokeChanged?
                      // .call(rxCurrentStroke.value);
                    }
                  },
                  onPointerUp: (_) {
                    // if (currentTool.isBucket) {
                    //   return;
                    // } else {
                    _sendDrawingPointsEnd();
                    // }
                    // if (rxCurrentStroke.hasStroke) {
                    //   _sendBufferedDrawingPoints();
                    //   // widget.onDrawingStrokeChanged?.call(null);
                    // }
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
                        // rxBackgroundImage: widget.rxBackgroundImage,
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
    // this.rxBackgroundImage,
  }) : super(
          repaint: Listenable.merge(
            [
              rxAllStrokes,
              rxCurrentStroke,
              rxIsShowGrid,
              // rxBackgroundImage,
            ],
          ),
        );
  final ValueNotifier<List<Stroke>>? rxAllStrokes;
  final CurrentStrokeValueNotifier? rxCurrentStroke;
  final Color backgroundColor;
  final ValueNotifier<bool>? rxIsShowGrid;
  // final ValueNotifier<ui.Image?>? rxBackgroundImage;

  @override
  void paint(Canvas canvas, Size size) {
    // if (rxBackgroundImage != null) {
    //   final backgroundImage = rxBackgroundImage!.value;

    //   if (backgroundImage != null) {
    //     canvas.drawImageRect(
    //       backgroundImage,
    //       Rect.fromLTWH(
    //         0,
    //         0,
    //         backgroundImage.width.toDouble(),
    //         backgroundImage.height.toDouble(),
    //       ),
    //       Rect.fromLTWH(0, 0, size.width, size.height),
    //       Paint(),
    //     );
    //   }
    // }

    final allStrokes = List<Stroke>.from(rxAllStrokes?.value ?? []);

    if (rxCurrentStroke?.hasStroke ?? false) {
      // TODO(Kevin): do something here?
      // allStrokes.add(rxCurrentStroke!.value!);
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

      if (stroke is BucketStroke) {
        // TODO: KEVIN NOW
        final newBucketStroke = _applyBucketFill(stroke, allStrokes);
        final path = Path()
          ..moveTo(
            newBucketStroke.points.first.dx,
            newBucketStroke.points.first.dy,
          );
        for (var i = 1; i < newBucketStroke.points.length; i++) {
          path.lineTo(
            newBucketStroke.points[i].dx,
            newBucketStroke.points[i].dy,
          );
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }

    if (rxIsShowGrid?.value ?? false) {
      drawGrid(size, canvas);
    }
  }

  void drawGrid(Size size, Canvas canvas) {
    const gridStrokeWidth = 1.0;
    const gridSpacing = 50.0;
    const subGridSpacing = 10.0;
    const subGridStrokeWidth = 0.5;

    final gridPaint = Paint()
      ..color = Colors.red.withOpacity(0.2)
      ..strokeWidth = gridStrokeWidth;

    final subGridPaint = Paint()
      ..color = Colors.red.withOpacity(0.2)
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
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

BucketStroke _applyBucketFill(
  BucketStroke bucketStroke,
  List<Stroke> allStrokes,
) {
  try {
    final startPoint = Offset(
      bucketStroke.points.first.dx.floorToDouble(),
      bucketStroke.points.first.dy.floorToDouble(),
    );
    const canvasWidth = _canvasSize;
    const canvasHeight = _canvasSize / (16 / 9);

    developer.log('Iniciando bucket fill no ponto: $startPoint');

    // Inicializa o mapa do canvas com áreas vazias
    final canvasMap = <Offset, Color?>{};
    // for (var y = 0; y < canvasHeight; y++) {
    //   for (var x = 0; x < canvasWidth; x++) {
    //     canvasMap[Offset(x.toDouble(), y.toDouble())] = null;
    //   }
    // }

    // Combina todos os strokes no mapa do canvas, exceto o bucketStroke atual
    for (final stroke in allStrokes) {
      if (stroke == bucketStroke) {
        developer.log('Ignorando o bucketStroke na geração do canvasMap');
        continue;
      }
      for (final point in stroke.points) {
        final roundedPoint = Offset(
          point.dx.floorToDouble(),
          point.dy.floorToDouble(),
        );
        canvasMap[roundedPoint] = stroke.color;
      }
    }
    developer.log('Mapa do canvas gerado com ${canvasMap.length} pontos');

    // Função para verificar se um ponto está dentro do canvas
    bool isPointInBounds(Offset point) {
      return point.dx >= 0 &&
          point.dy >= 0 &&
          point.dx < canvasWidth &&
          point.dy < canvasHeight;
    }

    // Função para buscar a cor no ponto
    Color? getColorAtPoint(Offset point) {
      developer.log(
        'Buscando cor no ponto $point: ',
      ); //${color?.toString() ?? 'Nenhuma'}',);
      return canvasMap[
          Offset(point.dx.floorToDouble(), point.dy.floorToDouble())];
    }

    // Cor base no ponto inicial
    final baseColor = getColorAtPoint(startPoint);
    developer
        .log('Cor base detectada no ponto inicial: ${baseColor ?? 'Nenhuma'}');

    // Nova cor de preenchimento
    final fillColor = bucketStroke.color;
    developer.log('Cor de preenchimento: $fillColor');

    // Flood Fill: Estruturas de controle
    final visited = <Offset>{};
    final queue = Queue<Offset>()..add(startPoint);
    final fillPoints = <Offset>[];

    // TODO(Kevin): NOW - esse limite esta muito baixo, preciso diminuir a
    // resolucao dos pixels offset e entao posteriormente ao processamendo
    // voltar a resolucao original
    const maxProcessing =
        500; // Limite de pontos processados para evitar travamentos

    while (queue.isNotEmpty) {
      if (visited.length > maxProcessing) {
        developer.log(
          'Limite de processamento alcançado, interrompendo o preenchimento.',
        );
        break;
      }

      final currentPoint = queue.removeLast();
      developer.log('Processando ponto: $currentPoint');

      // Ignora pontos já visitados
      if (!visited.add(currentPoint)) continue;

      // Verifica se o ponto está dentro do canvas
      if (!isPointInBounds(currentPoint)) continue;

      // Verifica se o ponto tem cor compatível com a base ou está vazio
      final currentColor = getColorAtPoint(currentPoint);
      if (baseColor == null) {
        if (currentColor != null) continue; // Apenas preenche áreas vazias
      } else if (currentColor != baseColor) {
        developer.log(
          'Cor no ponto $currentPoint ($currentColor) não é compatível com a base ($baseColor)',
        );
        continue; // Apenas preenche áreas da mesma cor
      }

      // Adiciona o ponto ao preenchimento
      fillPoints.add(currentPoint);
      developer.log('Ponto $currentPoint adicionado ao preenchimento');

      // Atualiza o mapa com a nova cor
      canvasMap[currentPoint] = fillColor;

      // Adiciona vizinhos à fila
      queue.addAll([
        Offset(currentPoint.dx + 1, currentPoint.dy), // Direita
        Offset(currentPoint.dx - 1, currentPoint.dy), // Esquerda
        Offset(currentPoint.dx, currentPoint.dy + 1), // Abaixo
        Offset(currentPoint.dx, currentPoint.dy - 1), // Acima
      ]);
    }

    developer.log(
      'Preenchimento concluído. ${fillPoints.length} pontos preenchidos.',
    );

    // Retorna o novo stroke com os pontos preenchidos
    return bucketStroke.copyWith(points: fillPoints);
  } catch (e, stackTrace) {
    developer.log(
      'Erro ao aplicar bucket fill: $e',
      name: '_applyBucketFill',
      stackTrace: stackTrace,
    );
  }

  // Em caso de erro, retorna o stroke original
  return bucketStroke;
}
