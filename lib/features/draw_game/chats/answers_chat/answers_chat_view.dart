import 'package:drawly/features/draw_game/chats/answers_chat/answers_chat_viewmodel.dart';
import 'package:drawly/features/draw_game/chats/answers_chat/models/answer.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class AnswersChatView extends StatefulWidget {
  final String username;
  final String roomName;
  final bool isCurrentDrawer;
  final bool isGameStarted;

  const AnswersChatView({
    super.key,
    required this.username,
    required this.roomName,
    required this.isCurrentDrawer,
    required this.isGameStarted,
  })  : assert(username.length >= 3, 'The username must be at least 3 characters long'),
        assert(roomName.length >= 3, 'The roomName must be at least 3 characters long');

  @override
  State<AnswersChatView> createState() => _AnswersChatViewState();
}

class _AnswersChatViewState extends AnswersChatViewModel {
  @override
  Widget build(BuildContext context) {
    return DrawlyContainer(
      child: AnimatedBuilder(
        animation: Listenable.merge([rxIsCurrentUserCorrectAnswer]),
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: Listenable.merge([rxAllAnswers]),
                  builder: (context, _) {
                    return ListView.builder(
                      itemCount: rxAllAnswers.value.length,
                      itemBuilder: (context, index) {
                        return _AnswerChatText(answer: rxAllAnswers.value[index]);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DrawlyChatTextField(
                  controller: answerController,
                  hintText: widget.isCurrentDrawer
                      ? ''
                      : rxIsCurrentUserCorrectAnswer.value
                          ? 'Você acertou!'
                          : 'Responda aqui...',
                  hintColor: rxIsCurrentUserCorrectAnswer.value ? Colors.green : null,
                  leftIcon: Icons.draw,
                  rightIcon: Icons.send,
                  onRightIconPressed: sendAnswer,
                  disabled: widget.isCurrentDrawer || !widget.isGameStarted || rxIsCurrentUserCorrectAnswer.value,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnswerChatText extends StatelessWidget {
  final Answer answer;

  const _AnswerChatText({
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    final icon = answer.getIcon();
    final color = answer.getColor();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color,
            ),
            SizedBox(width: 4)
          ],
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "${answer.username} ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: "${answer.isCorrect ? 'acertou!' : answer.text}",
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
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
