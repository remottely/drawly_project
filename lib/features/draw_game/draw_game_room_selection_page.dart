import 'dart:developer' as developer;

import 'package:drawly/features/draw_game/draw_game_room_page.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:flutter/material.dart';

class DrawGameRoomSelectionPage extends StatefulWidget {
  const DrawGameRoomSelectionPage({super.key, required this.username});

  final String username;

  @override
  State<DrawGameRoomSelectionPage> createState() => _DrawGameRoomSelectionPageState();
}

class _DrawGameRoomSelectionPageState extends State<DrawGameRoomSelectionPage> {
  final TextEditingController roomController = TextEditingController();
  final List<String> allRooms = [];

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  void _initializeSocket() {
    SocketManager.instance.connect();

    SocketManager.instance.onConnect((_) {
      developer.log('Connected to the server');
    });

    SocketManager.instance.on('roomList', (data) {
      setState(() {
        allRooms
          ..clear()
          ..addAll(List<String>.from(data));
      });
    });

    SocketManager.instance.onDisconnect((_) {
      developer.log('Disconnected from the server');
    });
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
  void dispose() {
    roomController.dispose();
    SocketManager.instance.off("roomList");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select or Create a Room'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
            const Text('Available Rooms:', style: TextStyle(fontWeight: FontWeight.bold)),
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
