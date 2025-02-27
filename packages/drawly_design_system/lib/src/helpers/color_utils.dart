import 'dart:ui';

import 'package:flutter/material.dart';

extension ColorUtils on Color {
  /// Aplica a opacidade especificada à cor informada.
  /// [opacity] deve estar entre 0.0 e 1.0.
  Color applyOpacity(double opacity) {
    // Converte o valor de opacidade (0.0 - 1.0) para um valor alpha (0 - 255)
    final alpha = (opacity * 255).round();
    return withAlpha(alpha);
  }

  /// Converte a cor para um Map, usando os componentes normalizados.
  Map<String, dynamic> toJson() => {
        'a': a,
        'r': r,
        'g': g,
        'b': b,
        'colorSpace': colorSpace.toString(), // opcional
      };

  /// Reconstrói a cor a partir de um Map.
  static Color fromJson(Map<String, dynamic> json) {
    // Se precisar tratar o ColorSpace, pode implementar uma lógica de parsing.
    // Aqui usamos sRGB por padrão.
    return Color.from(
      alpha: (json['a'] as num).toDouble(),
      red: (json['r'] as num).toDouble(),
      green: (json['g'] as num).toDouble(),
      blue: (json['b'] as num).toDouble(),
    );
  }
}
