import 'package:drawly_core/drawly_core.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class AllParticipants extends StatefulWidget {
  const AllParticipants({super.key});

  @override
  State<AllParticipants> createState() => _AllParticipantsState();
}

class _AllParticipantsState extends State<AllParticipants> {
  final rxAllParticipants = ValueNotifier<List<String>>([]);

  late final void Function(dynamic) _onUpdateRoomParticipantsEvent;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  @override
  void dispose() {
    SocketManager.instance
        .offEvent('room:participants:update', _onUpdateRoomParticipantsEvent);
    rxAllParticipants.dispose();
    super.dispose();
  }

  void _initializeSocket() {
    _onUpdateRoomParticipantsEvent = (data) {
      final participants = (data as Map<String, dynamic>)['participants'];
      if (participants is List<dynamic>) {
        final allParticipants = participants.whereType<String>().toList();
        rxAllParticipants.value = allParticipants;
      } else {
        debugPrint(
          'Unexpected data type for participants: ${participants.runtimeType}',
        );
      }
    };
    SocketManager.instance
        .onEvent('room:participants:update', _onUpdateRoomParticipantsEvent);
  }

  @override
  Widget build(BuildContext context) {
    return DrawlyContainer(
      child: ValueListenableBuilder<List<String>>(
        valueListenable: rxAllParticipants,
        builder: (context, value, _) {
          return ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, index) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Icon(Icons.person),
                  Text(value[index]),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
