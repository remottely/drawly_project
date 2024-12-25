import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum MessageIconType {
  info,
  check,
  clock,
  draw,
}

class Message extends Equatable {
  const Message({
    required this.icon,
    required this.userId,
    required this.text,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      icon: MessageIconType.values.cast<MessageIconType?>().firstWhere(
            (e) => e!.name == (json['icon']),
            orElse: () => null,
          ),
      userId: json['userId'] as String,
      text: json['text'] as String,
    );
  }

  final MessageIconType? icon;
  final String userId;
  final String text;

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
      _ => AppColors.greyAccent,
    };
  }

  // Map<String, dynamic> toJson() {
  //   return {
  //     'icon': icon?.name,
  //     'userId': userId,
  //     'text': text,
  //   };
  // }

  // Map<String, dynamic> toSendMessageSocketJson({
  //   required String roomName,
  //   required String message,
  // }) {
  //   return {
  //     'roomName': roomName,
  //     'userId': userId,
  //     'text': message,
  //   };
  // }

  Message copyWith({
    MessageIconType? icon,
    String? userId,
    String? text,
  }) {
    return Message(
      icon: icon ?? this.icon,
      userId: userId ?? this.userId,
      text: text ?? this.text,
    );
  }

  @override
  List<Object?> get props => [icon, userId, text];
}
