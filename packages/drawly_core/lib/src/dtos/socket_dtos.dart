class RoomDTO {
  RoomDTO({required this.roomName});
  final String roomName;

  // factory RoomDTO.fromJson(Map<String, dynamic> json) {
  //   return RoomDTO(
  //     roomName: json['roomName'] as String,
  //   );
  // }

  Map<String, dynamic> toJson() => {}..['roomName'] = roomName;
}

class RoomUserDTO extends RoomDTO {
  RoomUserDTO({
    required super.roomName,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.isLogged,
  });

  final String userId;
  final String username;
  final String? userAvatar;
  final bool isLogged;

  // factory RoomUserDTO.fromJson(Map<String, dynamic> json) {
  //   return RoomUserDTO(
  //     roomName: json['roomName'] as String,
  //     userId: json['userId'] as String,
  //     username: json['username'] as String,
  //     userAvatar: json['userAvatar'] as String?,
  //     isLogged: json['isLogged'] as bool,
  //   );
  // }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..['userId'] = userId
    ..['username'] = username
    ..['userAvatar'] = userAvatar
    ..['isLogged'] = isLogged;
}

class RoomUserMessageDTO extends RoomDTO {
  RoomUserMessageDTO({
    required super.roomName,
    required this.userId,
    required this.username,
    required this.text,
  });

  final String userId;
  final String username;
  final String text;

  // factory RoomUserMessageDTO.fromJson(Map<String, dynamic> json) {
  //   return RoomUserMessageDTO(
  //     roomName: json['roomName'] as String,
  //     userId: json['userId'] as String,
  //     username: json['username'] as String,
  //     text: json['text'] as String,
  //   );
  // }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..['userId'] = userId
    ..['username'] = username
    ..['text'] = text;
}

class RoomUserAnswerDTO extends RoomDTO {
  RoomUserAnswerDTO({
    required super.roomName,
    required this.userId,
    required this.username,
    required this.text,
  });

  final String userId;
  final String username;
  final String text;

  // factory RoomUserAnswerDTO.fromJson(Map<String, dynamic> json) {
  //   return RoomUserAnswerDTO(
  //     roomName: json['roomName'] as String,
  //     userId: json['userId'] as String,
  //     username: json['username'] as String,
  //     text: json['text'] as String,
  //   );
  // }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..['userId'] = userId
    ..['username'] = username
    ..['text'] = text;
}
