import 'package:flutter/material.dart';

class DrawlyChatTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final Color? hintColor;
  final TextInputType keyboardType;
  final IconData leftIcon;
  final IconData rightIcon;
  final void Function() onRightIconPressed;
  final bool disabled;

  const DrawlyChatTextField({
    super.key,
    this.controller,
    this.hintText,
    this.hintColor,
    this.keyboardType = TextInputType.text,
    required this.leftIcon,
    required this.rightIcon,
    required this.onRightIconPressed,
    required this.disabled,
  });

  @override
  State<DrawlyChatTextField> createState() => _DrawlyChatTextFieldState();
}

class _DrawlyChatTextFieldState extends State<DrawlyChatTextField> {
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
      enabled: !widget.disabled,
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
            color:
                // widget.disabled
                //     ? Colors.grey[300]
                //     :
                widget.hintColor ?? Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
          color: widget.disabled ? Colors.grey[300] : Colors.grey,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            widget.rightIcon,
            color: widget.disabled
                ? Colors.grey[300]
                : _focusNode.hasFocus
                    ? Colors.blue
                    : Colors.grey,
          ),
          onPressed: widget.onRightIconPressed,
        ),
      ),
      onSubmitted: (_) {
        if (!widget.disabled) {
          widget.onRightIconPressed();
          _focusNode.requestFocus();
        }
      },
    );
  }
}
