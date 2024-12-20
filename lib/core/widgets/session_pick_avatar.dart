import 'package:drawly/core/widgets/avatar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionPickAvatar extends StatefulWidget {
  const SessionPickAvatar({super.key});

  @override
  State<SessionPickAvatar> createState() => _SessionPickAvatarState();
}

class _SessionPickAvatarState extends State<SessionPickAvatar> {
  String? selectedAvatar;

  @override
  void initState() {
    super.initState();
    _loadSelectedAvatar();
  }

  // Carregar o avatar salvo no armazenamento local
  Future<void> _loadSelectedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedAvatar = prefs.getString('user_avatar_path');
    });
  }

  // Salvar o avatar selecionado no armazenamento local
  Future<void> _saveSelectedAvatar(String avatarPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_avatar_path', avatarPath);
  }

  Future<void> showAvatarSelectionDialog(BuildContext context) async {
    final newAvatar = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Escolha um Avatar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(20, (index) {
                    final avatarPath = 'assets/avatars/${index + 1}.webp';
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(avatarPath);
                      },
                      child: CircleAvatar(
                        backgroundImage: AssetImage(avatarPath),
                        radius: 32,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (newAvatar != null) {
      setState(() {
        selectedAvatar = newAvatar;
      });
      await _saveSelectedAvatar(newAvatar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Avatar(
                backgroundImage:
                    selectedAvatar != null ? AssetImage(selectedAvatar!) : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => showAvatarSelectionDialog(context),
                child: const Text('Trocar Avatar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
