class RoomDTO {
  final String roomName;

  RoomDTO({required this.roomName});

  factory RoomDTO.fromJson(Map<String, dynamic> json) {
    return RoomDTO(
      roomName: json['roomName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'roomName': roomName};
  }
}

class RoomUserDTO extends RoomDTO {
  final String username;
  final String? userAvatar;
  final bool isLogged;

  RoomUserDTO({
    required super.roomName,
    required this.username,
    required this.userAvatar,
    required this.isLogged,
  });

  factory RoomUserDTO.fromJson(Map<String, dynamic> json) {
    return RoomUserDTO(
      roomName: json['roomName'] as String,
      username: json['username'] as String,
      userAvatar: json['userAvatar'] as String?,
      isLogged: json['isLogged'] as bool,
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..['username'] = username
    ..['userAvatar'] = userAvatar
    ..['isLogged'] = isLogged;
}

class RoomUserMessageDTO extends RoomDTO {
  final String username;
  final String text;

  RoomUserMessageDTO({
    required super.roomName,
    required this.username,
    required this.text,
  });

  factory RoomUserMessageDTO.fromJson(Map<String, dynamic> json) {
    return RoomUserMessageDTO(
      roomName: json['roomName'] as String,
      username: json['username'] as String,
      text: json['text'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()..['text'] = text;
}

class RoomUserAnswerDTO extends RoomDTO {
  final String username;
  final String text;

  RoomUserAnswerDTO({
    required super.roomName,
    required this.username,
    required this.text,
  });

  factory RoomUserAnswerDTO.fromJson(Map<String, dynamic> json) {
    return RoomUserAnswerDTO(
      roomName: json['roomName'] as String,
      username: json['username'] as String,
      text: json['text'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()..['text'] = text;
}
