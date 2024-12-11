import 'dart:developer' as developer;

import 'package:socket_io_client/socket_io_client.dart' as socket_io_client;

class SocketManager {
  static final SocketManager _instance = SocketManager._internal();

  late final socket_io_client.Socket _socket;

  final List<Function(dynamic)> _connectListeners = [];
  final List<Function(dynamic)> _disconnectListeners = [];

  SocketManager._internal() {
    _initializeSocket();
  }

  static SocketManager get instance => _instance;

  void _initializeSocket() {
    _socket = socket_io_client.io(
      'http://localhost:5555',
      socket_io_client.OptionBuilder()
          .setTransports(['websocket']) // Define os transportes como websocket
          .disableAutoConnect() // Impede a conexão automática ao instanciar
          .setExtraHeaders({'Authorization': 'Bearer token'}) // (Opcional) Exemplos de headers adicionais
          .build(),
    );

    _socket.io.options?['reconnectionAttempts'] = 5; // Tentativas de reconexão
    _socket.io.options?['reconnectionDelay'] = 2000; // Delay inicial entre tentativas (ms)
    _socket.io.options?['reconnectionDelayMax'] = 5000; // Delay máximo entre tentativas (ms)

    _socket.on('connect', (_) {
      developer.log('Conectado ao servidor');
      for (var listener in _connectListeners) {
        listener(null); // Passa null como argumento ou dados relevantes, se necessário
      }
    });

    _socket.on('disconnect', (_) {
      developer.log('Desconectado do servidor');
      for (var listener in _disconnectListeners) {
        listener(null); // Passa null como argumento ou dados relevantes, se necessário
      }
    });

    _socket.on('reconnect_attempt', (_) {
      developer.log('Tentando reconectar...');
    });

    _socket.on('reconnect', (_) {
      developer.log('Reconectado com sucesso');
    });

    _socket.on('reconnect_failed', (_) {
      developer.log('Falha na reconexão');
    });

    _socket.connect();
  }

  /// Connects to the socket server
  void connect() {
    if (!_socket.connected) {
      _socket.connect();
    }
  }

  /// Disconnects from the socket server
  void disconnect() {
    if (_socket.connected) {
      _socket.disconnect();
    }
  }

  // chatgpt: nao entendi o que issa funcao faz, como q ele chama os listeners de connect?
  /// Adds a listener for the 'connect' event
  void onConnect(Function(dynamic) callback) {
    _connectListeners.add(callback);
  }

  /// Adds a listener for the 'disconnect' event
  void onDisconnect(Function(dynamic) callback) {
    _disconnectListeners.add(callback);
  }

  /// Emits an event to the server
  void emit(String event, dynamic data) {
    _socket.emit(event, data);
  }

  /// Listens for a specific event from the server
  void on(String event, Function(dynamic) callback) {
    _socket.on(event, callback);
  }

  /// Removes a specific listener
  void off(String event) {
    _socket.off(event);
  }

  /// Clears all listeners to avoid memory leaks
  void clearListeners() {
    _socket.clearListeners();
    _connectListeners.clear();
    _disconnectListeners.clear();
  }
}
