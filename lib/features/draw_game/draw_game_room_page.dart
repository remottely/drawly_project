import 'package:draw_board/draw_board.dart';
import 'package:drawly/features/draw_game/answers_chat/answers_chat.dart';
import 'package:drawly/features/draw_game/message_chat/message_chat.dart';
import 'package:drawly/features/draw_game/participants/all_participants.dart';
import 'package:drawly/tests.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class DrawGameRoomPage extends StatefulWidget {
  final String username;
  final String room;

  const DrawGameRoomPage({
    super.key,
    required this.username,
    required this.room,
  })  : assert(username.length >= 3, 'The username must be at least 3 characters long'),
        assert(room.length >= 3, 'The room must be at least 3 characters long');

  @override
  State<DrawGameRoomPage> createState() => _DrawGameRoomPageState();
}

abstract class GamePageViewModel extends State<DrawGameRoomPage> {
  _initialize() {
    _initializeSocket();
    _createRoom();
    _joinGameRoom();
  }

  /// Initializes the socket connection and defines event handlers
  void _initializeSocket() {
    SocketManager.instance.connect();

    SocketManager.instance.onConnect((_) {
      _joinGameRoom();
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
  }

  // Notify the server that the user is leaving the room
  void _leaveRoom() {
    SocketManager.instance.emit('leaveRoom', {
      'username': widget.username,
      'room': widget.room,
    });
  }
}

class _DrawGameRoomPageState extends GamePageViewModel {
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
    return Stack(
      children: [
        Scaffold(
          backgroundColor: lightPrimary,
          appBar: AppBar(
            title: Text('Drawly.io > Room - ${widget.room}'),
            actions: [
              IconButton(
                onPressed: Tests.testReconnection,
                icon: const Icon(Icons.wifi_off_sharp),
              ),
            ],
          ),
          body: Row(
            children: [
              Expanded(
                child: AllParticipants(),
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
        ),
        // MeteorShower(
        //   numberOfMeteors: 20,
        //   duration: Duration(seconds: 10),
        //   child: Center(),
        // ),
      ],
    );
  }
}
