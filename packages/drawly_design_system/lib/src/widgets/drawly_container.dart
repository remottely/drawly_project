// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class DrawlyContainer extends StatelessWidget {
  final Color? color;
  final Color? borderColor;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final Widget? child;

  const DrawlyContainer({
    super.key,
    this.color,
    this.borderColor,
    this.width,
    this.height,
    this.padding,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final margin = MediaQuery.of(context).size.width * 0.003;
    return Container(
      margin: EdgeInsets.all(margin),
      padding: padding ?? EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        border: Border.all(
          color: borderColor ?? Colors.grey,
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

class DrawlyTitleContainer extends StatelessWidget {
  const DrawlyTitleContainer({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return DrawlyContainer(
      borderColor: AppColors.darkBlueAccent,
      color: AppColors.blueAccent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
