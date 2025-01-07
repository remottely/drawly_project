import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late IO.Socket socket;
  String receivedMessage = 'Nenhuma mensagem';

  @override
  void initState() {
    super.initState();
    // Configurar o cliente Socket.IO
    socket = IO.io(
      'http://localhost:3000', // Endereço do servidor
      IO.OptionBuilder()
          .setTransports(['websocket']) // Usar apenas WebSocket
          .disableAutoConnect() // Conexão manual
          .build(),
    );

    // Configurar eventos do socket
    socket.onConnect((_) {
      print('Conectado ao servidor!');
    });

    socket.on('event', (data) {
      setState(() {
        receivedMessage = data as String;
      });
    });

    socket.onDisconnect((_) {
      print('Desconectado do servidor.');
    });

    socket.connect();
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  void sendMessage() {
    socket.emit('event', 'Hello, World!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Socket.IO Flutter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Mensagem recebida: $receivedMessage'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendMessage,
              child: const Text('Enviar Hello, World!'),
            ),
          ],
        ),
      ),
    );
  }
}
