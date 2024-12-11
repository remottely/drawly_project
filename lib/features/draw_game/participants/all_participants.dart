import 'package:drawly_core/drawly_core.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class AllParticipants extends StatefulWidget {
  const AllParticipants({super.key});

  @override
  State<AllParticipants> createState() => _AllParticipantsState();
}

class _AllParticipantsState extends State<AllParticipants> {
  final _rxAllParticipants = ValueNotifier<List<String>>([]);

  @override
  void initState() {
    super.initState();
    _initializeParticipantListener();
  }

  @override
  void dispose() {
    SocketManager.instance.off('updateParticipants');
    _rxAllParticipants.dispose();
    super.dispose();
  }

  void _initializeParticipantListener() {
    SocketManager.instance.on('updateParticipants', (data) {
      final List<String> allParticipants = List<String>.from(data);
      _rxAllParticipants.value = allParticipants;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DrawlyContainer(
      child: ValueListenableBuilder<List<String>>(
        valueListenable: _rxAllParticipants,
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
