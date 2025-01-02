import 'package:drawly/core/widgets/avatar.dart';
import 'package:drawly/features/draw_game/models/participants.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class AllParticipants extends StatefulWidget {
  const AllParticipants({super.key});

  @override
  State<AllParticipants> createState() => _AllParticipantsState();
}

class _AllParticipantsState extends State<AllParticipants> {
  final rxAllParticipants = ValueNotifier<List<Participant>>([]);

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
        try {
          final allParticipants = participants
              .map(
                (participant) =>
                    Participant.fromJson(participant as Map<String, dynamic>),
              )
              .toList();

          rxAllParticipants.value = allParticipants;
        } catch (e) {
          debugPrint('Error parsing participants: $e');
          debugPrint('Participants data: $participants');
        }
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
      child: DrawlyResponsiveFading(
        child: ValueListenableBuilder<List<Participant>>(
          valueListenable: rxAllParticipants,
          builder: (_, value, __) {
            return ListView.builder(
              itemCount: value.length,
              itemBuilder: (context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          _UserPicture(
                            userAvatar: value[index].userAvatar,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  value[index].username,
                                  style: const TextStyle(
                                    color: AppColors.greyAccent700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    height: 1,
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
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
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                                const SizedBox(height: 4),
                                const _Host(),
                                const SizedBox(height: 6),
                              ],
                            ),
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
      ),
    );
  }
}

class _UserPicture extends StatelessWidget {
  const _UserPicture({
    required this.userAvatar,
  });

  final String? userAvatar;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Avatar(
          backgroundImage: userAvatar != null ? AssetImage(userAvatar!) : null,
        ),
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
