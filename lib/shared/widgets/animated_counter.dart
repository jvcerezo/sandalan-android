import 'package:flutter/material.dart';
import '../../core/utils/formatters.dart';

/// Animates a numeric value change (e.g., balance going from 0 to actual value).
class AnimatedCurrency extends StatelessWidget {
  final double value;
  final String currencyCode;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCurrency({
    super.key,
    required this.value,
    this.currencyCode = 'PHP',
    this.style,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text(
          formatCurrency(animatedValue, currencyCode: currencyCode),
          style: style,
        );
      },
    );
  }
}

/// Animates a progress bar value from 0 to target.
class AnimatedProgressBar extends StatelessWidget {
  final double value;
  final double minHeight;
  final Color? color;
  final Color? backgroundColor;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.minHeight = 6,
    this.color,
    this.backgroundColor,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(minHeight / 2),
          child: LinearProgressIndicator(
            value: animatedValue,
            minHeight: minHeight,
            backgroundColor: backgroundColor ?? colorScheme.surfaceContainerHighest,
            color: color ?? colorScheme.primary,
          ),
        );
      },
    );
  }
}
