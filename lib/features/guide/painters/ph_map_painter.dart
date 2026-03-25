import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Subtle gradient mesh background with soft radial glows
/// that match each stage's color as you scroll through the journey.
class JourneyBackdropPainter extends CustomPainter {
  final bool isDark;
  final List<Color> stageColors;

  JourneyBackdropPainter({required this.isDark, required this.stageColors});

  @override
  void paint(Canvas canvas, Size size) {
    // Soft radial glows at each stage's vertical position
    for (int i = 0; i < stageColors.length; i++) {
      final t = (i + 0.5) / stageColors.length;
      final cy = size.height * t;
      final cx = i.isEven ? size.width * 0.2 : size.width * 0.8;
      final radius = size.width * 0.6;

      final gradient = RadialGradient(
        center: Alignment(
          (cx / size.width) * 2 - 1,
          (cy / size.height) * 2 - 1,
        ),
        radius: radius / size.width,
        colors: [
          stageColors[i].withOpacity(isDark ? 0.08 : 0.06),
          stageColors[i].withOpacity(0),
        ],
      );

      final rect = Offset.zero & size;
      canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
