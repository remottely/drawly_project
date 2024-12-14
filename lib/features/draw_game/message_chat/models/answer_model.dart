class MessageModel {
  final String username;
  final String answer;

  MessageModel({
    required this.username,
    required this.answer,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      username: json['username'] as String,
      answer: json['answer'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'answer': answer,
    };
  }
}
