/// Sandalan brand mark widget.

import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  final double size;
  final bool showText;

  const BrandMark({super.key, this.size = 40, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo icon placeholder (bahay kubo)
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(size * 0.25),
          ),
          child: Icon(
            Icons.home_rounded,
            color: colorScheme.onPrimary,
            size: size * 0.6,
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: size * 0.5,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              children: [
                const TextSpan(text: 'Sandal'),
                TextSpan(
                  text: 'an',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
