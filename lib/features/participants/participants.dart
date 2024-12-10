import 'package:drawly_core/drawly_core.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class Participants extends StatefulWidget {
  const Participants({super.key});

  @override
  State<Participants> createState() => _ParticipantsState();
}

class _ParticipantsState extends State<Participants> {
  final ValueNotifier<List<String>> _participants = ValueNotifier<List<String>>([]);

  @override
  void initState() {
    super.initState();
    _initializeParticipantListener();
  }

  @override
  void dispose() {
    SocketManager.instance.off('updateParticipants');
    _participants.dispose();
    super.dispose();
  }

  void _initializeParticipantListener() {
    SocketManager.instance.on('updateParticipants', (data) {
      final List<String> participants = List<String>.from(data);
      _participants.value = participants;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DrawlyContainer(
      child: ValueListenableBuilder<List<String>>(
        valueListenable: _participants,
        builder: (context, value, _) {
          return ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(value[index]),
              );
            },
          );
        },
      ),
    );
  }
}
