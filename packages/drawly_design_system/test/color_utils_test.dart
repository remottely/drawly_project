import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applyOpacity calculates alpha correctly', () {
    final color = Colors.blue;
    final result = color.applyOpacity(0.5);
    expect(result.alpha, 128);
  });

  test('toJson and fromJson are symmetrical', () {
    final color = Colors.green;
    final json = color.toJson();
    final restored = ColorUtils.fromJson(json);
    expect(restored.alpha, color.alpha);
    expect(restored.red, color.red);
    expect(restored.green, color.green);
    expect(restored.blue, color.blue);
  });
}
