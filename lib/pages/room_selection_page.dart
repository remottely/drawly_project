import 'dart:developer' as developer;

import 'package:drawly/pages/game_page.dart';
import 'package:drawly_core/drawly_core.dart';
import 'package:flutter/material.dart';

class RoomSelectionPage extends StatefulWidget {
  const RoomSelectionPage({super.key, required this.username});

  final String username;

  @override
  State<RoomSelectionPage> createState() => _RoomSelectionPageState();
}

class _RoomSelectionPageState extends State<RoomSelectionPage> {
  final TextEditingController roomController = TextEditingController();
  final List<String> rooms = [];

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  /// Initializes the socket connection and sets up listeners
  void _initializeSocket() {
    SocketManager.instance.connect();

    SocketManager.instance.onConnect((_) {
      developer.log('Connected to the server');
    });

    // Listen for room list updates
    SocketManager.instance.on("roomList", (data) {
      setState(() {
        rooms
          ..clear()
          ..addAll(List<String>.from(data));
      });
    });

    SocketManager.instance.onDisconnect((_) {
      developer.log('Disconnected from the server');
    });
  }

  /// Sends a request to create a new room
  void _createRoom() {
    final roomName = roomController.text.trim();
    if (roomName.isNotEmpty && roomName.length >= 3) {
      SocketManager.instance.emit("createRoom", roomName);
      roomController.clear();
    }
  }

  /// Joins the selected room
  void _joinRoom(String roomName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GamePage(username: widget.username, room: roomName),
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
            // Input field to create a room
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
            // List of rooms
            Expanded(
              child: rooms.isEmpty
                  ? const Center(child: Text('No rooms available'))
                  : ListView.builder(
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final roomName = rooms[index];
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
