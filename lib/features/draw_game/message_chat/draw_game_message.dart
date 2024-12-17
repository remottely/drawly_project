import 'package:equatable/equatable.dart';

/// A model representing a message in the draw game chat.
class DrawGameMessage extends Equatable {
  /// The icon associated with the message.
  final String? icon;

  /// The username of the person who sent the message.
  final String username;

  /// The content of the message.
  final String message;

  /// Creates an instance of [DrawGameMessage].
  DrawGameMessage({
    required this.icon,
    required this.username,
    required this.message,
  });

  /// Creates an instance of [DrawGameMessage] from a JSON object.
  factory DrawGameMessage.fromJson(Map<String, dynamic> json) {
    return DrawGameMessage(
      icon: json['icon'] as String?,
      username: json['username'] as String,
      message: json['message'] as String,
    );
  }

  /// Converts the [DrawGameMessage] instance to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'username': username,
      'message': message,
    };
  }

  /// Creates a copy of the current [DrawGameMessage] with new values.
  DrawGameMessage copyWith({
    String? icon,
    String? username,
    String? message,
  }) {
    return DrawGameMessage(
      icon: icon ?? this.icon,
      username: username ?? this.username,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [icon, username, message];
}
