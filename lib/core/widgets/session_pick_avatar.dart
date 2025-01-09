import 'package:drawly/core/widgets/avatar.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionPickAvatar extends StatefulWidget {
  const SessionPickAvatar({super.key});

  @override
  State<SessionPickAvatar> createState() => _SessionPickAvatarState();
}

class _SessionPickAvatarState extends State<SessionPickAvatar> {
  String? selectedUserAvatar;

  @override
  void initState() {
    super.initState();
    _loadSelectedAvatar();
  }

  Future<void> _loadSelectedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedUserAvatar = prefs.getString('user_avatar_path');
    });
  }

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
                      onTap: () => Navigator.of(context).pop(avatarPath),
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
        selectedUserAvatar = newAvatar;
      });
      await _saveSelectedAvatar(newAvatar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Avatar(
            color: AppColors.darkBlueAccent,
            size: 128,
            backgroundImage: selectedUserAvatar != null
                ? AssetImage(selectedUserAvatar!)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Positioned(
          top: 0,
          right: 0,
          child: FloatingActionButton(
            onPressed: () => showAvatarSelectionDialog(context),
            backgroundColor: Colors.blue,
            shape: const CircleBorder(
              side: BorderSide(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
