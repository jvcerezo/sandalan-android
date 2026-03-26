import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/widgets/animated_counter.dart';

/// Shared Y-axis label formatter for chart widgets.
/// Converts values like 1500000 -> "₱1.5M", 25000 -> "₱25K", 500 -> "₱500".
String formatYAxisLabel(double value) {
  final absVal = value.abs();
  String label;
  if (absVal >= 1000000) {
    label = '${(value / 1000000).toStringAsFixed(1)}M';
  } else if (absVal >= 1000) {
    label = '${(value / 1000).toStringAsFixed(0)}K';
  } else {
    label = value.toStringAsFixed(0);
  }
  return '\u20B1$label';
}

/// Compact currency formatter for chart tooltips.
String formatCompactCurrency(double value) {
  if (value >= 1000000) {
    return '₱${(value / 1000000).toStringAsFixed(1)}M';
  } else if (value >= 1000) {
    return '₱${(value / 1000).toStringAsFixed(0)}K';
  } else {
    return '₱${value.toStringAsFixed(0)}';
  }
}

/// Formats a "YYYY-MM" string into "Mon 'YY" (e.g. "2026-03" -> "Mar '26").
String formatMonth(String ym) {
  final parts = ym.split('-');
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final y = parts[0].substring(2);
  final m = int.parse(parts[1]);
  return "${months[m]} '$y";
}

// ─── Section Label ──────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ));
  }
}

// ─── Overview Card ──────────────────────────────────────────────────────────

class OverviewCard extends StatelessWidget {
  final Widget child;
  const OverviewCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

// ─── Quick Stat ─────────────────────────────────────────────────────────────

class QuickStat extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String value;
  final String subtitle;
  const QuickStat({super.key, required this.icon, this.label, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 14, color: colorScheme.primary),
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(label!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  letterSpacing: 0.5, color: colorScheme.onSurfaceVariant)),
            ],
          ]),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

// ─── Mini Stat Label ────────────────────────────────────────────────────────

class MiniStatLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const MiniStatLabel({super.key, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}

// ─── Health Row ─────────────────────────────────────────────────────────────

class HealthRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double progress;
  const HealthRow({super.key, required this.label, required this.value, required this.color, required this.progress});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.primary)),
          Text(value, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        ]),
        const SizedBox(height: 4),
        AnimatedProgressBar(
          value: progress.clamp(0, 1),
          minHeight: 4,
          backgroundColor: colorScheme.surfaceContainerHighest,
          color: color,
        ),
      ]),
    );
  }
}

// ─── Breakdown Row ──────────────────────────────────────────────────────────

class BreakdownRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const BreakdownRow({super.key, required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }
}

// ─── Legend Dot ──────────────────────────────────────────────────────────────

class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const LegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}

// ─── Gauge Painter ──────────────────────────────────────────────────────────

class GaugePainter extends CustomPainter {
  final double value; // 0-100
  final Color color;
  final String label;

  GaugePainter({required this.value, required this.color, this.label = 'Fair'});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.8);
    final radius = size.width / 2 - 12;

    // Background arc
    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, math.pi, false, bgPaint,
    );

    // Value arc
    final valPaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, math.pi * (value / 100), false, valPaint,
    );

    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${value.toInt()}',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height - 4));

    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, Offset(center.dx - labelPainter.width / 2, center.dy - 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
