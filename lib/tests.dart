import 'package:drawly_core/drawly_core.dart';

class Tests {
  static void testReconnection() {
    // Simula um cliente desconectando
    print("Simulando desconexão...");
    SocketManager.instance.disconnect();

    // Aguarde 2 segundos e reconecte
    Future.delayed(Duration(seconds: 2), () {
      print("Reconectando...");
      SocketManager.instance.connect();
    });
  }
}
