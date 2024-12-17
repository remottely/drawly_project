import 'package:equatable/equatable.dart';

/// A model representing an answer in the draw game.
class DrawGameAnswer extends Equatable {
  /// The username of the person who provided the answer.
  final String username;

  /// The answer provided by the user.
  final String answer;

  /// Whether the answer is correct or not.
  final bool isCorrect;

  /// Creates an instance of [DrawGameAnswer].
  DrawGameAnswer({
    required this.username,
    required this.answer,
    required this.isCorrect,
  });

  /// Creates an instance of [DrawGameAnswer] from a JSON object.
  factory DrawGameAnswer.fromJson(Map<String, dynamic> json) {
    return DrawGameAnswer(
      username: json['username'] as String,
      answer: json['answer'] as String,
      isCorrect: json['isCorrect'] as bool,
    );
  }

  /// Converts the [DrawGameAnswer] instance to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'answer': answer,
      'isCorrect': isCorrect,
    };
  }

  /// Creates a copy of the current [DrawGameAnswer] with new values.
  DrawGameAnswer copyWith({
    String? username,
    String? answer,
    bool? isCorrect,
  }) {
    return DrawGameAnswer(
      username: username ?? this.username,
      answer: answer ?? this.answer,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  @override
  List<Object?> get props => [username, answer, isCorrect];
}
