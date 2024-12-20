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
  const DrawGameRoomPage({
    required this.username,
    required this.roomName,
    super.key,
  })  : assert(
          username.length >= 3,
          'The username must be at least 3 characters long',
        ),
        assert(
          roomName.length >= 3,
          'The roomName must be at least 3 characters long',
        );
  final String username;
  final String roomName;

  @override
  State<DrawGameRoomPage> createState() => _DrawGameRoomPageState();
}

abstract class GamePageViewModel extends State<DrawGameRoomPage> {
  final rxWord = ValueNotifier<String>('');
  final rxCurrentDrawer = ValueNotifier<String?>(null);
  final rxIsCurrentDrawer = ValueNotifier<bool>(false);
  final rxTotalDuration = ValueNotifier<int>(0);
  final rxTimeLeft = ValueNotifier<int>(0);
  final rxAllAnswers = ValueNotifier<List<Answer>>([]);
  final rxIsCurrentUserCorrectAnswer = ValueNotifier<bool>(false);

  late final void Function(dynamic) _onConnectEvent;
  late final void Function(dynamic) _onNewTurnEvent;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  @override
  void dispose() {
    SocketManager.instance.offEvent('connect', _onConnectEvent);
    SocketManager.instance.offEvent('turn:new', _onNewTurnEvent);
    _leaveRoom();
    rxCurrentDrawer.dispose();
    rxIsCurrentDrawer.dispose();
    rxTotalDuration.dispose();
    rxTimeLeft.dispose();
    super.dispose();
  }

  void _initializeSocket() {
    Tests.createRoom(widget.roomName);
    _joinGameRoom();
    _onConnectEvent = (_) {
      _joinGameRoom();
    };
    _onNewTurnEvent = (data) {
      rxWord.value = (data as Map<String, dynamic>)['word'] as String;
      rxCurrentDrawer.value = data['currentDrawer'] as String;
      rxTotalDuration.value = data['totalDuration'] as int;
      rxTimeLeft.value = data['totalDuration'] as int;
      rxIsCurrentDrawer.value = rxCurrentDrawer.value == widget.username;

      rxAllAnswers.value = [];
      rxIsCurrentUserCorrectAnswer.value = false;

      startCountdown(rxTotalDuration.value);
    };
    SocketManager.instance.onEvent('connect', _onConnectEvent);
    SocketManager.instance.onEvent('turn:new', _onNewTurnEvent);
  }

  void startCountdown(int durationInMs) {
    var remaining = durationInMs;

    Future.doWhile(() async {
      if (remaining <= 0) return false;

      await Future<void>.delayed(const Duration(milliseconds: 100));
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
              backgroundColor: rxIsCurrentDrawer.value
                  ? AppColors.lightSecondary
                  : AppColors.lightPrimary,
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
                        backgroundColor: AppColors.lightGrey300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          rxIsCurrentDrawer.value
                              ? AppColors.redAccent
                              : AppColors.blueAccent,
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              DrawlyFakeAppBar(
                                children: [
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Text(
                                        widget.roomName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Expanded(
                                child: AllParticipants(),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
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
                                      text: rxCurrentDrawer.value == null
                                          ? 'Intervalo...'
                                          : 'Vez de ${rxCurrentDrawer.value}',
                                    ),
                                  if (Tests.isTesting)
                                    const IconButton(
                                      onPressed: Tests.testReconnection,
                                      icon: Icon(Icons.wifi_off_sharp),
                                    )
                                  else
                                    const SizedBox.shrink(),
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
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                ),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                    sigmaX: 10,
                                                    sigmaY: 10,
                                                  ),
                                                  child: Center(
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        final payload = RoomDTO(
                                                          roomName:
                                                              widget.roomName,
                                                        ).toJson();

                                                        SocketManager.instance
                                                            .emit(
                                                          'game:turns:start',
                                                          payload,
                                                        );
                                                      },
                                                      child: const Text(
                                                        'Start Game',
                                                      ),
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
                                            isCurrentDrawer:
                                                rxIsCurrentDrawer.value,
                                            isGameStarted:
                                                rxTotalDuration.value != 0 &&
                                                    rxWord.value.isNotEmpty,
                                            rxAllAnswers: rxAllAnswers,
                                            rxIsCurrentUserCorrectAnswer:
                                                rxIsCurrentUserCorrectAnswer,
                                          ),
                                        ),
                                        Expanded(
                                          child: MessagesChatView(
                                            username: widget.username,
                                            roomName: widget.roomName,
                                            isCurrentDrawer:
                                                rxIsCurrentDrawer.value,
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
        const MeteorShower(
          numberOfMeteors: 20,
          child: Center(),
        ),
      ],
    );
  }
}

class DrawlyFakeAppBar extends StatelessWidget {
  const DrawlyFakeAppBar({
    required this.children,
    super.key,
  });
  final List<Widget> children;

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
