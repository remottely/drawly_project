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

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  @override
  void dispose() {
    SocketManager.instance.offEvent('room:participants:update', (data) => _onUpdateRoomParticipantsEvent(data));
    rxAllParticipants.dispose();
    super.dispose();
  }

  void _onUpdateRoomParticipantsEvent(dynamic data) {
    final List<String> allParticipants = List<String>.from(data);
    rxAllParticipants.value = allParticipants;
  }

  void _initializeSocket() {
    SocketManager.instance.onEvent('room:participants:update', (data) => _onUpdateRoomParticipantsEvent(data));
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
                direction: Axis.horizontal,
                spacing: 8.0,
                runSpacing: 8.0,
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
