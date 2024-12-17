class MessageModel {
  final String username;
  final String message;

  MessageModel({
    required this.username,
    required this.message,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      username: json['username'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'message': message,
    };
  }
}
