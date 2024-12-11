import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter/widgets.dart';
// import 'package:flutter_inset_box_shadow/flutter_inset_box_shadow.dart';

class IconLeftInput extends StatelessWidget {
  const IconLeftInput({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryContainer(
      radius: 10,
      child: TextFormField(
        // style: const TextStyle(fontSize: 16, color: Colors.white),
        controller: TextEditingController(),
        textAlignVertical: TextAlignVertical.center,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.only(left: 20, right: 20, bottom: 3),
          border: InputBorder.none,
          // focusedBorder: OutlineInputBorder(
          //     borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00BAAB))),
          errorBorder: InputBorder.none,
          filled: false,
          disabledBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          hintText: 'Search',
          prefixIcon: Icon(Icons.search),
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ),
    );
  }
}

class PrimaryContainer extends StatelessWidget {
  final Widget child;
  final double? radius;
  final Color? color;
  const PrimaryContainer({
    super.key,
    this.radius,
    this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius ?? 30),
        boxShadow: [
          BoxShadow(
            color: color ?? const Color(0XFF1E1E1E),
          ),
          const BoxShadow(
            offset: Offset(2, 2),
            blurRadius: 4,
            spreadRadius: 0,
            color: Colors.white,
            // inset: true,
          ),
        ],
      ),
      child: child,
    );
  }
}
