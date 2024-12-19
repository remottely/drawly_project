import 'package:drawly/features/draw_game/models/message.dart';

class Answer extends Message {
  const Answer({
    required super.icon,
    required super.username,
    required super.text,
    required this.isCorrect,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    final message = Message.fromJson(json);

    return Answer(
      icon: message.icon,
      username: message.username,
      text: message.text,
      isCorrect: json['isCorrect'] as bool,
    );
  }
  final bool isCorrect;

  @override
  Map<String, dynamic> toJson() => super.toJson()..['isCorrect'] = isCorrect;

  @override
  Answer copyWith({
    MessageIconType? icon,
    String? username,
    String? text,
    bool? isCorrect,
  }) {
    return Answer(
      icon: icon ?? this.icon,
      username: username ?? this.username,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  @override
  List<Object?> get props => [icon, username, text, isCorrect];
}
