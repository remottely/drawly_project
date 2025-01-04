import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

extension GlobalKeyExtension on GlobalKey {
  Future<String?> toBase64() async {
    final boundary =
        currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();
    if (pngBytes == null) {
      return null;
    }
    return base64Encode(pngBytes);
  }
}
