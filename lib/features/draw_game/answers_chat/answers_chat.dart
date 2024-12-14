import 'package:drawly_core/drawly_core.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

/// Main drawing screen where the user interacts with the Pictionary game
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
  final _rxAllAnswers = ValueNotifier<List<String>>([]); // Messages received from the server
  final answerController = TextEditingController();

  /// Initializes the socket connection and defines event handlers
  void _initializeChatSocket() {
    // Handle new answer event
    SocketManager.instance.on('newAnswerChat', (data) {
      _rxAllAnswers.value = List.from(_rxAllAnswers.value)..add("${data['username']}: ${data['answer']}");
    });
  }

  /// Sends a chat answer to the server
  void _sendAnswer() {
    if (answerController.text.isNotEmpty) {
      final answer = answerController.text;
      SocketManager.instance.emit('sendAnswerChat', {
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
    SocketManager.instance.off('newAnswerChat');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrawlyContainer(
      child: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<List<String>>(
              valueListenable: _rxAllAnswers,
              builder: (context, value, child) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(value[index]),
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
