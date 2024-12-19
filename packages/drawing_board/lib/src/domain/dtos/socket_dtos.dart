import 'package:drawing_board/drawing_board.dart';
import 'package:drawly_core/drawly_core.dart';

class RoomDrawingDTO extends RoomDTO {
  final List<Stroke> strokes;

  RoomDrawingDTO({
    required super.roomName,
    required this.strokes,
  });

  factory RoomDrawingDTO.fromJson(Map<String, dynamic> json) {
    return RoomDrawingDTO(
      roomName: json['roomName'],
      strokes: (json['strokes'] as List<dynamic>).map((strokeJson) => Stroke.fromJson(strokeJson)).toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()..['strokes'] = strokes.map((stroke) => stroke.toJson()).toList();
}
