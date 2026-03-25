import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/milestone_service.dart';
import '../../core/theme/color_tokens.dart';

/// Show the appropriate celebration for a milestone based on its tier.
void showMilestoneCelebration(BuildContext context, Milestone milestone) {
  debugPrint('showMilestoneCelebration: ${milestone.id} tier=${milestone.tier} mounted=${context.mounted}');
  if (!context.mounted) return;
  switch (milestone.tier) {
    case MilestoneTier.a:
      HapticFeedback.heavyImpact();
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        barrierDismissible: true,
        builder: (_) => _MilestoneCelebrationOverlay(milestone: milestone),
      );
      break;
    case MilestoneTier.b:
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(milestone.icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${milestone.title}${milestone.description != null ? ' — ${milestone.description}' : ''}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to achievements handled by caller
            },
          ),
        ),
      );
      break;
    case MilestoneTier.c:
      // Silent — no UI
      break;
  }
}

class _MilestoneCelebrationOverlay extends StatefulWidget {
  final Milestone milestone;

  const _MilestoneCelebrationOverlay({required this.milestone});

  @override
  State<_MilestoneCelebrationOverlay> createState() =>
      _MilestoneCelebrationOverlayState();
}

class _MilestoneCelebrationOverlayState
    extends State<_MilestoneCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Confetti particles
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _ConfettiPainter(
                  progress: _controller.value,
                  primaryColor: colorScheme.primary,
                ),
              );
            },
          ),
        ),
        // Centered card
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              height: 280,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon in colored circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.milestone.icon,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    widget.milestone.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.milestone.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.milestone.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Dismiss button
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Salamat!'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple confetti painter: 20 colored dots that fall and fade over 2 seconds.
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final List<_Particle> _particles;

  _ConfettiPainter({
    required this.progress,
    required this.primaryColor,
  }) : _particles = _generateParticles(primaryColor);

  static List<_Particle> _generateParticles(Color primary) {
    final rng = Random(42); // Fixed seed for consistent particles
    final colors = [
      primary,
      AppColors.income,
      StageColors.blue,
      StageColors.amber,
      StageColors.violet,
      StageColors.rose,
    ];

    return List.generate(20, (i) {
      return _Particle(
        startX: rng.nextDouble(),
        startY: rng.nextDouble() * 0.3, // start in top 30%
        velocityX: (rng.nextDouble() - 0.5) * 0.3,
        velocityY: 0.5 + rng.nextDouble() * 0.5,
        size: 4 + rng.nextDouble() * 6,
        color: colors[i % colors.length],
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final x = (p.startX + p.velocityX * progress) * size.width;
      final y = (p.startY + p.velocityY * progress) * size.height;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}

class _Particle {
  final double startX, startY, velocityX, velocityY, size;
  final Color color;

  const _Particle({
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.color,
  });
}
