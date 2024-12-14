import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drawing_board/src/src.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

class CanvasSideBar extends StatefulWidget {
  final ValueNotifier<Color> rxSelectedColor;
  final ValueNotifier<double> rxSelectedColorOpacity;
  final ValueNotifier<double> rxCurrentStrokeSize;
  final ValueNotifier<double> rxEraserSize;
  final ValueNotifier<DrawingTool> rxDrawingTool;
  // final CurrentStrokeValueNotifier rxCurrentSketch;
  // final ValueNotifier<List<Stroke>> allSketches;
  final GlobalKey canvasGlobalKey;
  final ValueNotifier<bool> rxIsFilled;
  final ValueNotifier<int> rxPolygonSides;
  // final ValueNotifier<ui.Image?> backgroundImage;
  final UndoRedoStack undoRedoStack;
  final ValueNotifier<bool> rxIsShowGrid;
  final String roomName;
  final bool isCurrentDrawer;

  const CanvasSideBar({
    super.key,
    required this.rxSelectedColor,
    required this.rxSelectedColorOpacity,
    required this.rxCurrentStrokeSize,
    required this.rxEraserSize,
    required this.rxDrawingTool,
    // required this.rxCurrentSketch,
    // required this.allSketches,
    required this.canvasGlobalKey,
    required this.rxIsFilled,
    required this.rxPolygonSides,
    // required this.backgroundImage,
    required this.undoRedoStack,
    required this.rxIsShowGrid,
    required this.roomName,
    required this.isCurrentDrawer,
  }) : assert(roomName.length >= 3, 'The roomName must be at least 3 characters long');

  @override
  State<CanvasSideBar> createState() => _CanvasSideBarState();
}

abstract class CanvasSideBarViewModel extends State<CanvasSideBar> {
  final scrollController = ScrollController();

  void _initializeClearDrawSocket() {
    SocketManager.instance.on('drawing:clear', (_) {
      widget.undoRedoStack.clear();
    });
  }

  void _initializeUndoDrawSocket() {
    SocketManager.instance.on('drawing:undo', (_) {
      widget.undoRedoStack.undo();
    });
  }

  void _initializeRedoDrawSocket() {
    SocketManager.instance.on('drawing:redo', (_) {
      widget.undoRedoStack.redo();
    });
  }

  void _sendClearStrokes() {
    SocketManager.instance.emit('drawing:clear', {
      'roomName': widget.roomName,
    });
  }

  void _sendUndoStroke() {
    SocketManager.instance.emit('drawing:undo', {
      'roomName': widget.roomName,
    });
  }

  void _sendRedoStroke() {
    SocketManager.instance.emit('drawing:redo', {
      'roomName': widget.roomName,
    });
  }
}

class _CanvasSideBarState extends CanvasSideBarViewModel {
  @override
  void initState() {
    super.initState();
    _initializeClearDrawSocket();
    _initializeUndoDrawSocket();
    _initializeRedoDrawSocket();
  }

  @override
  void dispose() {
    SocketManager.instance.off('drawing:clear');
    SocketManager.instance.off('drawing:undo');
    SocketManager.instance.off('drawing:redo');

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return !widget.isCurrentDrawer
        ? const SizedBox.shrink()
        : DrawlyContainer(
            width: 100,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                widget.rxSelectedColor,
                widget.rxSelectedColorOpacity,
                widget.rxCurrentStrokeSize,
                widget.rxEraserSize,
                widget.rxDrawingTool,
                widget.rxIsFilled,
                widget.rxPolygonSides,
                // widget.backgroundImage,
                widget.rxIsShowGrid,
              ]),
              builder: (context, _) {
                return Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true,
                  trackVisibility: false,
                  child: ListView(
                    padding: const EdgeInsets.all(10.0),
                    controller: scrollController,
                    children: [
                      DrawlyBarGrid(
                        children: [
                          _IconBox(
                            iconData: FontAwesomeIcons.pencil,
                            selected: widget.rxDrawingTool.value == DrawingTool.pencil,
                            onTap: () => widget.rxDrawingTool.value = DrawingTool.pencil,
                            tooltip: 'Pencil',
                          ),
                          _IconBox(
                            selected: widget.rxDrawingTool.value == DrawingTool.line,
                            onTap: () => widget.rxDrawingTool.value = DrawingTool.line,
                            tooltip: 'Line',
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 22,
                                  height: 2,
                                  color:
                                      widget.rxDrawingTool.value == DrawingTool.line ? Colors.grey[900] : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          _IconBox(
                            iconData: FontAwesomeIcons.square,
                            selected: widget.rxDrawingTool.value == DrawingTool.square,
                            onTap: () => widget.rxDrawingTool.value = DrawingTool.square,
                            tooltip: 'Square',
                          ),
                          _IconBox(
                            iconData: FontAwesomeIcons.circle,
                            selected: widget.rxDrawingTool.value == DrawingTool.circle,
                            onTap: () => widget.rxDrawingTool.value = DrawingTool.circle,
                            tooltip: 'Circle',
                          ),
                          _IconBox(
                            iconData: Icons.hexagon_outlined,
                            selected: widget.rxDrawingTool.value == DrawingTool.polygon,
                            onTap: () => widget.rxDrawingTool.value = DrawingTool.polygon,
                            tooltip: 'Polygon',
                          ),
                          _IconBox(
                            iconData: FontAwesomeIcons.eraser,
                            selected: widget.rxDrawingTool.value == DrawingTool.eraser,
                            onTap: () => widget.rxDrawingTool.value = DrawingTool.eraser,
                            tooltip: 'Eraser',
                          ),
                        ],
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: widget.rxDrawingTool.value == DrawingTool.polygon
                            ? Column(
                                children: [
                                  const SizedBox(height: 5),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2, // Trilho fino
                                      thumbShape:
                                          const RoundSliderThumbShape(enabledThumbRadius: 8), // Tamanho do thumb
                                      overlayShape:
                                          const RoundSliderOverlayShape(overlayRadius: 16), // Efeito de arrastar
                                      trackShape:
                                          const RectangularSliderTrackShape(), // Remove o padding ao usar um trilho retangular
                                    ),
                                    child: Slider(
                                      value: widget.rxPolygonSides.value.toDouble(),
                                      min: 3,
                                      max: 8,
                                      divisions: 5,
                                      label: '${widget.rxPolygonSides.value}',
                                      onChanged: (val) {
                                        widget.rxPolygonSides.value = val.toInt();
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: widget.rxDrawingTool.value == DrawingTool.polygon ||
                                widget.rxDrawingTool.value == DrawingTool.square ||
                                widget.rxDrawingTool.value == DrawingTool.circle
                            ? Column(
                                children: [
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: widget.rxIsFilled.value,
                                        onChanged: (val) {
                                          widget.rxIsFilled.value = val ?? false;
                                        },
                                      ),
                                      const Text(
                                        'Fill',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 5),
                      DrawlyBarGrid(
                        children: [
                          ValueListenableBuilder<List<Stroke>>(
                            valueListenable: widget.undoRedoStack.rxAllStrokes,
                            builder: (_, strokesNotifier, __) {
                              return _IconBox(
                                iconData: Icons.undo,
                                selected: false,
                                onTap: strokesNotifier.isNotEmpty ? () => _sendUndoStroke() : null,
                                tooltip: 'Undo',
                              );
                            },
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: widget.undoRedoStack.rxCanRedo,
                            builder: (_, canRedo, __) {
                              return _IconBox(
                                iconData: Icons.redo,
                                selected: false,
                                onTap: canRedo ? () => _sendRedoStroke() : null,
                                tooltip: 'Redo',
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const DrawlyBarGrid(
                        children: [
                          // TextButton(
                          //   onPressed: () async {
                          //     if (widget.backgroundImage.value != null) {
                          //       widget.backgroundImage.value = null;
                          //     } else {
                          //       widget.backgroundImage.value = await _getImage;
                          //     }
                          //   },
                          //   child: Text(
                          //     widget.backgroundImage.value == null ? 'Add Background' : 'Remove Background',
                          //   ),
                          // ),
                        ],
                      ),
                      ColorPalette(
                        rxSelectedColor: widget.rxSelectedColor,
                        // selectedColorOpacityListenable: widget.selectedColorOpacity,
                      ),
                      SizedBox(
                        height: 120,
                        child: Row(
                          children: [
                            Expanded(
                              child: RotatedBox(
                                quarterTurns: -1,
                                child: DrawlySliderFb3(
                                  // value: widget.strokeSize.value,
                                  min: 2,
                                  max: 20,
                                  divisions: 10,
                                  onChanged: (value) {
                                    widget.rxCurrentStrokeSize.value = value;
                                  },
                                  initialValue: widget.rxCurrentStrokeSize.value,
                                  // accentColor:,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.blue,
                                      Colors.blue,
                                    ],
                                  ),
                                  showMinMaxText: false,
                                  minMaxTextStyle: const TextStyle(fontSize: 14),
                                  accentColor: Colors.blue,
                                ),
                              ),
                            ),
                            // Expanded(
                            //   child: RotatedBox(
                            //     quarterTurns: -1,
                            //     child: Tooltip(
                            //       message: 'Eraser Size',
                            //       child: Slider(
                            //         value: widget.eraserSize.value,
                            //         min: 0,
                            //         max: 80,
                            //         onChanged: (val) {
                            //           widget.eraserSize.value = val;
                            //         },
                            //       ),
                            //     ),
                            //   ),
                            // ),
                            Expanded(
                              child: RotatedBox(
                                quarterTurns: -1,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2, // Trilho fino
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8), // Tamanho do thumb
                                    overlayShape:
                                        const RoundSliderOverlayShape(overlayRadius: 16), // Efeito de arrastar
                                    trackShape:
                                        const RectangularSliderTrackShape(), // Remove o padding ao usar um trilho retangular
                                  ),
                                  child: DrawlySliderFb3(
                                    min: 10,
                                    max: 100,
                                    divisions: 9,
                                    onChanged: (value) {
                                      widget.rxSelectedColorOpacity.value = value / 100;
                                    },
                                    initialValue: widget.rxSelectedColorOpacity.value * 100,
                                    // accentColor:,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.blue,
                                        Colors.blue,
                                      ],
                                    ),
                                    showMinMaxText: false,
                                    minMaxTextStyle: const TextStyle(fontSize: 14),
                                    accentColor: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // DrawlyBarGrid(
                      //   children: [
                      //     SizedBox(
                      //       width: 140,
                      //       child: TextButton(
                      //         child: const Text('Export PNG'),
                      //         onPressed: () async {
                      //           Uint8List? pngBytes = await getBytes();
                      //           if (pngBytes != null) saveFile(pngBytes, 'png');
                      //         },
                      //       ),
                      //     ),
                      //     SizedBox(
                      //       width: 140,
                      //       child: TextButton(
                      //         child: const Text('Export JPEG'),
                      //         onPressed: () async {
                      //           Uint8List? pngBytes = await getBytes();
                      //           if (pngBytes != null) saveFile(pngBytes, 'jpeg');
                      //         },
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      // add about me button or follow buttons
                      // Center(
                      //   child: GestureDetector(
                      //     onTap: () => _launchUrl('https://github.com/KevinKobori'),
                      //     child: const Text(
                      //       'Made with 💙 by Kevin Kobori',
                      //       style: TextStyle(fontSize: 12),
                      //     ),
                      //   ),
                      // ),
                      DrawlyBarGrid(
                        children: [
                          _IconBox(
                            iconData: FontAwesomeIcons.ruler,
                            selected: widget.rxIsShowGrid.value,
                            onTap: () => widget.rxIsShowGrid.value = !widget.rxIsShowGrid.value,
                            tooltip: 'Guide Lines',
                          ),
                          _IconBox(
                            iconData: Icons.delete_forever,
                            selected: false,
                            onTap: _sendClearStrokes,
                            tooltip: 'Clear Strokes',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
  }

  void saveFile(Uint8List bytes, String extension) async {
    if (kIsWeb) {
      html.AnchorElement()
        ..href = '${Uri.dataFromBytes(bytes, mimeType: 'image/$extension')}'
        ..download = 'FlutterLetsDraw-${DateTime.now().toIso8601String()}.$extension'
        ..style.display = 'none'
        ..click();
    } else {
      await FileSaver.instance.saveFile(
        name: 'FlutterLetsDraw-${DateTime.now().toIso8601String()}.$extension',
        bytes: bytes,
        ext: extension,
        mimeType: extension == 'png' ? MimeType.png : MimeType.jpeg,
      );
    }
  }

  Future<ui.Image> get _getImage async {
    final completer = Completer<ui.Image>();
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      final file = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (file != null) {
        final filePath = file.files.single.path;
        final bytes = filePath == null ? file.files.first.bytes : File(filePath).readAsBytesSync();
        if (bytes != null) {
          completer.complete(decodeImageFromList(bytes));
        } else {
          completer.completeError('No image selected');
        }
      }
    } else {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        completer.complete(
          decodeImageFromList(bytes),
        );
      } else {
        completer.completeError('No image selected');
      }
    }

    return completer.future;
  }

  Future<void> _launchUrl(String url) async {
    if (kIsWeb) {
      html.window.open(
        url,
        url,
      );
    } else {
      if (!await launchUrl(Uri.parse(url))) {
        throw 'Could not launch $url';
      }
    }
  }

  Future<Uint8List?> getBytes() async {
    RenderRepaintBoundary boundary = widget.canvasGlobalKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List? pngBytes = byteData?.buffer.asUint8List();
    return pngBytes;
  }
}

class _IconBox extends StatelessWidget {
  final IconData? iconData;
  final Widget? child;
  final bool selected;
  final VoidCallback? onTap;
  final String? tooltip;

  const _IconBox({
    this.iconData,
    this.child,
    this.tooltip,
    required this.selected,
    required this.onTap,
  }) : assert(child != null || iconData != null);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.grey[900]! : Colors.grey,
              width: 1.5,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: Tooltip(
            message: tooltip,
            preferBelow: false,
            child: child ??
                Icon(
                  iconData,
                  color: selected ? Colors.grey[900] : Colors.grey,
                  size: 20,
                ),
          ),
        ),
      ),
    );
  }
}
