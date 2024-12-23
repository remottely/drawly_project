import 'package:flutter/material.dart';

class DrawlyResponsiveFading extends StatelessWidget {
  const DrawlyResponsiveFading({
    super.key,
    this.leftFading = false,
    required this.child,
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
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0),
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
                      Colors.white.withOpacity(0),
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
