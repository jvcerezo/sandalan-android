import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/widgets/animated_counter.dart';

// ─── Stage Data ────────────────────────────────────────────────────────────────

class _StageData {
  final String id;
  final String title;
  final String subtitle;
  final String progress;
  final IconData icon;
  final Color color;

  const _StageData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.icon,
    required this.color,
  });
}

const _stages = [
  _StageData(id: 'unang-hakbang', title: 'Unang Hakbang', subtitle: 'First Steps',
      progress: '0/12', icon: LucideIcons.graduationCap, color: StageColors.blue),
  _StageData(id: 'pundasyon', title: 'Pundasyon', subtitle: 'Building the Foundation',
      progress: '0/11', icon: LucideIcons.toyBrick, color: StageColors.emerald),
  _StageData(id: 'tahanan', title: 'Tahanan', subtitle: 'Establishing a Home',
      progress: '0/5', icon: LucideIcons.home, color: StageColors.violet),
  _StageData(id: 'tugatog', title: 'Tugatog', subtitle: 'Career Peak',
      progress: '0/10', icon: LucideIcons.mountain, color: StageColors.amber),
  _StageData(id: 'paghahanda', title: 'Paghahanda', subtitle: 'Pre-Retirement',
      progress: '0/10', icon: LucideIcons.clock, color: StageColors.rose),
  _StageData(id: 'gintong-taon', title: 'Gintong Taon', subtitle: 'Golden Years',
      progress: '0/10', icon: LucideIcons.gem, color: StageColors.yellow),
];

// ─── Screen ────────────────────────────────────────────────────────────────────

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Adulting Journey',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
              const SizedBox(height: 2),
              Text('Level up through every stage of Filipino adult life.',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 14),

              // Overall progress
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Overall Progress',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('0/58 completed',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: AnimatedProgressBar(
                        value: 0,
                        minHeight: 6,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Journey map with Philippine backdrop
        Expanded(
          child: _JourneyMap(),
        ),
      ],
    );
  }
}

// ─── Journey Map ───────────────────────────────────────────────────────────────

class _JourneyMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: CustomPaint(
            painter: _ArchipelagoPainter(
              isDark: isDark,
              primaryColor: colorScheme.primary,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                children: [
                  for (int i = 0; i < _stages.length; i++) ...[
                    _JourneyNode(stage: _stages[i], index: i),
                    if (i < _stages.length - 1)
                      _DashedConnector(
                        fromColor: _stages[i].color,
                        toColor: _stages[i + 1].color,
                        goRight: i.isEven,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Journey Node (Circle icon + label) ────────────────────────────────────────

class _JourneyNode extends StatelessWidget {
  final _StageData stage;
  final int index;

  const _JourneyNode({required this.stage, required this.index});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLeft = index.isEven;

    return Row(
      mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // TODO: Navigate to stage detail
          },
          child: SizedBox(
            width: 160,
            child: Column(
              children: [
                // Circle icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: stage.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: stage.color.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(stage.icon, size: 30, color: Colors.white),
                ),
                const SizedBox(height: 10),
                // Title
                Text(stage.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center),
                // Subtitle
                Text(stage.subtitle,
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
                // Progress
                Text(stage.progress,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: stage.color)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Dashed Curved Connector ───────────────────────────────────────────────────

class _DashedConnector extends StatelessWidget {
  final Color fromColor;
  final Color toColor;
  final bool goRight;

  const _DashedConnector({
    required this.fromColor,
    required this.toColor,
    required this.goRight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: CustomPaint(
        size: Size(MediaQuery.of(context).size.width - 40, 60),
        painter: _DashedCurvePainter(
          fromColor: fromColor,
          toColor: toColor,
          goRight: goRight,
        ),
      ),
    );
  }
}

class _DashedCurvePainter extends CustomPainter {
  final Color fromColor;
  final Color toColor;
  final bool goRight;

  _DashedCurvePainter({
    required this.fromColor,
    required this.toColor,
    required this.goRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Start from center of left/right node, curve to opposite side
    final startX = goRight ? 80.0 : size.width - 80;
    final endX = goRight ? size.width - 80 : 80.0;

    final path = Path();
    path.moveTo(startX, 0);
    path.cubicTo(
      startX, size.height * 0.5,
      endX, size.height * 0.5,
      endX, size.height,
    );

    // Draw dashed with gradient
    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;
    const dashLength = 8.0;
    const gapLength = 6.0;

    double distance = 0;
    while (distance < totalLength) {
      final start = distance;
      final end = math.min(distance + dashLength, totalLength);
      final t = distance / totalLength;

      paint.color = Color.lerp(
        fromColor.withValues(alpha: 0.5),
        toColor.withValues(alpha: 0.5),
        t,
      )!;

      final extractedPath = metrics.extractPath(start, end);
      canvas.drawPath(extractedPath, paint);

      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Philippine Archipelago Background Painter ─────────────────────────────────

class _ArchipelagoPainter extends CustomPainter {
  final bool isDark;
  final Color primaryColor;

  _ArchipelagoPainter({required this.isDark, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final opacity = isDark ? 0.15 : 0.08;

    // Luzon (top area, large)
    _drawIsland(canvas, size, paint,
      cx: size.width * 0.55, cy: size.height * 0.10,
      points: _luzonShape, scale: size.width * 0.50, color: primaryColor, opacity: opacity);

    // Mindoro (mid-left)
    _drawIsland(canvas, size, paint,
      cx: size.width * 0.15, cy: size.height * 0.30,
      points: _smallIslandShape, scale: size.width * 0.18, color: StageColors.emerald, opacity: opacity * 0.8);

    // Visayas cluster (center)
    _drawIsland(canvas, size, paint,
      cx: size.width * 0.50, cy: size.height * 0.42,
      points: _visayasShape1, scale: size.width * 0.28, color: StageColors.violet, opacity: opacity * 0.9);
    _drawIsland(canvas, size, paint,
      cx: size.width * 0.78, cy: size.height * 0.46,
      points: _visayasShape2, scale: size.width * 0.20, color: StageColors.violet, opacity: opacity * 0.7);
    _drawIsland(canvas, size, paint,
      cx: size.width * 0.30, cy: size.height * 0.50,
      points: _smallIslandShape, scale: size.width * 0.14, color: StageColors.amber, opacity: opacity * 0.6);

    // Mindanao (bottom area, large)
    _drawIsland(canvas, size, paint,
      cx: size.width * 0.60, cy: size.height * 0.72,
      points: _mindanaoShape, scale: size.width * 0.45, color: StageColors.rose, opacity: opacity * 0.9);

    // Palawan (left side, elongated)
    _drawIsland(canvas, size, paint,
      cx: size.width * 0.06, cy: size.height * 0.45,
      points: _palawanShape, scale: size.width * 0.12, color: StageColors.amber, opacity: opacity * 0.8);

    // Scattered small islands
    _drawIsland(canvas, size, paint,
      cx: size.width * 0.90, cy: size.height * 0.20,
      points: _smallIslandShape, scale: size.width * 0.10, color: primaryColor, opacity: opacity * 0.5);
    _drawIsland(canvas, size, paint,
      cx: size.width * 0.20, cy: size.height * 0.65,
      points: _smallIslandShape, scale: size.width * 0.10, color: StageColors.yellow, opacity: opacity * 0.5);
    _drawIsland(canvas, size, paint,
      cx: size.width * 0.85, cy: size.height * 0.88,
      points: _smallIslandShape, scale: size.width * 0.08, color: StageColors.yellow, opacity: opacity * 0.4);

    // Water ripple circles (subtle)
    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = primaryColor.withValues(alpha: isDark ? 0.10 : 0.06);

    for (final pos in _ripplePositions) {
      canvas.drawCircle(
        Offset(size.width * pos.dx, size.height * pos.dy),
        size.width * 0.06,
        ripplePaint,
      );
    }
  }

  void _drawIsland(Canvas canvas, Size size, Paint paint, {
    required double cx, required double cy,
    required List<Offset> points, required double scale,
    required Color color, required double opacity,
  }) {
    paint.color = color.withValues(alpha: opacity);
    final path = Path();
    if (points.isEmpty) return;

    path.moveTo(cx + points[0].dx * scale, cy + points[0].dy * scale);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      final midY = (prev.dy + curr.dy) / 2;
      path.quadraticBezierTo(
        cx + prev.dx * scale, cy + prev.dy * scale,
        cx + midX * scale, cy + midY * scale,
      );
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // Simplified island shapes as relative points
  static const _luzonShape = [
    Offset(0.0, -0.4), Offset(0.15, -0.5), Offset(0.3, -0.35),
    Offset(0.4, -0.1), Offset(0.35, 0.1), Offset(0.5, 0.25),
    Offset(0.4, 0.4), Offset(0.2, 0.5), Offset(0.0, 0.35),
    Offset(-0.15, 0.2), Offset(-0.3, 0.0), Offset(-0.2, -0.2),
  ];

  static const _mindanaoShape = [
    Offset(0.0, -0.3), Offset(0.25, -0.35), Offset(0.4, -0.15),
    Offset(0.45, 0.1), Offset(0.3, 0.3), Offset(0.1, 0.35),
    Offset(-0.15, 0.3), Offset(-0.35, 0.15), Offset(-0.4, -0.05),
    Offset(-0.3, -0.25),
  ];

  static const _visayasShape1 = [
    Offset(0.0, -0.25), Offset(0.3, -0.2), Offset(0.4, 0.0),
    Offset(0.3, 0.2), Offset(0.0, 0.25), Offset(-0.3, 0.15),
    Offset(-0.35, -0.05), Offset(-0.2, -0.2),
  ];

  static const _visayasShape2 = [
    Offset(0.0, -0.2), Offset(0.25, -0.15), Offset(0.3, 0.05),
    Offset(0.15, 0.2), Offset(-0.1, 0.2), Offset(-0.25, 0.05),
    Offset(-0.2, -0.15),
  ];

  static const _palawanShape = [
    Offset(0.0, -0.8), Offset(0.15, -0.5), Offset(0.1, -0.1),
    Offset(0.15, 0.3), Offset(0.05, 0.7), Offset(-0.1, 0.8),
    Offset(-0.15, 0.4), Offset(-0.1, 0.0), Offset(-0.15, -0.4),
  ];

  static const _smallIslandShape = [
    Offset(0.0, -0.3), Offset(0.25, -0.15), Offset(0.3, 0.1),
    Offset(0.1, 0.3), Offset(-0.2, 0.2), Offset(-0.3, -0.05),
  ];

  static const _ripplePositions = [
    Offset(0.45, 0.15), Offset(0.20, 0.40), Offset(0.65, 0.55),
    Offset(0.15, 0.72), Offset(0.50, 0.80), Offset(0.80, 0.30),
  ];

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
