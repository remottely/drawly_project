import 'package:drawly/features/draw_game/answers_chat/models/answer_model.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class AnswersChat extends StatefulWidget {
  final String username;
  final String roomName;
  final bool isCurrentDrawer;
  final bool isGameStarted;

  const AnswersChat({
    super.key,
    required this.username,
    required this.roomName,
    required this.isCurrentDrawer,
    required this.isGameStarted,
  })  : assert(username.length >= 3, 'The username must be at least 3 characters long'),
        assert(roomName.length >= 3, 'The roomName must be at least 3 characters long');

  @override
  State<AnswersChat> createState() => _AnswersChatState();
}

abstract class PictionaryScreenViewModel extends State<AnswersChat> {
  final _rxAllAnswers = ValueNotifier<List<AnswerModel>>([]);
  final _rxIsCurrentUserCorrectAnswer = ValueNotifier<bool>(false);
  final answerController = TextEditingController();

  void _initializeChatSocket() {
    SocketManager.instance.on('answerChat:new', (data) {
      final answer = AnswerModel.fromJson(data);
      _rxAllAnswers.value = List.from(_rxAllAnswers.value)..add(answer);

      _rxIsCurrentUserCorrectAnswer.value = answer.isCorrect && answer.username == widget.username;
    });
  }

  void _sendAnswer() {
    if (answerController.text.isNotEmpty) {
      final answer = answerController.text;
      SocketManager.instance.emit('answerChat:send', {
        'username': widget.username,
        'roomName': widget.roomName,
        'answer': answer,
      });

      answerController.clear();
    }
  }
}

class _AnswersChatState extends PictionaryScreenViewModel {
  @override
  void initState() {
    super.initState();
    _initializeChatSocket();
  }

  @override
  void dispose() {
    answerController.dispose();
    SocketManager.instance.off('answerChat:new');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrawlyContainer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_rxIsCurrentUserCorrectAnswer]),
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_rxAllAnswers]),
                  builder: (context, _) {
                    return ListView.builder(
                      itemCount: _rxAllAnswers.value.length,
                      itemBuilder: (context, index) {
                        return _AnswerChatText(answer: _rxAllAnswers.value[index]);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DrawlyIconBorderedTextField(
                  controller: answerController,
                  leftIcon: Icons.draw,
                  rightIcon: Icons.send,
                  onRightIconPressed: _sendAnswer,
                  isCurrentDrawer:
                      widget.isCurrentDrawer || !widget.isGameStarted || _rxIsCurrentUserCorrectAnswer.value,
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
  final AnswerModel answer;

  const _AnswerChatText({
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        "${answer.username}: ${answer.isCorrect ? '****' : answer.answer}",
        style: TextStyle(
          color: answer.isCorrect ? Colors.green : Colors.grey,
          fontSize: 16,
        ),
      ),
    );
  }
}
