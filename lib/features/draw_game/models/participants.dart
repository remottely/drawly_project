class Participant {
  Participant({
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.isLogged,
    required this.isConnected,
    required this.score,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['userId'] as String,
      username: json['username'] as String,
      userAvatar: json['userAvatar'] as String?,
      isLogged: json['isLogged'] as bool,
      isConnected: json['isConnected'] as bool,
      score: json['score'] as int,
    );
  }

  final String userId;
  final String username;
  final String? userAvatar;
  final bool isLogged;
  final bool isConnected;
  final int score;

  // Map<String, dynamic> toJson() {
  //   return {
  //     'userId': userId,
  //     'username': username,
  //     'userAvatar': userAvatar,
  //     'isLogged': isLogged,
  //     'isConnected': isConnected,
  //     'score': score,
  //   };
  // }
}
