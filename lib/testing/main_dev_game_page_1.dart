import 'package:drawly/drawly_app.dart';
import 'package:drawly/features/draw_game/draw_game_room_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const DrawlyApp(
      home: DrawGameRoomPage(userId: '1', username: 'Kevin', roomName: '2323'),
    ),
  );
}
