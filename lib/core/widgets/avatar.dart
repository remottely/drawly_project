import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    this.size = 64,
    this.backgroundImage,
    super.key,
  });

  final double size;
  final ImageProvider<Object>? backgroundImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.darkBlueAccent,
          width: 4,
        ),
      ),
      child: CircleAvatar(
        backgroundImage:
            backgroundImage ?? const AssetImage('assets/avatars/1.webp'),
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
