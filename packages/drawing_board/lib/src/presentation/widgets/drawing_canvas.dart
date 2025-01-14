import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

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

  final double _canvasSize = 500;
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
    final canvasWidth = _canvasSize;
    final canvasHeight = _canvasSize / (16 / 9);

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
                      if (currentTool.isBucket) {
                        // chatgpt: quero mudar a logica, preciso q vc crie um objeto q contorne tudo q estiver no canvas, for da mesma cor e nao tiver limites entre outras cores, assim comoo é feito com o bucket de qualquer sistema
                        _applyBucketFill(localPosition, scale);
                      } else {
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
                      }
                    }
                  },
                  onPointerMove: (details) {
                    final localPosition = details.localPosition;
                    if (_isPointInsideCanvas(localPosition)) {
                      rxCurrentStroke.addPoint(localPosition);
                      // widget.onDrawingStrokeChanged?
                      // .call(rxCurrentStroke.value);
                    }
                  },
                  onPointerUp: (_) {
                    if (currentTool.isBucket) {
                      return;
                    } else {
                      _sendDrawingPointsEnd();
                    }
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

  void _applyBucketFill(Offset startPoint, double scale) {
    try {
      // Lista de traços atuais no canvas
      final allStrokes = List<Stroke>.from(rxAllStrokes.value);

      // Dimensões do canvas
      final canvasWidth = _canvasSize;
      final canvasHeight = _canvasSize / (16 / 9);

      // Criação do mapa unificado de cores
      final canvasMap = <Offset, Color?>{};

      // Combina os strokes, priorizando os de índice maior
      for (final stroke in allStrokes) {
        for (final point in stroke.points) {
          canvasMap[point] = stroke.color;
        }
      }

      // Função auxiliar para verificar se um ponto está dentro do canvas
      bool isPointInBounds(Offset point) {
        return point.dx >= 0 &&
            point.dy >= 0 &&
            point.dx <= canvasWidth &&
            point.dy <= canvasHeight;
      }

      // Detectar a cor inicial no ponto de partida
      final baseColor = canvasMap[startPoint];

      // Caso o ponto inicial esteja vazio ou fora do canvas
      if (baseColor == null) {
        developer.log('Bucket iniciado em uma área vazia ou fora do canvas.');
        return;
      }

      // Estruturas para o algoritmo de Flood Fill
      final visited = <Offset>{};
      final queue = <Offset>[startPoint];
      final boundaryPoints = <Offset>[];

      // Flood Fill: Percorre os pontos conectados
      while (queue.isNotEmpty) {
        final currentPoint = queue.removeLast();

        // Ignora pontos já visitados
        if (visited.contains(currentPoint)) continue;

        // Marca o ponto como visitado
        visited.add(currentPoint);

        // Verifica se o ponto está dentro dos limites do canvas
        if (!isPointInBounds(currentPoint)) continue;

        // Verifica se a cor é diferente da base (limite encontrado)
        if (canvasMap[currentPoint] != baseColor) continue;

        // Adiciona o ponto ao conjunto de preenchimento
        boundaryPoints.add(currentPoint);

        // Adiciona os vizinhos à fila
        queue.addAll([
          Offset(currentPoint.dx + 1, currentPoint.dy), // Direita
          Offset(currentPoint.dx - 1, currentPoint.dy), // Esquerda
          Offset(currentPoint.dx, currentPoint.dy + 1), // Abaixo
          Offset(currentPoint.dx, currentPoint.dy - 1), // Acima
        ]);
      }

      // Criação do novo traço de preenchimento
      final bucketStroke = BucketStroke(
        points: boundaryPoints,
        color: strokeColor, // Cor do bucket
        size: size / scale, // Tamanho do traço ajustado
        opacity: opacity, // Opacidade do bucket
      );

      rxAllStrokes.value = List<Stroke>.from(rxAllStrokes.value)
        ..add(bucketStroke);

      // Adiciona os pontos preenchidos ao traço atual
      rxCurrentStroke.addPoints(bucketStroke.points);

      // Envia os pontos preenchidos para o servidor
      _sendBufferedDrawingPoints();

      // Finaliza o traço atual
      _sendDrawingPointsEnd();
    } catch (e, stackTrace) {
      // Registra erros durante o processo de bucket fill
      developer.log(
        'Erro ao aplicar bucket fill: $e',
        name: '_applyBucketFill',
        stackTrace: stackTrace,
      );
    }
  }

  Path _getFillBoundary({
    required Offset startPoint, // Ponto inicial do preenchimento
    required Path combinedPath, // Conjunto de contornos existentes no canvas
    required double canvasWidth, // Largura do canvas
    required double canvasHeight, // Altura do canvas
  }) {
    // Cria um objeto Path para armazenar os limites da área de preenchimento
    final boundaryPath = Path();

    // Verifica se o ponto inicial está dentro de algum contorno existente
    if (!combinedPath.contains(startPoint)) {
      // Caso o ponto inicial esteja fora de qualquer contorno:
      // Adiciona um retângulo que cobre toda a área do canvas como contorno
      // TODO: KEVIN NOW
      boundaryPath.addRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight));
      return boundaryPath;
    } else {
      // Caso o ponto inicial esteja dentro de um contorno existente:
      // Utiliza uma abordagem de busca (similar a BFS) para determinar a área conectada
      final visited = <Offset>{}; // Conjunto para rastrear pontos já visitados
      final queue = <Offset>[startPoint]; // Fila de pontos a serem processados

      while (queue.isNotEmpty) {
        // Remove o último ponto da fila (LIFO para simular BFS)
        final point = queue.removeLast();

        // Ignora pontos que já foram visitados
        if (visited.contains(point)) continue;

        // Adiciona o ponto ao conjunto de visitados
        visited.add(point);

        // Verifica se o ponto está fora dos limites do canvas
        if (point.dx < 0 ||
            point.dy < 0 ||
            point.dx > canvasWidth ||
            point.dy > canvasHeight) {
          continue;
        }

        // Verifica se o ponto está fora do contorno combinado
        if (!combinedPath.contains(point)) {
          // Adiciona um pequeno círculo ao boundaryPath para representar o ponto
          boundaryPath.addOval(
            Rect.fromCircle(center: point, radius: 1),
          );
          continue;
        }

        // Adiciona os vizinhos (acima, abaixo, esquerda, direita) à fila para processamento
        queue.addAll([
          Offset(point.dx + 1, point.dy), // Vizinho à direita
          Offset(point.dx - 1, point.dy), // Vizinho à esquerda
          Offset(point.dx, point.dy + 1), // Vizinho abaixo
          Offset(point.dx, point.dy - 1), // Vizinho acima
        ]);
      }
    }

    // Fecha o path para garantir que ele esteja completo
    boundaryPath.close();
    return boundaryPath;
  }

  /// Converte um objeto `Path` em uma lista de pontos (`List<Offset>`).
  ///
  /// Essa função percorre o comprimento total do `Path`, segmentando-o
  /// em intervalos regulares, e extrai os pontos que compõem o caminho.
  ///
  /// ### Parâmetros
  /// - `path`: Um objeto `Path` que representa o contorno ou desenho a ser convertido.
  ///
  /// ### Retorno
  /// - Uma lista de pontos (`List<Offset>`) que representa o contorno do `Path`.
  ///
  /// ### Notas
  /// - O espaçamento entre os pontos é controlado pela constante `step`.
  /// - Essa função é útil para simplificar um `Path` complexo em um conjunto
  ///   discreto de pontos para processamento adicional ou renderização.
  ///
  /// ### Exemplo de Uso
  /// ```dart
  /// final path = Path()..addRect(Rect.fromLTWH(0, 0, 100, 100));
  /// final points = _convertPathToPoints(path);
  /// print(points); // Lista de pontos no contorno do retângulo.
  /// ```
  List<Offset> _convertPathToPoints(Path path) {
    // Inicializa uma lista para armazenar os pontos do contorno.
    final boundaryPoints = <Offset>[];

    // Itera sobre as métricas de cada segmento do Path.
    for (final metric in path.computeMetrics()) {
      // Obtém o comprimento total do segmento atual.
      final length = metric.length;

      // Define o intervalo entre os pontos extraídos.
      const step = 5.0; // Distância em pixels entre os pontos.

      // Percorre o comprimento do segmento em intervalos definidos por `step`.
      for (var distance = 0.0; distance < length; distance += step) {
        // Obtém a tangente para a posição atual no segmento.
        final tangent = metric.getTangentForOffset(distance);

        // Se a tangente não for nula, adiciona sua posição à lista de pontos.
        if (tangent != null) {
          boundaryPoints.add(tangent.position);
        }
      }
    }

    // Retorna a lista de pontos que representam o contorno do Path.
    return boundaryPoints;
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
          // path.close();
          // paint.style = PaintingStyle.fill;
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
        final path = Path()
          ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (var i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        path.close();
        // paint.style = PaintingStyle.fill;
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
