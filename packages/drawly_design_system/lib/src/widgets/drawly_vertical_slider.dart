// import 'package:flutter/material.dart';

// class VerticalSlider extends StatefulWidget {
//   final double value;
//   final double min;
//   final double max;
//   final ValueChanged<double> onChanged;

//   const VerticalSlider({
//     super.key,
//     required this.value,
//     required this.min,
//     required this.max,
//     required this.onChanged,
//   });

//   @override
//   _VerticalSliderState createState() => _VerticalSliderState();
// }

// class _VerticalSliderState extends State<VerticalSlider> {
//   late double _value;

//   @override
//   void initState() {
//     super.initState();
//     _value = widget.value;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onVerticalDragUpdate: (details) {
//         double newValue = _value - details.delta.dy / 2; // Ajusta a sensibilidade
//         if (newValue < widget.min) newValue = widget.min;
//         if (newValue > widget.max) newValue = widget.max;

//         setState(() {
//           _value = newValue;
//         });
//         widget.onChanged(_value);
//       },
//       child: Container(
//         width: 40,
//         height: 200,
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Stack(
//           alignment: AlignmentDirectional.center,
//           children: [
//             Container(
//               alignment: Alignment(0, _valueToAlignment(_value)),
//               child: Container(
//                 width: 20,
//                 height: 20,
//                 decoration: const BoxDecoration(
//                   color: Colors.blue,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   double _valueToAlignment(double value) {
//     double range = widget.max - widget.min;
//     return ((value - widget.min) / range) * 2 - 1; // Transforma o valor em -1 a 1
//   }
// }
