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
  final _rxAllAnswers = ValueNotifier<List<String>>([]);
  // final _rxIsCorrectAnswer = ValueNotifier<bool>(false);
  final answerController = TextEditingController();

  void _initializeChatSocket() {
    SocketManager.instance.on('answerChat:new', (data) {
      _rxAllAnswers.value = List.from(_rxAllAnswers.value)..add("${data['username']}: ${data['answer']}");

      // _rxIsCorrectAnswer.value = data['isCorrect'];
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
      child: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _rxAllAnswers,
                // _rxIsCorrectAnswer,
              ]),
              builder: (context, _) {
                return ListView.builder(
                  itemCount: _rxAllAnswers.value.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        _rxAllAnswers.value[index],
                        // style: TextStyle(color: _rxIsCorrectAnswer.value ? Colors.green : Colors.grey),
                      ),
                    );
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
              isCurrentDrawer: widget.isCurrentDrawer || !widget.isGameStarted,
            ),
          ),
        ],
      ),
    );
  }
}
