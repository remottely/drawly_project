import 'dart:io';

import 'package:drawly/core/widgets/avatar.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePickAvatar extends StatefulWidget {
  const ProfilePickAvatar({super.key});

  @override
  State<ProfilePickAvatar> createState() => _ProfilePickAvatarState();
}

class _ProfilePickAvatarState extends State<ProfilePickAvatar> {
  String? imagePath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadImagePath();
  }

  Future<void> saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_avatar_path', path);
    setState(() {
      imagePath = path;
    });
  }

  Future<void> loadImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      imagePath = prefs.getString('user_avatar_path');
    });
  }

  Future<void> pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final path = image.path;
      await saveImagePath(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        children: [
          _ProfileAvatar(imagePath: imagePath),
          FloatingActionButton(
            onPressed: pickImage,
            child: const Icon(Icons.image),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imagePath,
  });

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Avatar(
      color: AppColors.darkBlueAccent,
      backgroundImage: imagePath == null
          ? const AssetImage('assets/avatars/default.webp')
          : kIsWeb
              ? NetworkImage(imagePath!)
              : FileImage(
                  File(imagePath!),
                ),
    );
  }
}
