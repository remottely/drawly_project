import 'package:drawly/pages/game_page.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DrawlyApp());
}

class DrawlyApp extends StatelessWidget {
  const DrawlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Drawly",
      theme: lightTheme,
      home: GamePage(
        username: 'test1',
        room: '2323',
      ),
    );
  }
}
