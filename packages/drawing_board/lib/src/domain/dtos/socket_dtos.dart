import 'dart:ui';

import 'package:drawing_board/drawing_board.dart';
import 'package:drawly_core/drawly_core.dart';

// class RoomDrawingStrokesDTO extends RoomDTO {
//   RoomDrawingStrokesDTO({
//     required super.roomName,
//     required this.strokes,
//   });

//   final List<Stroke> strokes;

//   // factory RoomDrawingDTO.fromJson(Map<String, dynamic> json) {
//   //   return RoomDrawingDTO(
//   //     roomName: json['roomName'],
//   //     strokes: (json['strokes'] as List<dynamic>)
//   //         .map((strokeJson) => Stroke.fromJson(strokeJson))
//   //         .toList(),
//   //   );
//   // }

//   @override
//   Map<String, dynamic> toJson() => super.toJson()
//     ..['strokes'] = strokes.map((stroke) => stroke.toJson()).toList();
// }

class RoomDrawingStartStrokeDTO extends RoomDTO {
  RoomDrawingStartStrokeDTO({
    required super.roomName,
    required this.stroke,
  });

  final Stroke stroke;

  @override
  Map<String, dynamic> toJson() => super.toJson()..['stroke'] = stroke.toJson();
}

class RoomDrawingStrokePointsDTO extends RoomDTO {
  RoomDrawingStrokePointsDTO({
    required super.roomName,
    required this.strokeLastPoints,
  });

  final List<Offset> strokeLastPoints;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..['strokeLastPoints'] =
        strokeLastPoints.map((point) => [point.dx, point.dy]).toList();
}
