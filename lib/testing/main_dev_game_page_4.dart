import 'package:drawly/features/draw_game/draw_game_room_page.dart';
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
      debugShowCheckedModeBanner: false,
      title: 'Drawly',
      theme: lightTheme,
      home: const DrawGameRoomPage(
        username: 'Michelle',
        roomName: '2323',
      ),
    );
  }
}
