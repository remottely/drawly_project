import 'package:equatable/equatable.dart';

/// A model representing an answer in the draw game.
class Answer extends Equatable {
  /// The username of the person who provided the answer.
  final String username;

  /// The answer provided by the user.
  final String answer;

  /// Whether the answer is correct or not.
  final bool isCorrect;

  /// Creates an instance of [Answer].
  Answer({
    required this.username,
    required this.answer,
    required this.isCorrect,
  });

  /// Creates an instance of [Answer] from a JSON object.
  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      username: json['username'] as String,
      answer: json['answer'] as String,
      isCorrect: json['isCorrect'] as bool,
    );
  }

  /// Converts the [Answer] instance to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'answer': answer,
      'isCorrect': isCorrect,
    };
  }

  /// Creates a copy of the current [Answer] with new values.
  Answer copyWith({
    String? username,
    String? answer,
    bool? isCorrect,
  }) {
    return Answer(
      username: username ?? this.username,
      answer: answer ?? this.answer,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  @override
  List<Object?> get props => [username, answer, isCorrect];
}
