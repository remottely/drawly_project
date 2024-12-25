import 'package:drawly/features/draw_game/models/message.dart';

class Answer extends Message {
  const Answer({
    required super.icon,
    required super.userId,
    required super.text,
    required this.isCorrect,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    final message = Message.fromJson(json);

    return Answer(
      icon: message.icon,
      userId: message.userId,
      text: message.text,
      isCorrect: json['isCorrect'] as bool,
    );
  }

  final bool isCorrect;

  // @override
  // Map<String, dynamic> toJson() => super.toJson()..['isCorrect'] = isCorrect;

  @override
  Answer copyWith({
    MessageIconType? icon,
    String? userId,
    String? text,
    bool? isCorrect,
  }) {
    return Answer(
      icon: icon ?? this.icon,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  @override
  List<Object?> get props => [icon, userId, text, isCorrect];
}
