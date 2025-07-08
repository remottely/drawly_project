import 'package:flutter_test/flutter_test.dart';
import 'package:drawly_core/drawly_core.dart';

void main() {
  test('RoomDTO serialization', () {
    final dto = RoomDTO(roomName: 'room');
    expect(dto.toJson(), {'roomName': 'room'});
  });

  test('RoomUserDTO serialization', () {
    final dto = RoomUserDTO(
      roomName: 'room',
      userId: 'u1',
      username: 'name',
      userAvatar: 'a.png',
      isLogged: true,
    );
    expect(dto.toJson(), {
      'roomName': 'room',
      'userId': 'u1',
      'username': 'name',
      'userAvatar': 'a.png',
      'isLogged': true,
    });
  });

  test('RoomUserMessageDTO serialization', () {
    final dto = RoomUserMessageDTO(
      roomName: 'room',
      userId: 'u2',
      username: 'user',
      text: 'hi',
    );
    expect(dto.toJson(), {
      'roomName': 'room',
      'userId': 'u2',
      'username': 'user',
      'text': 'hi',
    });
  });

  test('RoomUserAnswerDTO serialization', () {
    final dto = RoomUserAnswerDTO(
      roomName: 'room',
      userId: 'u3',
      username: 'user3',
      text: 'answer',
    );
    expect(dto.toJson(), {
      'roomName': 'room',
      'userId': 'u3',
      'username': 'user3',
      'text': 'answer',
    });
  });

  test('ErrorDTO copyWith updates fields', () {
    final dto = ErrorDTO(message: 'm', action: ErrorActionType.retry);
    final copy = dto.copyWith(
      message: 'n',
      action: ErrorActionType.ignore,
    );
    expect(copy.message, 'n');
    expect(copy.action, ErrorActionType.ignore);
  });

  test('ErrorDTO invalid action throws', () {
    expect(
      () => ErrorDTO.fromJson({'message': 'err', 'action': 'nope'}),
      throwsArgumentError,
    );
  });
}
