import 'package:drawly/features/draw_game/message_chat/models/answer_model.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class MessageChat extends StatefulWidget {
  final String username;
  final String roomName;
  final bool isCurrentDrawer;

  const MessageChat({
    super.key,
    required this.username,
    required this.roomName,
    required this.isCurrentDrawer,
  })  : assert(username.length >= 3, 'The username must be at least 3 characters long'),
        assert(roomName.length >= 3, 'The roomName must be at least 3 characters long');

  @override
  State<MessageChat> createState() => _MessageChatState();
}

abstract class PictionaryScreenViewModel extends State<MessageChat> {
  final _rxAllMessages = ValueNotifier<List<MessageModel>>([]);
  final TextEditingController messageController = TextEditingController();

  void _initializeChatSocket() {
    SocketManager.instance.on('message:new', (data) {
      final message = MessageModel.fromJson(data);
      _rxAllMessages.value = List.from(_rxAllMessages.value)..add(message);
    });

    SocketManager.instance.onDisconnect((_) {});
  }

  void _sendMessage() {
    if (messageController.text.isNotEmpty) {
      final message = messageController.text;
      SocketManager.instance.emit('message:send', {
        'username': widget.username,
        'roomName': widget.roomName,
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
    SocketManager.instance.off('message:new');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrawlyContainer(
      child: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<List<MessageModel>>(
              valueListenable: _rxAllMessages,
              builder: (context, value, child) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return _MessageChatText(message: _rxAllMessages.value[index]);
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
              isBlocked: widget.isCurrentDrawer,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageChatText extends StatelessWidget {
  final MessageModel message;

  const _MessageChatText({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        "${message.username}: ${message.message}",
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      ),
    );
  }
}
