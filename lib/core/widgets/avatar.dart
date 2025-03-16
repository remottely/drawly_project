import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    required this.color,
    this.size = 64,
    this.backgroundImage,
    super.key,
  });

  final double size;
  final Color color;
  final ImageProvider<Object>? backgroundImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 4),
      ),
      child: CircleAvatar(
        backgroundImage:
            backgroundImage ?? const AssetImage('assets/avatars/1.webp'),
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
