import 'package:drawly/features/draw_game/message_chat/draw_game_message.dart';
import 'package:drawly/features/draw_game/message_chat/messages_chat_view.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:flutter/material.dart';

abstract class MessagesChatViewModel extends State<MessagesChatView> {
  final rxAllMessages = ValueNotifier<List<DrawGameMessage>>([]);
  final TextEditingController messageController = TextEditingController();

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

  void _initializeChatSocket() {
    SocketManager.instance.on('message:new', (data) {
      final message = DrawGameMessage.fromJson(data);
      rxAllMessages.value = List.from(rxAllMessages.value)..add(message);
    });

    SocketManager.instance.onDisconnect((_) {});
  }

  void sendMessage() {
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
