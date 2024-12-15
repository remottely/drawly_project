import 'package:flutter/material.dart';

class DrawlyIconBorderedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final TextInputType keyboardType;
  final IconData leftIcon;
  final IconData rightIcon;
  final VoidCallback onRightIconPressed;
  final bool isBlocked;

  const DrawlyIconBorderedTextField({
    super.key,
    this.controller,
    this.hintText,
    this.keyboardType = TextInputType.text,
    required this.leftIcon,
    required this.rightIcon,
    required this.onRightIconPressed,
    required this.isBlocked,
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
      setState(() {});
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
      enabled: !widget.isBlocked,
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
        prefixIcon: Icon(
          widget.leftIcon,
          color: widget.isBlocked ? Colors.grey[300] : Colors.grey,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            widget.rightIcon,
            color: widget.isBlocked
                ? Colors.grey[300]
                : _focusNode.hasFocus
                    ? Colors.blue
                    : Colors.grey,
          ),
          onPressed: widget.onRightIconPressed,
        ),
      ),
    );
  }
}
