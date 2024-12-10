import 'package:flutter/material.dart';

class DrawlyBarGrid extends StatelessWidget {
  const DrawlyBarGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
  });

  final List<Widget> children;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}
