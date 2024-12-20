import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class Avatar extends StatefulWidget {
  const Avatar({
    this.backgroundImage,
    super.key,
  });

  final ImageProvider<Object>? backgroundImage;

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.darkBlueAccent,
          width: 4,
        ),
      ),
      child: CircleAvatar(
        backgroundImage:
            widget.backgroundImage ?? const AssetImage('assets/avatars/1.webp'),
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
