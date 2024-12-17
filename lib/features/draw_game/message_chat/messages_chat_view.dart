import 'package:drawly/features/draw_game/message_chat/message.dart';
import 'package:drawly/features/draw_game/message_chat/messages_chat_viewmodel.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class MessagesChatView extends StatefulWidget {
  final String username;
  final String roomName;
  final bool isCurrentDrawer;

  const MessagesChatView({
    super.key,
    required this.username,
    required this.roomName,
    required this.isCurrentDrawer,
  })  : assert(username.length >= 3, 'The username must be at least 3 characters long'),
        assert(roomName.length >= 3, 'The roomName must be at least 3 characters long');

  @override
  State<MessagesChatView> createState() => _MessagesChatViewState();
}

class _MessagesChatViewState extends MessagesChatViewModel {
  @override
  Widget build(BuildContext context) {
    return DrawlyContainer(
      child: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<List<Message>>(
              valueListenable: rxAllMessages,
              builder: (context, value, child) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return _MessageChatText(message: rxAllMessages.value[index]);
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
              onRightIconPressed: sendMessage,
              isBlocked: widget.isCurrentDrawer,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageChatText extends StatelessWidget {
  final Message message;

  const _MessageChatText({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final IconData? icon = message.icon == 'info' ? Icons.info : null;
    final Color? color = message.icon == 'info' ? Colors.blue : null;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              Icons.info,
              color: color,
            ),
            SizedBox(width: 4)
          ],
          Text(
            "${message.username}: ${message.message}",
            style: TextStyle(
              color: color ?? Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
