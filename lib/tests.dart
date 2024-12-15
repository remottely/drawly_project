import 'package:drawly_core/drawly_core.dart';

class Tests {
  static void testReconnection() {
    print("Simulando desconexão...");
    SocketManager.instance.disconnect();

    Future.delayed(Duration(seconds: 2), () {
      print("Reconectando...");
      SocketManager.instance.connect();
    });
  }

  static void createRoom(String roomName) {
    SocketManager.instance.emit('room:create', {
      'roomName': roomName,
    });
  }
}
