/// Sandalan brand mark widget matching the web app's logo.
/// "Sandal" in dark text + "an" in primary green.

import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  final double size;
  final bool showText;

  const BrandMark({super.key, this.size = 40, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF0F4F2) : const Color(0xFF14213D);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo icon (bahay kubo)
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(size * 0.22),
          ),
          child: Icon(
            Icons.home_rounded,
            color: colorScheme.onPrimary,
            size: size * 0.55,
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
