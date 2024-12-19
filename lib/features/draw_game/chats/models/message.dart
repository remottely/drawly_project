import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum MessageIconType {
  info,
  check,
  clock,
  draw,
}

class Message extends Equatable {
  final MessageIconType? icon;
  final String username;
  final String text;

  Message({
    required this.icon,
    required this.username,
    required this.text,
  });

  IconData? getIcon() {
    return switch (icon) {
      MessageIconType.info => Icons.info,
      MessageIconType.check => Icons.check,
      _ => null,
    };
  }

  Color getColor() {
    return switch (icon) {
      MessageIconType.info => Colors.blue,
      MessageIconType.check => Colors.green,
      _ => Colors.grey,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      icon: MessageIconType.values.cast<MessageIconType?>().firstWhere(
            (e) => e!.name == (json['icon']),
            orElse: () => null,
          ),
      username: json['username'],
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icon': icon?.name,
      'username': username,
      'text': text,
    };
  }

  Map<String, dynamic> toSendMessageSocketJson({
    required String roomName,
    required String message,
  }) {
    return {
      'roomName': roomName,
      'username': username,
      'text': message,
    };
  }

  Message copyWith({
    MessageIconType? icon,
    String? username,
    String? text,
  }) {
    return Message(
      icon: icon ?? this.icon,
      username: username ?? this.username,
      text: text ?? this.text,
    );
  }

  @override
  List<Object?> get props => [icon, username, text];
}
