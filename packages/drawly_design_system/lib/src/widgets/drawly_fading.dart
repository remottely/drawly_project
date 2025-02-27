import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class DrawlyResponsiveFading extends StatelessWidget {
  const DrawlyResponsiveFading({
    required this.child,
    super.key,
    this.leftFading = false,
  });

  final bool leftFading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            child,
            if (leftFading)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.white.applyOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.white,
                      Colors.white.applyOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
