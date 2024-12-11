import 'package:drawly_core/drawly_core.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

/// Main drawing screen where the user interacts with the Pictionary game
class MessageChat extends StatefulWidget {
  const MessageChat({
    super.key,
    required this.username,
    required this.room,
  })  : assert(username.length >= 3, 'The username must be at least 3 characters long'),
        assert(room.length >= 3, 'The room must be at least 3 characters long');

  final String username;
  final String room;

  @override
  State<MessageChat> createState() => _MessageChatState();
}

abstract class PictionaryScreenViewModel extends State<MessageChat> {
  final _rxAllMessages = ValueNotifier<List<String>>([]); // Messages received from the server
  final TextEditingController messageController = TextEditingController();

  /// Initializes the socket connection and defines event handlers
  void _initializeChatSocket() {
    // Handle new message event
    SocketManager.instance.on('newMessageChat', (data) {
      _rxAllMessages.value = List.from(_rxAllMessages.value)..add("${data['username']}: ${data['message']}");
    });

    SocketManager.instance.onDisconnect((_) {});
  }

  /// Sends a chat message to the server
  void _sendMessage() {
    if (messageController.text.isNotEmpty) {
      final message = messageController.text;
      SocketManager.instance.emit('sendMessageChat', {
        'username': widget.username,
        'room': widget.room,
        'message': message,
      });

      messageController.clear();
    }
  }
}

class _MessageChatState extends PictionaryScreenViewModel {
  @override
  void initState() {
    super.initState();
    _initializeChatSocket();
  }

  @override
  void dispose() {
    messageController.dispose();
    SocketManager.instance.off('newMessageChat');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrawlyContainer(
      child: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<List<String>>(
              valueListenable: _rxAllMessages,
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
              controller: messageController,
              leftIcon: Icons.question_answer,
              rightIcon: Icons.send,
              onRightIconPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
