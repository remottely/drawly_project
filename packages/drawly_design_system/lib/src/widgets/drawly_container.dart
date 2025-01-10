import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class DrawlyContainer extends StatelessWidget {
  const DrawlyContainer({
    super.key,
    this.color,
    this.borderColor,
    this.width,
    this.height,
    this.padding,
    this.child,
  });

  final Color? color;
  final Color? borderColor;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final margin = MediaQuery.of(context).size.width * 0.003;
    return Container(
      margin: EdgeInsets.all(margin),
      padding: padding ?? EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        border: Border.all(
          color: borderColor ?? AppColors.greyAccent,
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
    required this.text,
    this.textColor = Colors.white,
    this.color = AppColors.blueAccent,
    super.key,
  });

  final String text;
  final Color textColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DrawlyContainer(
      borderColor: AppColors.transparent,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
