import 'package:drawly_core/drawly_core.dart';
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
  final ValueNotifier<List<String>> rxMessages = ValueNotifier([]); // Messages received from the server
  final TextEditingController messageController = TextEditingController();

  /// Initializes the socket connection and defines event handlers
  void _initializeChatSocket() {
    // Handle new message event
    SocketManager.instance.on('newMessage', (data) {
      rxMessages.value = List.from(rxMessages.value)..add("${data['username']}: ${data['message']}");
    });
  }

  /// Sends a chat message to the server
  void _sendMessage() {
    if (messageController.text.isNotEmpty) {
      final message = messageController.text;
      SocketManager.instance.emit('sendMessage', {
        'room': widget.room,
        'message': message,
        'username': widget.username,
      });

      messageController.clear();
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
    messageController.dispose();
    SocketManager.instance.off('newMessage');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ValueListenableBuilder<List<String>>(
            valueListenable: rxMessages,
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your message',
                  ),
                ),
              ),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
              ),
              IconButton(
                onPressed: () {
                  SocketManager.instance.disconnect();
                },
                icon: const Icon(Icons.wifi_off_sharp),
              ),
              IconButton(
                onPressed: () {
                  // TODO(Kevin): we need to recreate all socket configuration what we have done in the initState
                  // _initialize();
                },
                icon: const Icon(Icons.wifi),
              ),
            ],
          ),
        ),
      ],
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
