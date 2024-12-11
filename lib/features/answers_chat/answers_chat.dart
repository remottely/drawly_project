import 'package:drawly_core/drawly_core.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

/// Main drawing screen where the user interacts with the Pictionary game
class AnswersChat extends StatefulWidget {
  const AnswersChat({
    super.key,
    required this.username,
    required this.room,
  })  : assert(username.length >= 3, 'The username must be at least 3 characters long'),
        assert(room.length >= 3, 'The room must be at least 3 characters long');

  final String username;
  final String room;

  @override
  State<AnswersChat> createState() => _AnswersChatState();
}

abstract class PictionaryScreenViewModel extends State<AnswersChat> {
  /// [CHAT]
  final ValueNotifier<List<String>> rxAnswers = ValueNotifier([]); // Messages received from the server
  final TextEditingController answerController = TextEditingController();

  /// Initializes the socket connection and defines event handlers
  void _initializeChatSocket() {
    // Handle new answer event
    SocketManager.instance.on('newAnswerChat', (data) {
      rxAnswers.value = List.from(rxAnswers.value)..add("${data['username']}: ${data['answer']}");
    });
  }

  /// Sends a chat answer to the server
  void _sendAnswer() {
    if (answerController.text.isNotEmpty) {
      final answer = answerController.text;
      SocketManager.instance.emit('sendAnswerChat', {
        'room': widget.room,
        'answer': answer,
        'username': widget.username,
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
              valueListenable: rxAnswers,
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
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to render the drawing
class DrawingPainter extends CustomPainter {
  final List<Offset?> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
