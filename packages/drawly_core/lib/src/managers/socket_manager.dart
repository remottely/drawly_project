import 'dart:async';
import 'dart:developer' as developer;

import 'package:socket_io_client/socket_io_client.dart' as socket_io_client;

class SocketManager {
  SocketManager._internal() {
    _initializeSocket();
  }
  static final SocketManager _instance = SocketManager._internal();
  static SocketManager get instance => _instance;

  late final socket_io_client.Socket _socket;
  final Map<String, List<void Function(dynamic)>> _eventListeners = {};

  void _onConnect() {
    developer.log('Connected to server');
  }

  void _onDisconnect() {
    developer.log('Disconnected from server');
  }

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

    onEvent('connect', (_) => _onConnect());
    onEvent('disconnect', (_) => _onDisconnect());

    connect();
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

  /// Register a callback for a specific event
  void onEvent(String event, void Function(dynamic) callback) {
    _eventListeners.putIfAbsent(event, () => []);

    // Add the callback to the list
    _eventListeners[event]!.add(callback);

    // Register the event with the socket only once
    if (_eventListeners[event]!.length == 1) {
      _socket.on(event, (data) {
        for (final listener in _eventListeners[event]!) {
          listener(data);
        }
      });
    }
  }

  /// Remove a specific callback from an event
  void offEvent(String event, void Function(dynamic) callback) {
    if (_eventListeners[event] != null) {
      _eventListeners[event]!.remove(callback);

      // If no callbacks are left, remove the event listener from the socket
      if (_eventListeners[event]!.isEmpty) {
        _eventListeners.remove(event);
        _socket.off(event);
      }
    }
  }

  /// Emit an event to the server
  void emit(String event, dynamic data) {
    _socket.emit(event, data);
  }

  Future<Map<String, dynamic>> emitWithAck(
    String event,
    dynamic data, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    final completer = Completer<Map<String, dynamic>>();

    _socket.emitWithAck(
      event,
      data,
      ack: (Map<String, dynamic> response) {
        if (!completer.isCompleted) {
          completer.complete(response);
        }
      },
    );

    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        completer
            .completeError('Timeout: No response received for event $event');
      }
    });

    return completer.future;
  }

  /// Clear all listeners (use with caution)
  void clearListeners() {
    _eventListeners
      ..forEach((event, _) {
        _socket.off(event);
      })
      ..clear();
  }
}
