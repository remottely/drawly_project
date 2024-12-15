class AnswerModel {
  final String username;
  final String answer;
  final bool isCorrect;

  AnswerModel({
    required this.username,
    required this.answer,
    required this.isCorrect,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      username: json['username'] as String,
      answer: json['answer'] as String,
      isCorrect: json['isCorrect'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'answer': answer,
      'isCorrect': isCorrect,
    };
  }
}
