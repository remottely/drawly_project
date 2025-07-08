// Unit tests for Flutter data models.
import 'package:drawly/features/draw_game/models/answer.dart';
import 'package:drawly/features/draw_game/models/message.dart';
import 'package:drawly/features/draw_game/models/participants.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Message model', () {
    test('fromJson parses icon correctly', () {
      final json = {
        'icon': 'info',
        'userId': '1',
        'username': 'test',
        'text': 'hello',
      };
      final message = Message.fromJson(json);
      expect(message.icon, MessageIconType.info);
      expect(message.userId, '1');
    });

    test('fromJson with unknown icon results in null icon', () {
      final json = {
        'icon': 'unknown',
        'userId': '1',
        'username': 'test',
        'text': 'hello',
      };
      final message = Message.fromJson(json);
      expect(message.icon, isNull);
    });

    test('getIcon and getColor return expected values', () {
      final msgInfo = Message(
        icon: MessageIconType.info,
        userId: '1',
        username: 'test',
        text: 'hello',
      );
      expect(msgInfo.getIcon(), Icons.info);
      expect(msgInfo.getColor(), Colors.blue);

      final msgCheck = msgInfo.copyWith(icon: MessageIconType.check);
      expect(msgCheck.getIcon(), Icons.check);
      expect(msgCheck.getColor(), Colors.green);

      final msgOther = msgInfo.copyWith(icon: null);
      expect(msgOther.getIcon(), isNull);
      expect(msgOther.getColor(), AppColors.greyAccent);
    });

    test('copyWith overrides fields', () {
      final message = Message(
        icon: MessageIconType.info,
        userId: '1',
        username: 'name',
        text: 'text',
      );
      final copy = message.copyWith(text: 'other');
      expect(copy.text, 'other');
      expect(copy.userId, '1');
    });
  });

  test('Answer.fromJson parses fields', () {
    final json = {
      'icon': 'check',
      'userId': 'u1',
      'username': 'user',
      'text': 'ok',
      'isCorrect': true,
    };
    final answer = Answer.fromJson(json);
    expect(answer.isCorrect, isTrue);
    expect(answer.icon, MessageIconType.check);
  });

  test('Participant.fromJson parses fields', () {
    final json = {
      'userId': 'u1',
      'username': 'user',
      'userAvatar': null,
      'isLogged': true,
      'isConnected': false,
      'score': 10,
    };
    final participant = Participant.fromJson(json);
    expect(participant.userId, 'u1');
    expect(participant.score, 10);
    expect(participant.isConnected, isFalse);
  });

  group('ErrorDTO', () {
    test('fromJson and toJson work', () {
      final json = {
        'message': 'error',
        'action': 'retry',
      };
      final dto = ErrorDTO.fromJson(json);
      expect(dto.message, 'error');
      expect(dto.action, ErrorActionType.retry);
      expect(dto.toJson(), json);
    });

    test('copyWith preserves unchanged fields', () {
      final dto = ErrorDTO(message: 'm', action: ErrorActionType.ignore);
      final copy = dto.copyWith(message: 'n');
      expect(copy.message, 'n');
      expect(copy.action, ErrorActionType.ignore);
    });
  });
}
