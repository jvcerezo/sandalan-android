/// Sandalan brand mark widget using the actual bahay kubo SVG logo.
/// "Sandal" in dark text + "an" in primary green.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandMark extends StatelessWidget {
  final double size;
  final bool showText;

  const BrandMark({super.key, this.size = 40, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF3F6F4) : const Color(0xFF14213D);

    // Dark mode: use version with white bg (dark house visible on white).
    // Light mode: use transparent bg version (dark house visible on light surface).
    final svgAsset = isDark
        ? 'assets/images/app-icon.svg'
        : 'assets/images/app-icon-nobg.svg';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: SvgPicture.asset(
            svgAsset,
            width: size,
            height: size,
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.25),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: size * 0.5,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: textColor,
              ),
              children: [
                const TextSpan(text: 'Sandal'),
                TextSpan(
                  text: 'an',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
