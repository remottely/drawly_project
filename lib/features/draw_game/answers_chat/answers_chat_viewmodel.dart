import 'package:drawly/features/draw_game/answers_chat/answer.dart';
import 'package:drawly/features/draw_game/answers_chat/answers_chat_view.dart';
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
      SocketManager.instance.emit('answer:send', {
        'username': widget.username,
        'roomName': widget.roomName,
        'answer': answer,
      });

      answerController.clear();
    }
  }
}
