import 'dart:developer' as developer;

import 'package:drawing_board/drawing_board.dart';
import 'package:drawly/features/draw_game/answers_chat/answers_chat.dart';
import 'package:drawly/features/draw_game/message_chat/message_chat.dart';
import 'package:drawly/features/draw_game/participants/all_participants.dart';
import 'package:drawly/tests.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:flutter/material.dart';

class DrawGameRoomPage extends StatefulWidget {
  final String username;
  final String roomName;

  const DrawGameRoomPage({
    super.key,
    required this.username,
    required this.roomName,
  })  : assert(username.length >= 3, 'The username must be at least 3 characters long'),
        assert(roomName.length >= 3, 'The roomName must be at least 3 characters long');

  @override
  State<DrawGameRoomPage> createState() => _DrawGameRoomPageState();
}

abstract class GamePageViewModel extends State<DrawGameRoomPage> {
  final currentDrawer = ValueNotifier<String>("Waiting...");
  final isCurrentDrawer = ValueNotifier<bool>(false);
  final totalDuration = ValueNotifier<int>(0);
  final timeLeft = ValueNotifier<int>(0);

  bool _hasJoinedRoom = false;

  void _initialize() {
    _initializeSocket();
  }

  void _initializeSocket() {
    SocketManager.instance.connect();

    SocketManager.instance.onConnect((_) {
      if (!_hasJoinedRoom) {
        Tests.createRoom(widget.roomName);
        _joinGameRoom();
        _hasJoinedRoom = true;
      }
    });

    SocketManager.instance.on('newTurn', (data) {
      developer.log("New turn event received: $data");

      currentDrawer.value = data['currentDrawer'];
      totalDuration.value = data['totalDuration'];
      timeLeft.value = data['totalDuration'];
      isCurrentDrawer.value = currentDrawer.value == widget.username;

      startCountdown(totalDuration.value);
    });
  }

  void startCountdown(int durationInMs) {
    int remaining = durationInMs;

    Future.doWhile(() async {
      if (remaining <= 0) return false;

      await Future.delayed(const Duration(milliseconds: 100));
      remaining -= 100;
      timeLeft.value = remaining;

      return true;
    });
  }

  void _joinGameRoom() {
    SocketManager.instance.emit('joinRoom', {
      'username': widget.username,
      'roomName': widget.roomName,
    });
  }

  void _leaveRoom() {
    SocketManager.instance.emit('leaveRoom', {
      'username': widget.username,
      'roomName': widget.roomName,
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
    SocketManager.instance.off('newTurn');
    _leaveRoom();
    currentDrawer.dispose();
    isCurrentDrawer.dispose();
    totalDuration.dispose();
    timeLeft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          // backgroundColor: isCurrentDrawer.value ? lightPrimary : Colors.white,
          appBar: AppBar(
            title: ValueListenableBuilder(
              valueListenable: currentDrawer,
              builder: (context, value, child) {
                return Text('Drawly.io > Room - ${widget.roomName} > Current drawer: $value');
              },
            ),
            actions: [
              IconButton(
                onPressed: Tests.testReconnection,
                icon: const Icon(Icons.wifi_off_sharp),
              ),
            ],
          ),
          body: Column(
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([
                  timeLeft,
                  totalDuration,
                ]),
                builder: (context, _) {
                  if (timeLeft.value <= 0) return const SizedBox.shrink();
                  return LinearProgressIndicator(
                    value: timeLeft.value / totalDuration.value,
                    minHeight: 5,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCurrentDrawer.value ? Colors.green : Colors.blue,
                    ),
                  );
                },
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: AllParticipants()),
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ValueListenableBuilder(
                              valueListenable: isCurrentDrawer,
                              builder: (context, value, child) {
                                return DrawingBoard(
                                  username: widget.username,
                                  roomName: widget.roomName,
                                  isCurrentDrawer: value,
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: ValueListenableBuilder(
                                    valueListenable: isCurrentDrawer,
                                    builder: (context, value, child) {
                                      return AnswersChat(
                                        username: widget.username,
                                        roomName: widget.roomName,
                                        isCurrentDrawer: value,
                                      );
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: ValueListenableBuilder(
                                    valueListenable: isCurrentDrawer,
                                    builder: (context, value, child) {
                                      return MessageChat(
                                        username: widget.username,
                                        roomName: widget.roomName,
                                        isCurrentDrawer: value,
                                      );
                                    },
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
