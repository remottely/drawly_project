import 'package:drawly/features/draw_game/chats/message_chat/messages_chat_view.dart';
import 'package:drawly/features/draw_game/models/message.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:flutter/material.dart';

abstract class MessagesChatViewModel extends State<MessagesChatView> {
  final rxAllMessages = ValueNotifier<List<Message>>([]);
  final TextEditingController messageController = TextEditingController();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  @override
  void dispose() {
    messageController.dispose();
    SocketManager.instance.off('message:new');
    super.dispose();
  }

  void _initializeSocket() {
    SocketManager.instance.on('message:new', (data) {
      final message = Message.fromJson(data);
      rxAllMessages.value = List.from(rxAllMessages.value)..add(message);
    });

    SocketManager.instance.onDisconnect((_) {});
  }

  void sendMessage() {
    if (messageController.text.isNotEmpty) {
      final message = messageController.text;
      final payload = RoomUserMessageDTO(
        roomName: widget.roomName,
        username: widget.username,
        text: message,
      ).toJson();

      SocketManager.instance.emit('message:send', payload);

      messageController.clear();
    }
  }
}
