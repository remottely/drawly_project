import 'package:drawly/features/draw_game/draw_game_room_selection_page.dart';
import 'package:flutter/material.dart';

/// Login screen where the user enters their username
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final usernameController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login - Pictionary App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Apelido', // Nick
                hintText: 'Insira um apelido', // Enter your nickname
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final username = usernameController.text.trim();
                if (username.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DrawGameRoomSelectionPage(username: username),
                    ),
                  );
                }
              },
              child: const Text('Entrar'), // Join
            ),
          ],
        ),
      ),
    );
  }
}
