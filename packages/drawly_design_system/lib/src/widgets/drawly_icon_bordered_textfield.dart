import 'package:flutter/material.dart';

class DrawlyIconBorderedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final TextInputType keyboardType;
  final IconData leftIcon;
  final IconData rightIcon;
  final VoidCallback onRightIconPressed;

  const DrawlyIconBorderedTextField({
    super.key,
    this.controller,
    this.hintText,
    this.keyboardType = TextInputType.text,
    required this.leftIcon,
    required this.rightIcon,
    required this.onRightIconPressed,
  });

  @override
  State<DrawlyIconBorderedTextField> createState() => _DrawlyIconBorderedTextFieldState();
}

class _DrawlyIconBorderedTextFieldState extends State<DrawlyIconBorderedTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {}); // Atualiza a UI quando o foco muda
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 1.5,
          ),
        ),
        prefixIcon: Icon(widget.leftIcon, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            widget.rightIcon,
            color: _focusNode.hasFocus ? Colors.blue : Colors.grey, // Atualiza a cor com base no foco
          ),
          onPressed: widget.onRightIconPressed,
        ),
      ),
    );
  }
}
