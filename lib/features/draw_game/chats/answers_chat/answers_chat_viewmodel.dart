import 'package:drawly/features/draw_game/chats/answers_chat/answers_chat_view.dart';
import 'package:drawly/features/draw_game/chats/answers_chat/models/answer.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:flutter/material.dart';

abstract class AnswersChatViewModel extends State<AnswersChatView> {
  final rxAllAnswers = ValueNotifier<List<Answer>>([]);
  final rxIsCurrentUserCorrectAnswer = ValueNotifier<bool>(false);
  final answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  @override
  void dispose() {
    answerController.dispose();
    SocketManager.instance.off('answer:new');
    super.dispose();
  }

  void _initializeSocket() {
    SocketManager.instance.on('answer:new', (data) {
      final answer = Answer.fromJson(data);
      rxAllAnswers.value = List.from(rxAllAnswers.value)..add(answer);

      rxIsCurrentUserCorrectAnswer.value = answer.isCorrect && answer.username == widget.username;
    });
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
