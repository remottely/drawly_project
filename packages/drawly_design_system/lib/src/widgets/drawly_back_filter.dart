import 'dart:ui';

import 'package:flutter/material.dart';

class DrawlyBackFilter extends StatelessWidget {
  const DrawlyBackFilter({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).shadowColor.withOpacity(0.32),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),
        child: Center(
          child: child,
        ),
      ),
    );
  }
}
