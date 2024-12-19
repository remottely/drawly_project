import 'package:drawly/features/draw_game/chats/answers_chat/answers_chat_view.dart';
import 'package:drawly/features/draw_game/models/answer.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:flutter/material.dart';

abstract class AnswersChatViewModel extends State<AnswersChatView> {
  final answerController = TextEditingController();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  @override
  void dispose() {
    answerController.dispose();
    SocketManager.instance.offEvent('answer:new', _onNewAnswerEvent);
    super.dispose();
  }

  void _onNewAnswerEvent(dynamic data) {
    final answer = Answer.fromJson(data as Map<String, dynamic>);
    widget.rxAllAnswers.value = List.from(widget.rxAllAnswers.value)..add(answer);

    widget.rxIsCurrentUserCorrectAnswer.value = answer.isCorrect && answer.username == widget.username;
  }

  void _initializeSocket() {
    SocketManager.instance.onEvent('answer:new', _onNewAnswerEvent);
  }

  void sendAnswer() {
    if (answerController.text.isNotEmpty) {
      final answer = answerController.text;

      final payload = RoomUserAnswerDTO(
        roomName: widget.roomName,
        username: widget.username,
        text: answer,
      ).toJson();

      SocketManager.instance.emit('answer:send', payload);

      answerController.clear();
    }
  }
}
