import 'package:draw_board/draw_board.dart';
import 'package:flutter/material.dart';

class GamePage extends StatefulWidget {
  final String username;
  final String room;

  const GamePage({
    super.key,
    required this.username,
    required this.room,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  @override
  Widget build(BuildContext context) {
    return DrawBoard(
      username: widget.username,
      room: widget.room,
    );
  }
}
