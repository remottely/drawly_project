class Participant {
  Participant({
    required this.username,
    required this.userAvatar,
    required this.isLogged,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      username: json['username'] as String,
      userAvatar: json['userAvatar'] as String?,
      isLogged: json['isLogged'] as bool,
    );
  }

  final String username;
  final String? userAvatar;
  final bool isLogged;

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'userAvatar': userAvatar,
      'isLogged': isLogged,
    };
  }
}
