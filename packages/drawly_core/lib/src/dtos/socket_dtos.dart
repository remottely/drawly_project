class RoomDTO {
  final String roomName;

  RoomDTO({required this.roomName});

  factory RoomDTO.fromJson(Map<String, dynamic> json) {
    return RoomDTO(roomName: json['roomName']);
  }

  Map<String, dynamic> toJson() {
    return {'roomName': roomName};
  }
}

class RoomUserDTO extends RoomDTO {
  final String username;

  RoomUserDTO({
    required super.roomName,
    required this.username,
  });

  factory RoomUserDTO.fromJson(Map<String, dynamic> json) {
    return RoomUserDTO(
      roomName: json['roomName'],
      username: json['username'],
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()..['username'] = username;
}

class RoomUserMessageDTO extends RoomUserDTO {
  final String text;

  RoomUserMessageDTO({
    required super.roomName,
    required super.username,
    required this.text,
  });

  factory RoomUserMessageDTO.fromJson(Map<String, dynamic> json) {
    return RoomUserMessageDTO(
      roomName: json['roomName'],
      username: json['username'],
      text: json['text'],
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()..['text'] = text;
}

class RoomUserAnswerDTO extends RoomUserDTO {
  final String text;

  RoomUserAnswerDTO({
    required super.roomName,
    required super.username,
    required this.text,
  });

  factory RoomUserAnswerDTO.fromJson(Map<String, dynamic> json) {
    return RoomUserAnswerDTO(
      roomName: json['roomName'],
      username: json['username'],
      text: json['text'],
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()..['text'] = text;
}
