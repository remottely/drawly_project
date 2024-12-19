import 'package:drawly/features/draw_game/chats/message_chat/messages_chat_view.dart';
import 'package:drawly/features/draw_game/models/message.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:flutter/material.dart';

abstract class MessagesChatViewModel extends State<MessagesChatView> {
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  final rxAllMessages = ValueNotifier<List<Message>>([]);

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  @override
  void dispose() {
    messageController.dispose();
    SocketManager.instance.offEvent('message:new', (data) => _onNewMessageEvent(data));
    super.dispose();
  }

  void _onNewMessageEvent(dynamic data) {
    final message = Message.fromJson(data);
    rxAllMessages.value = List.from(rxAllMessages.value)..add(message);
  }

  void _initializeSocket() {
    SocketManager.instance.onEvent('message:new', (data) => _onNewMessageEvent(data));
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
