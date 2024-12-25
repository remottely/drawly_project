import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class DrawlyChatTextField extends StatefulWidget {
  const DrawlyChatTextField({
    required this.leftIcon,
    required this.rightIcon,
    required this.onRightIconPressed,
    required this.disabled,
    super.key,
    this.controller,
    this.hintText,
    this.hintColor,
    this.keyboardType = TextInputType.text,
  });
  final TextEditingController? controller;
  final String? hintText;
  final Color? hintColor;
  final TextInputType keyboardType;
  final IconData leftIcon;
  final IconData rightIcon;
  final void Function() onRightIconPressed;
  final bool disabled;

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
              //     ? AppColors.lightGrey300
              //     :
              widget.hintColor ?? AppColors.greyAccent,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.greyAccent,
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
            color: AppColors.greyAccent,
            width: 1.5,
          ),
        ),
        prefixIcon: Icon(
          widget.leftIcon,
          color:
              widget.disabled ? AppColors.lightGrey300 : AppColors.greyAccent,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            widget.rightIcon,
            color: widget.disabled
                ? AppColors.lightGrey300
                : _focusNode.hasFocus
                    ? Colors.blue
                    : AppColors.greyAccent,
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
