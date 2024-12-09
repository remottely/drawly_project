// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class DrawlyContainer extends StatelessWidget {
  const DrawlyContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final margin = MediaQuery.of(context).size.width * 0.003;
    return Container(
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(
          color: Colors.grey, // Cor da borda
          width: 2, // Largura da borda
        ),
        borderRadius: BorderRadius.circular(8), // Bordas arredondadas
      ),
      child: child,
    );
  }
}
