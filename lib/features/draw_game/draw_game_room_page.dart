import 'dart:developer' as developer;
import 'dart:ui';

import 'package:drawing_board/drawing_board.dart';
import 'package:drawly/features/draw_game/chats/answers_chat/answers_chat_view.dart';
import 'package:drawly/features/draw_game/chats/message_chat/messages_chat_view.dart';
import 'package:drawly/features/draw_game/models/answer.dart';
import 'package:drawly/features/draw_game/participants/all_participants.dart';
import 'package:drawly/testing/tests.dart';
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
  final rxWord = ValueNotifier<String>('');
  final rxCurrentDrawer = ValueNotifier<String>('Waiting...');
  final rxIsCurrentDrawer = ValueNotifier<bool>(false);
  final rxTotalDuration = ValueNotifier<int>(0);
  final rxTimeLeft = ValueNotifier<int>(0);
  final rxAllAnswers = ValueNotifier<List<Answer>>([]);
  final rxIsCurrentUserCorrectAnswer = ValueNotifier<bool>(false);

  // bool _hasJoinedRoom = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    SocketManager.instance.off('turn:new');
    _leaveRoom();
    rxCurrentDrawer.dispose();
    rxIsCurrentDrawer.dispose();
    rxTotalDuration.dispose();
    rxTimeLeft.dispose();
    super.dispose();
  }

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

    SocketManager.instance.on('turn:new', (data) {
      developer.log("New turn event received: $data");

      rxWord.value = data['word'];
      rxCurrentDrawer.value = data['currentDrawer'];
      rxTotalDuration.value = data['totalDuration'];
      rxTimeLeft.value = data['totalDuration'];
      rxIsCurrentDrawer.value = rxCurrentDrawer.value == widget.username;

      rxAllAnswers.value = [];
      rxIsCurrentUserCorrectAnswer.value = false;

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
    final payload = RoomUserDTO(
      roomName: widget.roomName,
      username: widget.username,
    ).toJson();

    SocketManager.instance.emit('room:join', payload);
  }

  void _leaveRoom() {
    final payload = RoomUserDTO(
      roomName: widget.roomName,
      username: widget.username,
    ).toJson();

    SocketManager.instance.emit('room:leave', payload);
  }
}

class _DrawGameRoomPageState extends GamePageViewModel {
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
              backgroundColor: rxIsCurrentDrawer.value ? AppColors.lightSecondary : AppColors.lightPrimary,
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
                          rxIsCurrentDrawer.value ? AppColors.redAccent : AppColors.blueAccent,
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                DrawlyFakeAppBar(
                                  children: [
                                    Flexible(
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Text(
                                          '${widget.roomName}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: AllParticipants(),
                                ),
                              ],
                            )),
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              DrawlyFakeAppBar(
                                children: [
                                  if (rxIsCurrentDrawer.value)
                                    DrawlyTitleContainer(
                                      text: rxWord.value,
                                    )
                                  else
                                    DrawlyTitleContainer(
                                      text: 'Current drawer: ${rxCurrentDrawer.value}',
                                    ),
                                  Tests.isTesting
                                      ? IconButton(
                                          onPressed: Tests.testReconnection,
                                          icon: const Icon(Icons.wifi_off_sharp),
                                        )
                                      : const SizedBox.shrink(),
                                ],
                              ),
                              Expanded(
                                flex: 3,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    DrawingBoard(
                                      username: widget.username,
                                      roomName: widget.roomName,
                                      word: rxWord.value,
                                      isCurrentDrawer: rxIsCurrentDrawer.value,
                                    ),
                                    ValueListenableBuilder<int>(
                                      valueListenable: rxTotalDuration,
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value == 0 ? 1.0 : 0.0,
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
                                                        final payload = RoomDTO(
                                                          roomName: widget.roomName,
                                                        ).toJson();

                                                        SocketManager.instance.emit(
                                                          'game:turns:start',
                                                          payload,
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
                                            rxAllAnswers: rxAllAnswers,
                                            rxIsCurrentUserCorrectAnswer: rxIsCurrentUserCorrectAnswer,
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

class DrawlyFakeAppBar extends StatelessWidget {
  final List<Widget> children;

  const DrawlyFakeAppBar({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: children,
      ),
    );
  }
}
