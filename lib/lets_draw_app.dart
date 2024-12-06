import 'package:draw_board/draw_board.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class DrawlyApp extends StatelessWidget {
  const DrawlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Drawly",
      theme: lightTheme,
      home: const DrawBoard(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
