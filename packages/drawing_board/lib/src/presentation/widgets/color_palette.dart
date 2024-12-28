import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/svg.dart';

class ColorPalette extends StatelessWidget {
  ColorPalette({
    required this.rxSelectedColor,
    super.key,
  });

  final ValueNotifier<Color> rxSelectedColor;
  final GlobalKey _key = GlobalKey();

  double getHeight() {
    final context = _key.currentContext;
    if (context == null) return 0;
    final box = context.findRenderObject()! as RenderBox;
    return box.size.height;
  }

  @override
  Widget build(BuildContext context) {
    final allColors = <Color>[
      Colors.black,
      Colors.white,
      AppColors.greyAccent,
      ...Colors.primaries,
    ];

    return ValueListenableBuilder(
      valueListenable: rxSelectedColor,
      builder: (context, selectedColor, child) {
        return Column(
          key: _key,
          mainAxisSize: MainAxisSize.min,
          children: [
            DrawlyBarGrid(
              crossAxisCount: 3,
              children: [
                for (final Color color in allColors)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => rxSelectedColor.value = color,
                      child: Container(
                        height: 25,
                        width: 25,
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(
                            color: selectedColor == color
                                ? Colors.blue
                                : AppColors.greyAccent,
                            width: 1.5,
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedColor,
                        border: Border.all(color: Colors.blue, width: 1.5),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          showColorWheel(context, rxSelectedColor);
                        },
                        child: SvgPicture.asset(
                          'assets/svgs/color_wheel.svg',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void showColorWheel(BuildContext context, ValueNotifier<Color> color) {
    showDialog<Widget>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: color.value,
              onColorChanged: (value) {
                color.value = value;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}
