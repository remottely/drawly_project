import 'package:flutter/material.dart';

class DrawlyBarGrid extends StatelessWidget {
  const DrawlyBarGrid({
    required this.children,
    super.key,
    this.crossAxisCount = 2,
  });

  final List<Widget> children;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}
