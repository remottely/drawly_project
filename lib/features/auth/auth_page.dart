import 'package:drawly/core/widgets/session_pick_avatar.dart';
import 'package:drawly/features/draw_game/draw_game_room_selection_page.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
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
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 16),
              const SessionPickAvatar(),
              const SizedBox(height: 16),
              Container(
                width: 300,
                decoration: BoxDecoration(
                  // color: Colors.red,
                  border: Border.all(
                    color: AppColors.greyAccent,
                    width: 4,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Apelido', // Nick
                    hintText: 'Insira um apelido', // Enter your nickname
                  ),
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
                child: const Text('Salas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
