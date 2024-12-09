import 'package:drawly_core/drawly_core.dart';
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
    return Container(
      width: 200,
      color: Colors.grey[200],
      child: ValueListenableBuilder<List<String>>(
        valueListenable: _participants,
        builder: (context, participants, _) {
          return ListView.builder(
            itemCount: participants.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(participants[index]),
              );
            },
          );
        },
      ),
    );
  }
}
