import 'dart:math' as math;
// import 'dart:ui' as ui;

import 'package:drawly/core/widgets/session_pick_avatar.dart';
import 'package:drawly/features/draw_game/draw_game_room_selection_page.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_box_shadow/flutter_inset_box_shadow.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                height: 500,
                width: 500,
                // child: NeonCard(
                //   intensity: 1,
                //   glowSpread: .7,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 64,
                        child: Center(
                          child: GradientText(
                            text: 'DRAWLY',
                            fontSize: 44,
                            gradientColors: [
                              Color.fromARGB(255, 255, 41, 117),
                              Color.fromARGB(255, 255, 41, 117),
                              Color.fromARGB(255, 9, 221, 222),
                            ],
                          ),
                        ),
                      ),
                      _AuthBody(),
                    ],
                  ),
                ),
                // ),
              ),
            ),
            TextRotateDemo(),
          ],
        ),
      ),
    );
  }
}

class _AuthBody extends StatefulWidget {
  const _AuthBody();

  @override
  State<_AuthBody> createState() => _AuthBodyState();
}

class _AuthBodyState extends State<_AuthBody> {
  final usernameController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SessionPickAvatar(),
        SizedBox(
          width: 300,
          child: NeumorphicValidationField(
            textEditingController: usernameController,
            // labelText: 'Apelido', // Nick
            hintText: 'Insira seu apelido', // Enter your nickname
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            final username = usernameController.text.trim();
            if (username.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DrawGameRoomSelectionPage(username: username),
                ),
              );
            }
          },
          child: const Text('Salas'),
        ),
      ],
    );
  }
}

// class NeonCard extends StatefulWidget {
//   const NeonCard({
//     required this.child,
//     super.key,
//     this.intensity = 0.3,
//     this.glowSpread = 2.0,
//   });

//   final Widget child;
//   final double intensity;
//   final double glowSpread;

//   @override
//   State<NeonCard> createState() => _NeonCardState();
// }

// class _NeonCardState extends State<NeonCard>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         return CustomPaint(
//           painter: GlowPainter(
//             progress: _controller.value,
//             intensity: widget.intensity,
//             glowSpread: widget.glowSpread,
//           ),
//           child: widget.child,
//         );
//       },
//     );
//   }
// }

// class GlowPainter extends CustomPainter {
//   GlowPainter({
//     required this.progress,
//     this.intensity = 0.3,
//     this.glowSpread = 2.0,
//   });

//   final double progress;
//   final double intensity;
//   final double glowSpread;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final rect = Rect.fromLTWH(0, 0, size.width, size.height);
//     final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(1000));

//     const firstColor = Color(0xFFFF00AA);
//     const secondColor = Color(0xFF00FFF1);
//     const blurSigma = 50.0;

//     // Background glow gradient
//     final backgroundPaint = Paint()
//       ..shader = ui.Gradient.radial(
//         Offset(size.width / 2, size.height / 2),
//         size.width * glowSpread,
//         [
//           Color.lerp(firstColor, secondColor, progress)!.withOpacity(intensity),
//           Color.lerp(firstColor, secondColor, progress)!.withOpacity(0),
//         ],
//       )
//       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, blurSigma);

//     canvas.drawRect(rect.inflate(size.width * glowSpread), backgroundPaint);

//     final cardPaint = Paint()..color = Colors.white;
//     canvas.drawRRect(rrect, cardPaint);

//     // Glow outline
//     final glowPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3
//       ..shader = LinearGradient(
//         colors: [
//           Color.lerp(firstColor, secondColor, progress)!,
//           Color.lerp(secondColor, firstColor, progress)!,
//         ],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ).createShader(rect);

//     canvas.drawRRect(rrect, glowPaint);
//   }

//   @override
//   bool shouldRepaint(GlowPainter oldDelegate) =>
//       oldDelegate.progress != progress ||
//       oldDelegate.intensity != intensity ||
//       oldDelegate.glowSpread != glowSpread;
// }

// class GlowRectanglePainter extends CustomPainter {
//   GlowRectanglePainter({
//     required this.progress,
//     this.intensity = 0.3,
//     this.glowSpread = 2.0,
//   });
//   final double progress;
//   final double intensity;
//   final double glowSpread;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final rect = Rect.fromLTWH(0, 0, size.width, size.height);
//     final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

//     const firstColor = Color(0xFFFF00AA);
//     const secondColor = Color(0xFF00FFF1);
//     const blurSigma = 50.0;

//     final backgroundPaint = Paint()
//       ..shader = ui.Gradient.radial(
//         Offset(size.width / 2, size.height / 2),
//         size.width * glowSpread,
//         [
//           Color.lerp(firstColor, secondColor, progress)!.withOpacity(intensity),
//           Color.lerp(firstColor, secondColor, progress)!.withOpacity(0),
//         ],
//       )
//       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, blurSigma);
//     canvas.drawRect(rect.inflate(size.width * glowSpread), backgroundPaint);

//     final cardPaint = Paint()..color = Colors.white;
//     canvas.drawRRect(rrect, cardPaint);

//     final glowPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2
//       ..shader = LinearGradient(
//         colors: [
//           Color.lerp(firstColor, secondColor, progress)!,
//           Color.lerp(secondColor, firstColor, progress)!,
//         ],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ).createShader(rect);

//     canvas.drawRRect(rrect, glowPaint);
//   }

//   @override
//   bool shouldRepaint(GlowRectanglePainter oldDelegate) =>
//       oldDelegate.progress != progress ||
//       oldDelegate.intensity != intensity ||
//       oldDelegate.glowSpread != glowSpread;
// }

class GradientText extends StatelessWidget {
  const GradientText({
    required this.text,
    required this.fontSize,
    required this.gradientColors,
    super.key,
  });
  final String text;
  final double fontSize;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          colors: gradientColors,
          stops: const [0.0, 0.3, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          height: 1,
          letterSpacing: -1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class TextRotateDemo extends StatefulWidget {
  const TextRotateDemo({super.key});

  @override
  State<TextRotateDemo> createState() => _TextRotateDemoState();
}

class _TextRotateDemoState extends State<TextRotateDemo> {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: const IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: RotatingTextWidget(
                          text: 'Desenhe, adivinhe e se divirta como nunca',
                          radius: 250,
                          textStyle: TextStyle(
                              fontSize: 18, color: AppColors.darkBlueAccent),
                          rotationDuration: Duration(seconds: 120),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class NeumorphicValidationField extends StatefulWidget {
  const NeumorphicValidationField({
    required this.textEditingController,
    this.labelText,
    this.hintText,
    this.isPasswordField = false,
    super.key,
  });

  final bool isPasswordField;
  final TextEditingController textEditingController;
  final String? labelText;
  final String? hintText;

  @override
  NeumorphicValidationFieldState createState() =>
      NeumorphicValidationFieldState();
}

class NeumorphicValidationFieldState extends State<NeumorphicValidationField> {
  bool _showErrorIcon = true;
  bool _isObscureText = true;

  @override
  void dispose() {
    widget.textEditingController.dispose();
    super.dispose();
  }

  void _validateInput(String value) {
    setState(() {
      _showErrorIcon = value.isEmpty;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isObscureText = !_isObscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryContainer(
      // color: Colors.white,
      radius: 10,
      child: TextFormField(
        onChanged: _validateInput,
        obscureText: widget.isPasswordField ? _isObscureText : false,
        style: const TextStyle(fontSize: 16, color: Colors.white),
        controller: widget.textEditingController,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: TextStyle(
            fontSize: 16,
            color: AppColors.greyAccent,
            fontWeight: FontWeight.bold,
          ),
          hintText: widget.hintText,
          contentPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 3),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          filled: false,
          hintStyle: TextStyle(
            fontSize: 16,
            color: AppColors.greyAccent,
            fontWeight: FontWeight.bold,
          ),
          suffixIcon: widget.isPasswordField
              ? IconButton(
                  icon: _isObscureText
                      ? const Icon(Icons.visibility, color: Colors.grey)
                      : const Icon(Icons.visibility_off, color: Colors.grey),
                  onPressed: _togglePasswordVisibility,
                )
              : _showErrorIcon
                  ? const Padding(
                      padding: EdgeInsets.all(15),
                      child: Icon(Icons.error, color: Colors.red),
                    )
                  : const Padding(
                      padding: EdgeInsets.all(15),
                      child: Icon(Icons.check_box_rounded, color: Colors.green),
                    ),
        ),
      ),
    );
  }
}

class PrimaryContainer extends StatelessWidget {
  const PrimaryContainer({
    super.key,
    this.radius,
    this.color,
    required this.child,
  });
  
  final double? radius;
  final Color? color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            color: Colors.black,
            inset: true,
          ),
        ],
      ),
      child: child,
    );
  }
}

class RotatingTextWidget extends StatefulWidget {
  const RotatingTextWidget({
    required this.text,
    required this.radius,
    required this.textStyle,
    required this.rotationDuration,
    super.key,
  });

  final String text;
  final double radius;
  final TextStyle textStyle;
  final Duration rotationDuration;

  @override
  State<RotatingTextWidget> createState() => _RotatingTextWidgetState();
}

class _RotatingTextWidgetState extends State<RotatingTextWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.rotationDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.radius * 2, widget.radius * 2),
          painter: _CircularTextPainter(
            text: widget.text,
            radius: widget.radius,
            textStyle: widget.textStyle,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _CircularTextPainter extends CustomPainter {
  final String text;
  final double radius;
  final TextStyle textStyle;
  final double progress;

  _CircularTextPainter({
    required this.text,
    required this.radius,
    required this.textStyle,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    const double totalAngle = 2 * math.pi;
    double startAngle = -math.pi / 2 + (progress * totalAngle);

    // Calculate the total width of the text and dot
    double textWidth = _calculateTextWidth(text);
    double dotWidth = textStyle.fontSize!;
    double totalWidth = textWidth + dotWidth;

    // Calculate how many times the text can fit
    int repetitions = (totalAngle * radius / totalWidth).floor();
    repetitions = math.max(1, repetitions); // Ensure at least one repetition

    double segmentAngle = totalAngle / repetitions;
    double textAngle = (textWidth / totalWidth) * segmentAngle;
    double dotAngle = segmentAngle - textAngle;

    for (int rep = 0; rep < repetitions; rep++) {
      // Draw the dot before the text
      _drawDot(canvas, centerX, centerY, startAngle, radius);

      // Adjust the start angle for the text to come after the dot
      // double textStartAngle = startAngle + dotAngle;
      double textStartAngle = startAngle + dotAngle / 2; //+ 1.5 * dotAngle;

      // Pre-calculate character widths and total width
      List<double> charWidths = [];
      double totalCharWidth = 0;
      for (int i = 0; i < text.length; i++) {
        final textSpan = TextSpan(text: text[i], style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        charWidths.add(textPainter.width);
        totalCharWidth += textPainter.width;
      }

      // Draw the text
      double currentAngle = textStartAngle;
      for (int i = 0; i < text.length; i++) {
        final textSpan = TextSpan(text: text[i], style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Calculate the proportion of the total angle this character should occupy
        double charProportion = charWidths[i] / totalCharWidth;
        double charAngle = textAngle * charProportion;

        // Center the character within its allocated angle
        double charCenterAngle = currentAngle + (charAngle / 2);

        final x = centerX + radius * math.cos(charCenterAngle);
        final y = centerY + radius * math.sin(charCenterAngle);

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(charCenterAngle + math.pi / 2);

        textPainter.paint(
            canvas, Offset(-charWidths[i] / 2, -textPainter.height / 2));

        canvas.restore();

        // Update the angle for the next character
        currentAngle += charAngle;
      }

      // Update the start angle for the next repetition
      startAngle += segmentAngle;
    }
  }

  double _calculateTextWidth(String text) {
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }

  void _drawDot(Canvas canvas, double centerX, double centerY, double angle,
      double radius) {
    final dotRadius = textStyle.fontSize! / 4;
    final dotPaint = Paint()
      ..color = textStyle.color!
      ..style = PaintingStyle.fill;

    final dotX = centerX + radius * math.cos(angle);
    final dotY = centerY + radius * math.sin(angle);

    canvas.drawCircle(Offset(dotX, dotY), dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
