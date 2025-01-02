import 'package:drawly/features/draw_game/chats/message_chat/messages_chat_viewmodel.dart';
import 'package:drawly/features/draw_game/models/message.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class MessagesChatView extends StatefulWidget {
  const MessagesChatView({
    required this.userId,
    required this.username,
    required this.roomName,
    required this.isCurrentDrawer,
    super.key,
  })  : assert(
          username.length >= 3,
          'The username must be at least 3 characters long',
        ),
        assert(
          roomName.length >= 3,
          'The roomName must be at least 3 characters long',
        );

  final String userId;
  final String username;
  final String roomName;
  final bool isCurrentDrawer;

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
              builder: (_, value, __) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    scrollController
                        .jumpTo(scrollController.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: scrollController,
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return _MessageChatText(
                      message: rxAllMessages.value[index],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: DrawlyChatTextField(
              controller: messageController,
              leftIcon: Icons.question_answer,
              rightIcon: Icons.send,
              onRightIconPressed: sendMessage,
              disabled: widget.isCurrentDrawer,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageChatText extends StatelessWidget {
  const _MessageChatText({
    required this.message,
  });

  final Message message;

  @override
  Widget build(BuildContext context) {
    final icon = message.getIcon();
    final color = message.getColor();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: message.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: ' ${message.text}',
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
