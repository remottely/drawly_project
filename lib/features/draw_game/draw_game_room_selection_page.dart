import 'package:drawly/features/draw_game/draw_game_room_page.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:flutter/material.dart';

class DrawGameRoomSelectionPage extends StatefulWidget {
  const DrawGameRoomSelectionPage({required this.username, super.key});

  final String username;

  @override
  State<DrawGameRoomSelectionPage> createState() => _DrawGameRoomSelectionPageState();
}

class _DrawGameRoomSelectionPageState extends State<DrawGameRoomSelectionPage> {
  final roomController = TextEditingController();
  final List<String> allRooms = [];

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  @override
  void dispose() {
    roomController.dispose();
    SocketManager.instance.offEvent('room:all', _onAllRoomsEvent);
    super.dispose();
  }

  void _onAllRoomsEvent(dynamic data) {
    if (data is List<dynamic>) {
      setState(() {
        allRooms
          ..clear()
          ..addAll(data.whereType<String>());
      });
    } else {
      debugPrint('Unexpected data type: ${data.runtimeType}');
    }
  }

  void _initializeSocket() {
    SocketManager.instance.connect();
    SocketManager.instance.onEvent('room:all', _onAllRoomsEvent);
  }

  void _createRoom() {
    final roomName = roomController.text.trim();
    if (roomName.isNotEmpty && roomName.length >= 3) {
      final payload = RoomDTO(
        roomName: roomName,
      ).toJson();

      SocketManager.instance.emit('room:create', payload);
      roomController.clear();
    }
  }

  void _joinRoom(String roomName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawGameRoomPage(username: widget.username, roomName: roomName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select or Create a Room'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: roomController,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                hintText: 'Enter a room name...',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createRoom,
              child: const Text('Create Room'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Available Rooms:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: allRooms.isEmpty
                  ? const Center(child: Text('No rooms available'))
                  : ListView.builder(
                      itemCount: allRooms.length,
                      itemBuilder: (context, index) {
                        final roomName = allRooms[index];
                        return ListTile(
                          title: Text(roomName),
                          trailing: ElevatedButton(
                            onPressed: () => _joinRoom(roomName),
                            child: const Text('Join'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
