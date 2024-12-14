import 'package:flutter/material.dart';

class DrawlySliderFb3 extends StatefulWidget {
  final double min;
  final double max;
  final double initialValue;
  final bool showMinMaxText;
  final int divisions;
  final Color accentColor;
  final Function(double) onChanged;
  final TextStyle minMaxTextStyle;

  const DrawlySliderFb3({
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.initialValue = 0.0,
    this.accentColor = Colors.white,
    this.showMinMaxText = true,
    this.minMaxTextStyle = const TextStyle(fontSize: 14),
    super.key,
  });

  @override
  State<DrawlySliderFb3> createState() => _DrawlySliderFb3State();
}

class _DrawlySliderFb3State extends State<DrawlySliderFb3> {
  late double _currentSliderValue;
  @override
  void initState() {
    super.initState();
    _currentSliderValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: widget.showMinMaxText ? const EdgeInsets.only(left: 15.5, right: 15.5) : EdgeInsets.zero,
        child: Row(
          children: [
            widget.showMinMaxText
                ? Text(
                    '${widget.min.toInt()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : const SizedBox.shrink(),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: widget.accentColor,
                  inactiveTrackColor: widget.accentColor.withAlpha(35),
                  trackShape: const RoundedRectSliderTrackShape(),
                  trackHeight: 4.0,
                  thumbShape: CustomSliderThumbCircle(
                    thumbRadius: 20,
                    min: widget.min,
                    max: widget.max,
                  ),
                  thumbColor: widget.accentColor,
                  overlayColor: widget.accentColor.withAlpha(32),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 28.0),
                  tickMarkShape: const RoundSliderTickMarkShape(),
                  activeTickMarkColor: widget.accentColor,
                  inactiveTickMarkColor: widget.accentColor,
                  valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                  valueIndicatorColor: widget.accentColor,
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.white,
                  ),
                ),
                child: Slider(
                  min: widget.min,
                  max: widget.max,
                  value: _currentSliderValue,
                  divisions: widget.divisions,
                  onChanged: (value) {
                    setState(() {
                      _currentSliderValue = value;
                    });
                    widget.onChanged(value);
                  },
                ),
              ),
            ),
            widget.showMinMaxText
                ? Text(
                    '${widget.max.toInt()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

// Credits to @Ankit Chowdhury
class CustomSliderThumbCircle extends SliderComponentShape {
  final double thumbRadius;
  final double min;
  final double max;

  const CustomSliderThumbCircle({
    required this.thumbRadius,
    this.min = 0.0,
    this.max = 100.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    TextSpan span = TextSpan(
      style: TextStyle(
        fontSize: thumbRadius * .6,
        fontWeight: FontWeight.w700,
        // color: sliderTheme.thumbColor,
        color: Colors.white,
      ),
      text: getValue(value),
    );

    TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    tp.layout();
    Offset textCenter = Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2));

    canvas.drawCircle(center, thumbRadius * .7, paint);
    tp.paint(canvas, textCenter);
  }

  String getValue(double value) {
    return (min + (max - min) * value).round().toString();
  }
}
