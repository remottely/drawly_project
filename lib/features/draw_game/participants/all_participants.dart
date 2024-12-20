import 'package:drawly/core/widgets/avatar.dart';
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const _Picture(),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value[index],
                              style: const TextStyle(
                                color: AppColors.greyAccent700,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '0 pts',
                              style: TextStyle(
                                color: AppColors.darkBlueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const _Host(),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: AppColors.lightGrey300,
                    height: 1,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Picture extends StatelessWidget {
  const _Picture();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Avatar(),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.yellowAccent,
              border: Border.all(
                color: AppColors.white,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blueAccent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: AppColors.blueAccent,
              size: 14,
            ),
          ),
          const Text(
            'Host',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
