import 'dart:developer' as developer;
import 'dart:ui';

import 'package:drawing_board/drawing_board.dart';
import 'package:drawly/features/draw_game/answers_chat/answers_chat_view.dart';
import 'package:drawly/features/draw_game/message_chat/messages_chat_view.dart';
import 'package:drawly/features/draw_game/participants/all_participants.dart';
import 'package:drawly/tests.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
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
  final rxWord = ValueNotifier<String>("???");
  final rxCurrentDrawer = ValueNotifier<String>("Waiting...");
  final rxIsCurrentDrawer = ValueNotifier<bool>(false);
  final rxTotalDuration = ValueNotifier<int>(0);
  final rxTimeLeft = ValueNotifier<int>(0);

  // bool _hasJoinedRoom = false;

  void _initialize() {
    _initializeSocket();
  }

  void _initializeSocket() {
    SocketManager.instance.connect();

    SocketManager.instance.onConnect((_) {
      // if (!_hasJoinedRoom) {
      Tests.createRoom(widget.roomName);
      _joinGameRoom();
      // _hasJoinedRoom = true;
      // }
    });

    SocketManager.instance.on('newTurn', (data) {
      developer.log("New turn event received: $data");

      rxWord.value = data['word'];
      rxCurrentDrawer.value = data['currentDrawer'];
      rxTotalDuration.value = data['totalDuration'];
      rxTimeLeft.value = data['totalDuration'];
      rxIsCurrentDrawer.value = rxCurrentDrawer.value == widget.username;

      startCountdown(rxTotalDuration.value);
    });
  }

  void startCountdown(int durationInMs) {
    int remaining = durationInMs;

    Future.doWhile(() async {
      if (remaining <= 0) return false;

      await Future.delayed(const Duration(milliseconds: 100));
      remaining -= 100;
      rxTimeLeft.value = remaining;

      return true;
    });
  }

  void _joinGameRoom() {
    SocketManager.instance.emit('room:join', {
      'username': widget.username,
      'roomName': widget.roomName,
    });
  }

  void _leaveRoom() {
    SocketManager.instance.emit('room:leave', {
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
    rxCurrentDrawer.dispose();
    rxIsCurrentDrawer.dispose();
    rxTotalDuration.dispose();
    rxTimeLeft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([
            rxIsCurrentDrawer,
            rxWord,
          ]),
          builder: (context, _) {
            return Scaffold(
              backgroundColor: rxIsCurrentDrawer.value ? Colors.red : lightPrimary,
              appBar: AppBar(
                title: AnimatedBuilder(
                  animation: Listenable.merge([
                    rxCurrentDrawer,
                    rxWord,
                  ]),
                  builder: (context, _) {
                    return Text('Drawly.io > Room - ${widget.roomName} > Current drawer: ${rxCurrentDrawer.value}' +
                        ' > Word: ${rxWord.value}');
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
                      rxTimeLeft,
                      rxTotalDuration,
                    ]),
                    builder: (context, _) {
                      if (rxTimeLeft.value <= 0) return const SizedBox.shrink();
                      return LinearProgressIndicator(
                        value: rxTimeLeft.value / rxTotalDuration.value,
                        minHeight: 5,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          rxIsCurrentDrawer.value ? Colors.green : Colors.blue,
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
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      DrawingBoard(
                                        username: widget.username,
                                        roomName: widget.roomName,
                                        isCurrentDrawer: rxIsCurrentDrawer.value,
                                      ),
                                      ValueListenableBuilder(
                                        valueListenable: rxTotalDuration,
                                        builder: (context, value, child) {
                                          return AnimatedOpacity(
                                            opacity: value == 0 ? 1.0 : 0.0,
                                            duration: const Duration(milliseconds: 1000),
                                            child: IgnorePointer(
                                              ignoring: value != 0,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withOpacity(0.5),
                                                  ),
                                                  child: BackdropFilter(
                                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                                    child: Center(
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          SocketManager.instance.emit(
                                                            'game:startTurns',
                                                            {'roomName': widget.roomName},
                                                          );
                                                        },
                                                        child: const Text("Start Game"),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: AnimatedBuilder(
                                    animation: Listenable.merge([
                                      rxTotalDuration,
                                      rxWord,
                                    ]),
                                    builder: (context, _) {
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: AnswersChatView(
                                              username: widget.username,
                                              roomName: widget.roomName,
                                              isCurrentDrawer: rxIsCurrentDrawer.value,
                                              isGameStarted: rxTotalDuration.value != 0 && rxWord.value.isNotEmpty,
                                            ),
                                          ),
                                          Expanded(
                                            child: MessagesChatView(
                                              username: widget.username,
                                              roomName: widget.roomName,
                                              isCurrentDrawer: rxIsCurrentDrawer.value,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        MeteorShower(
          numberOfMeteors: 20,
          duration: Duration(seconds: 10),
          child: Center(),
        ),
      ],
    );
  }
}
