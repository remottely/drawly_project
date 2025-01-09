import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

class AnimatedFlipper extends StatefulWidget {
  const AnimatedFlipper({super.key});

  @override
  State<AnimatedFlipper> createState() => _AnimatedFlipperState();
}

class _AnimatedFlipperState extends State<AnimatedFlipper> {
  late Stream<int> _valueStream;

  @override
  void initState() {
    super.initState();
    _valueStream =
        Stream.periodic(const Duration(seconds: 2), (count) => count);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _valueStream,
      initialData: 0,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0;
        return AnimatedFlipCounter(
          value: value,
          fractionDigits: 2,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          textStyle: TextStyle(
            fontSize: 40,
            color: value >= 0 ? Colors.green : Colors.red,
          ),
        );
      },
    );
  }
}
