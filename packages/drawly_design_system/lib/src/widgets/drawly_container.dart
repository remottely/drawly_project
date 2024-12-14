// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class DrawlyContainer extends StatelessWidget {
  const DrawlyContainer({
    super.key,
    this.child,
    this.color,
    this.width,
    this.height,
  });

  final Widget? child;
  final Color? color;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final margin = MediaQuery.of(context).size.width * 0.003;
    return Container(
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        border: Border.all(
          color: Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      width: width,
      height: height,
      child: child,
    );
  }
}
