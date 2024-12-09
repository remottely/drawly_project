import 'dart:developer' as developer;

import 'package:draw_board/draw_board.dart';
import 'package:drawly/features/answers_chat/answers_chat.dart';
import 'package:drawly/features/message_chat/message_chat.dart';
import 'package:drawly/features/participants/participants.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:flutter/material.dart';

class GamePage extends StatefulWidget {
  final String username;
  final String room;

  const GamePage({
    super.key,
    required this.username,
    required this.room,
  })  : assert(username.length >= 3, 'The username must be at least 3 characters long'),
        assert(room.length >= 3, 'The room must be at least 3 characters long');

  @override
  State<GamePage> createState() => _GamePageState();
}

abstract class GamePageViewModel extends State<GamePage> {
  _initialize() {
    _initializeSocket();
    _createRoom();
    _joinGameRoom();
  }

  /// Initializes the socket connection and defines event handlers
  void _initializeSocket() {
    SocketManager.instance.connect();

    SocketManager.instance.onConnect((_) {
      developer.log('Connected to the Socket.IO server');
    });

    SocketManager.instance.onDisconnect((_) {
      developer.log('Disconnected from the server');
    });
  }

  /// Sends a request to create a new room
  void _createRoom() {
    SocketManager.instance.emit('createRoom', widget.room);
  }

  /// Joins the room specified in the widget
  void _joinGameRoom() {
    SocketManager.instance.emit('joinRoom', {
      'username': widget.username,
      'room': widget.room,
    });
    // // Handle draw event from the server
    // SocketManager.instance.socket.on('draw', (data) {
    //   developer.log('Draw event received: $data');
    //   // List<Stroke?> receivedStroke =
    //   //     (data['strokes'] as List).map((point) => point != null ? Stroke.fromJson(point) : null).toList();
    //   // error: The argument type 'Iterable<Stroke?>' can't be assigned to the parameter type 'Iterable<Stroke>'.
    //   // Add received strokes to the list if not already present
    //   // _strokes.value = List.from(_strokes.value)
    //   //   ..addAll(receivedStroke.where((p) => p == null || !_strokes.value.contains(p)));
    //   // Add received strokes to the list if not already present
    //   // _strokes.value = List.from(_strokes.value)
    //   //   ..addAll(receivedStroke.where((p) => p != null && !_strokes.value.contains(p)).cast<Stroke>());
    //   // _strokes.value = List<Stroke>.from(_strokes.value)..add(_currentStroke.value!);
    //   Stroke? receivedStroke = Stroke.fromJson(data['strokes']);
    //   _strokes.value = List<Stroke>.from(_strokes.value)..add(receivedStroke);
    // });
  }

  // Notify the server that the user is leaving the room
  void _leaveRoom() {
    SocketManager.instance.emit('leaveRoom', {
      'username': widget.username,
      'room': widget.room,
    });
  }
}

class _GamePageState extends GamePageViewModel {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _leaveRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drawly - ${widget.room}'),
        actions: [
          IconButton(
            onPressed: () {
              SocketManager.instance.disconnect();
            },
            icon: const Icon(Icons.wifi_off_sharp),
          ),
          IconButton(
            onPressed: () {
              // TODO(Kevin): we need to recreate all socket configuration what we have done in the initState
              _initialize();
            },
            icon: const Icon(Icons.wifi),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Participants(),
          ),
          Expanded(
            flex: 6,
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: DrawBoard(
                    username: widget.username,
                    room: widget.room,
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: AnswersChat(
                          username: widget.username,
                          room: widget.room,
                        ),
                      ),
                      Expanded(
                        child: MessageChat(
                          username: widget.username,
                          room: widget.room,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
