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
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer token'})
          .build(),
    );

    _socket.io.options?['reconnectionAttempts'] = 5;
    _socket.io.options?['reconnectionDelay'] = 2000;
    _socket.io.options?['reconnectionDelayMax'] = 5000;

    _socket.on('connect', (_) {
      developer.log('Conectado ao servidor');
      for (var listener in _connectListeners) {
        listener(null);
      }
    });

    _socket.on('disconnect', (_) {
      developer.log('Desconectado do servidor');
      for (var listener in _disconnectListeners) {
        listener(null);
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

  void connect() {
    if (!_socket.connected) {
      _socket.connect();
    }
  }

  void disconnect() {
    if (_socket.connected) {
      _socket.disconnect();
    }
  }

  void onConnect(Function(dynamic) callback) {
    _connectListeners.add(callback);
  }

  void onDisconnect(Function(dynamic) callback) {
    _disconnectListeners.add(callback);
  }

  void emit(String event, dynamic data) {
    _socket.emit(event, data);
  }

  void on(String event, Function(dynamic) callback) {
    _socket.on(event, callback);
  }

  void off(String event) {
    _socket.off(event);
  }

  void clearListeners() {
    _socket.clearListeners();
    _connectListeners.clear();
    _disconnectListeners.clear();
  }
}
