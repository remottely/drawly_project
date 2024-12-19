import 'dart:developer' as developer;

import 'package:drawly_core/drawly_core.dart';

class Tests {
  static const isTesting = true;
  static void testReconnection() {
    developer.log('Simulando desconexão...');
    SocketManager.instance.disconnect();

    Future.delayed(const Duration(seconds: 2), () {
      developer.log('Reconectando...');
      SocketManager.instance.connect();
    });
  }

  static void createRoom(String roomName) {
    final payload = RoomDTO(
      roomName: roomName,
    ).toJson();

    SocketManager.instance.emit('room:create', payload);
  }
}
