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
  socket_io_client.Socket get socket => _socket;

  void _initializeSocket() {
    _socket = socket_io_client.io(
      'http://localhost:5555',
      socket_io_client.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    // Listen for connection events
    _socket.on('connect', (_) {
      for (var listener in _connectListeners) {
        listener(_);
      }
    });

    // Listen for disconnection events
    _socket.on('disconnect', (_) {
      for (var listener in _disconnectListeners) {
        listener(_);
      }
    });
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
