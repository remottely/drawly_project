import 'package:drawing_board/src/src.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_platform/universal_platform.dart';

void main() {
  testWidgets('HotkeyListener triggers onUndo on Ctrl + Z',
      (WidgetTester tester) async {
    var undoCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: HotkeyListener(
          onUndo: () => undoCalled = true,
          child: Container(),
        ),
      ),
    );

    // Ensure the HotkeyListener gets focus
    final focusFinder = find.byType(HotkeyListener);
    await tester.tap(focusFinder);
    await tester.pump();

    if (UniversalPlatform.isMacOS) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    } else {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }

    await tester.pump(); // Ensure all events are processed

    expect(undoCalled, true);
  });

  testWidgets('HotkeyListener triggers onRedo on Ctrl + Y',
      (WidgetTester tester) async {
    var redoCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: HotkeyListener(
          onRedo: () => redoCalled = true,
          child: Container(),
        ),
      ),
    );

    if (UniversalPlatform.isMacOS) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    } else {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }

    expect(redoCalled, true);
  });

  testWidgets('HotkeyListener triggers onShiftPressed correctly',
      (WidgetTester tester) async {
    var shiftPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: HotkeyListener(
          onShiftPressed: ({bool value = false}) => shiftPressed = value,
          child: Container(),
        ),
      ),
    );

    // Simulate pressing Shift
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    expect(shiftPressed, true);

    // Simulate releasing Shift
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(shiftPressed, false);
  });
}
