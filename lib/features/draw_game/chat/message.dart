import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum MessageIconType {
  info,
  check,
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
    final x = switch (icon) {
      MessageIconType.info => Icons.info,
      MessageIconType.check => Icons.check,
      _ => null,
    };
    final y = x == Icons.check;
    return x;
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
            (e) => e?.name == (json['icon'] as String?),
            orElse: () => null,
          ),
      username: json['username'] as String,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icon': icon?.name,
      'username': username,
      'text': text,
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
