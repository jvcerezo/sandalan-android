import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Sandalan branded loading indicator.
/// Shows the bahay kubo logo with a gentle pulse + rotating ring.
class SandalanLoading extends StatefulWidget {
  final double size;
  final String? message;
  const SandalanLoading({super.key, this.size = 48, this.message});

  @override
  State<SandalanLoading> createState() => _SandalanLoadingState();
}

class _SandalanLoadingState extends State<SandalanLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final svgAsset = isDark
        ? 'assets/images/app-icon-dark.svg'
        : 'assets/images/app-icon-nobg.svg';
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size + 16,
          height: widget.size + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating ring
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform.rotate(
                  angle: _controller.value * 6.28,
                  child: child,
                ),
                child: SizedBox(
                  width: widget.size + 12,
                  height: widget.size + 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary.withOpacity(0.3),
                  ),
                ),
              ),
              // Pulsing logo
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // Gentle pulse: 1.0 -> 1.06 -> 1.0
                  final pulse = 1.0 + (0.06 * (0.5 + 0.5 * (1 - (2 * _controller.value - 1).abs())));
                  return Transform.scale(scale: pulse, child: child);
                },
                child: SvgPicture.asset(svgAsset, width: widget.size, height: widget.size),
              ),
            ],
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(widget.message!,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

/// Animated success checkmark with a circle draw + check draw.
class SuccessCheckmark extends StatefulWidget {
  final double size;
  final Color? color;
  final VoidCallback? onComplete;
  const SuccessCheckmark({super.key, this.size = 64, this.color, this.onComplete});

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFF16A34A);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CheckPainter(
            progress: _controller.value,
            color: color,
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  _CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // Circle (draws first 60% of animation)
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final circleProgress = (progress / 0.6).clamp(0.0, 1.0);
    if (circleProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.57, // Start at top
        circleProgress * 6.28,
        false,
        circlePaint,
      );
    }

    // Fill circle with subtle background
    if (circleProgress >= 1.0) {
      canvas.drawCircle(center, radius, Paint()..color = color.withOpacity(0.08));
    }

    // Checkmark (draws last 40% of animation)
    final checkProgress = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      // Check mark points (relative to center)
      final p1 = Offset(center.dx - radius * 0.3, center.dy + radius * 0.05);
      final p2 = Offset(center.dx - radius * 0.05, center.dy + radius * 0.3);
      final p3 = Offset(center.dx + radius * 0.35, center.dy - radius * 0.25);

      if (checkProgress <= 0.5) {
        // First stroke: p1 -> p2
        final t = checkProgress / 0.5;
        path.moveTo(p1.dx, p1.dy);
        path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
      } else {
        // Full first stroke + partial second stroke
        final t = (checkProgress - 0.5) / 0.5;
        path.moveTo(p1.dx, p1.dy);
        path.lineTo(p2.dx, p2.dy);
        path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => progress != old.progress;
}

/// Animated empty state — icon floats gently while text fades in.
class AnimatedEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const AnimatedEmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                final offset = -6.0 * _floatController.value;
                return Transform.translate(offset: Offset(0, offset), child: child);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 40,
                    color: cs.onSurfaceVariant.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
                textAlign: TextAlign.center),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(widget.subtitle!,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
            if (widget.action != null) ...[
              const SizedBox(height: 16),
              widget.action!,
            ],
          ]),
        ),
      ),
    );
  }
}
