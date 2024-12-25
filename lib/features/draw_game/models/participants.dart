class Participant {
  Participant({
    required this.userId,
    required this.userAvatar,
    required this.isLogged,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['userId'] as String,
      userAvatar: json['userAvatar'] as String?,
      isLogged: json['isLogged'] as bool,
    );
  }

  final String userId;
  final String? userAvatar;
  final bool isLogged;

  // Map<String, dynamic> toJson() {
  //   return {
  //     'userId': userId,
  //     'userAvatar': userAvatar,
  //     'isLogged': isLogged,
  //   };
  // }
}
