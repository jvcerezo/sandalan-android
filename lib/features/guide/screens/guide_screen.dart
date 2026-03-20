import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/widgets/animated_counter.dart';

// ─── Stage Data ────────────────────────────────────────────────────────────────

class _StageData {
  final String title;
  final String subtitle;
  final String progress;
  final IconData icon;
  final Color color;

  const _StageData({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.icon,
    required this.color,
  });
}

const _stages = [
  _StageData(title: 'Unang Hakbang', subtitle: 'First Steps',
      progress: '0/12', icon: LucideIcons.graduationCap, color: StageColors.blue),
  _StageData(title: 'Pundasyon', subtitle: 'Building Foundation',
      progress: '0/11', icon: LucideIcons.toyBrick, color: StageColors.emerald),
  _StageData(title: 'Tahanan', subtitle: 'Establishing Home',
      progress: '0/5', icon: LucideIcons.home, color: StageColors.violet),
  _StageData(title: 'Tugatog', subtitle: 'Career Peak',
      progress: '0/10', icon: LucideIcons.mountain, color: StageColors.amber),
  _StageData(title: 'Paghahanda', subtitle: 'Pre-Retirement',
      progress: '0/10', icon: LucideIcons.clock, color: StageColors.rose),
  _StageData(title: 'Gintong Taon', subtitle: 'Golden Years',
      progress: '0/10', icon: LucideIcons.gem, color: StageColors.yellow),
];

// Winding path node positions (x as fraction of width, y as absolute)
// Zigzags left-center-right like PvZ2
const _nodePositions = [
  Offset(0.25, 0),    // left
  Offset(0.72, 1),    // right
  Offset(0.22, 2),    // left
  Offset(0.70, 3),    // right
  Offset(0.28, 4),    // left
  Offset(0.65, 5),    // right
];

const double _segmentHeight = 200; // vertical space per stage
const double _nodeRadius = 36;
const double _topPadding = 30;

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
              const SizedBox(height: 12),
              // Overall progress
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Overall Progress',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Text('0/58 completed',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: AnimatedProgressBar(value: 0, minHeight: 6, color: colorScheme.primary),
                  ),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Journey map
        Expanded(
          child: _JourneyMapView(),
        ),
      ],
    );
  }
}

// ─── Journey Map View ──────────────────────────────────────────────────────────

class _JourneyMapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final totalHeight = _topPadding + (_stages.length) * _segmentHeight + 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: SizedBox(
        width: screenWidth,
        height: totalHeight,
        child: CustomPaint(
          painter: _MapBackgroundPainter(isDark: isDark, screenWidth: screenWidth),
          child: CustomPaint(
            painter: _PathPainter(isDark: isDark, screenWidth: screenWidth),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < _stages.length; i++)
                  _buildNode(context, i),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNode(BuildContext context, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final pos = _nodePositions[index];
    final cx = pos.dx * screenWidth;
    final cy = _topPadding + pos.dy * _segmentHeight + _segmentHeight * 0.5;
    final stage = _stages[index];
    final isLeft = pos.dx < 0.5;

    return Positioned(
      left: cx - _nodeRadius,
      top: cy - _nodeRadius,
      child: _StageNode(stage: stage, index: index, isLeft: isLeft),
    );
  }
}

// ─── Stage Node ────────────────────────────────────────────────────────────────

class _StageNode extends StatelessWidget {
  final _StageData stage;
  final int index;
  final bool isLeft;

  const _StageNode({required this.stage, required this.index, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: SizedBox(
        width: _nodeRadius * 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing circle
            Container(
              width: _nodeRadius * 2,
              height: _nodeRadius * 2,
              decoration: BoxDecoration(
                color: stage.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: stage.color.withValues(alpha: 0.45),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(stage.icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 6),
            // Title
            Text(stage.title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.1),
                textAlign: TextAlign.center),
            // Subtitle
            Text(stage.subtitle,
                style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant, height: 1.2),
                textAlign: TextAlign.center),
            // Progress
            Text(stage.progress,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: stage.color)),
          ],
        ),
      ),
    );
  }
}

// ─── Winding Path Painter ──────────────────────────────────────────────────────

class _PathPainter extends CustomPainter {
  final bool isDark;
  final double screenWidth;

  _PathPainter({required this.isDark, required this.screenWidth});

  @override
  void paint(Canvas canvas, Size size) {
    // Build the winding path through all nodes
    final points = <Offset>[];
    for (int i = 0; i < _nodePositions.length; i++) {
      final pos = _nodePositions[i];
      points.add(Offset(
        pos.dx * screenWidth,
        _topPadding + pos.dy * _segmentHeight + _segmentHeight * 0.5,
      ));
    }

    if (points.length < 2) return;

    // Road background (thick)
    final roadPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF8B7355)).withValues(alpha: isDark ? 0.08 : 0.12)
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roadPath = _buildSmoothPath(points);
    canvas.drawPath(roadPath, roadPaint);

    // Road center line (dashed, lighter)
    final dashPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFFA0926E)).withValues(alpha: isDark ? 0.06 : 0.08)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, roadPath, dashPaint, 12, 10);

    // Road border dots (small stones along the path)
    final stonePaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF6B5B3E)).withValues(alpha: isDark ? 0.04 : 0.06);

    final metrics = roadPath.computeMetrics().first;
    final rng = math.Random(42);
    for (double d = 0; d < metrics.length; d += 18) {
      final tangent = metrics.getTangentForOffset(d);
      if (tangent == null) continue;
      final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
      // Left side stone
      final leftPos = tangent.position + normal * (14 + rng.nextDouble() * 4);
      canvas.drawCircle(leftPos, 1.5 + rng.nextDouble(), stonePaint);
      // Right side stone
      final rightPos = tangent.position - normal * (14 + rng.nextDouble() * 4);
      canvas.drawCircle(rightPos, 1.5 + rng.nextDouble(), stonePaint);
    }
  }

  Path _buildSmoothPath(List<Offset> points) {
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midY = (p0.dy + p1.dy) / 2;

      path.cubicTo(
        p0.dx, midY,
        p1.dx, midY,
        p1.dx, p1.dy,
      );
    }
    return path;
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashLen, double gapLen) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLen, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Background Scenery Painter (Philippine elements) ──────────────────────────

class _MapBackgroundPainter extends CustomPainter {
  final bool isDark;
  final double screenWidth;

  _MapBackgroundPainter({required this.isDark, required this.screenWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7001);
    final baseOpacity = isDark ? 0.06 : 0.05;

    // ─── Rolling hills / rice terraces ─────────────────────────
    _drawTerraces(canvas, size, baseOpacity, rng);

    // ─── Coconut trees scattered ───────────────────────────────
    _drawCoconutTrees(canvas, size, baseOpacity);

    // ─── Bahay kubo silhouettes ────────────────────────────────
    _drawBahayKubo(canvas, size, baseOpacity, size.width * 0.08, size.height * 0.12);
    _drawBahayKubo(canvas, size, baseOpacity, size.width * 0.88, size.height * 0.48);
    _drawBahayKubo(canvas, size, baseOpacity * 0.7, size.width * 0.14, size.height * 0.72);

    // ─── Jeepney silhouette ────────────────────────────────────
    _drawJeepney(canvas, size, baseOpacity, size.width * 0.82, size.height * 0.22);

    // ─── Waves / water at bottom ───────────────────────────────
    _drawWaves(canvas, size, baseOpacity);

    // ─── Mountain peaks ────────────────────────────────────────
    _drawMountain(canvas, size, baseOpacity * 0.6, size.width * 0.90, size.height * 0.58, 60);
    _drawMountain(canvas, size, baseOpacity * 0.5, size.width * 0.05, size.height * 0.42, 45);

    // ─── Stars / fireflies (dark mode) ─────────────────────────
    if (isDark) {
      final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.08);
      for (int i = 0; i < 25; i++) {
        canvas.drawCircle(
          Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
          rng.nextDouble() * 1.5 + 0.5,
          starPaint,
        );
      }
    }
  }

  void _drawTerraces(Canvas canvas, Size size, double opacity, math.Random rng) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = StageColors.emerald.withValues(alpha: opacity * 0.5);

    // Several stacked curves representing rice terraces
    for (int row = 0; row < 4; row++) {
      final y = size.height * (0.15 + row * 0.22);
      final path = Path();
      path.moveTo(0, y);

      for (double x = 0; x <= size.width; x += size.width / 6) {
        path.lineTo(x, y + math.sin(x / 50 + row * 1.5) * 12 + rng.nextDouble() * 6);
      }
      path.lineTo(size.width, y + 20);
      path.lineTo(0, y + 20);
      path.close();

      paint.color = StageColors.emerald.withValues(alpha: opacity * (0.25 + row * 0.08));
      canvas.drawPath(path, paint);
    }
  }

  void _drawCoconutTrees(Canvas canvas, Size size, double opacity) {
    final positions = [
      Offset(size.width * 0.92, size.height * 0.08),
      Offset(size.width * 0.05, size.height * 0.30),
      Offset(size.width * 0.95, size.height * 0.65),
      Offset(size.width * 0.10, size.height * 0.88),
      Offset(size.width * 0.85, size.height * 0.85),
    ];

    for (final pos in positions) {
      _drawPalmTree(canvas, pos, opacity);
    }
  }

  void _drawPalmTree(Canvas canvas, Offset base, double opacity) {
    // Trunk
    final trunkPaint = Paint()
      ..color = const Color(0xFF8B6914).withValues(alpha: opacity * 0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final trunkPath = Path();
    trunkPath.moveTo(base.dx, base.dy);
    trunkPath.quadraticBezierTo(
      base.dx - 3, base.dy - 22,
      base.dx + 2, base.dy - 40,
    );
    canvas.drawPath(trunkPath, trunkPaint);

    // Fronds
    final frondPaint = Paint()
      ..color = StageColors.emerald.withValues(alpha: opacity * 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final top = Offset(base.dx + 2, base.dy - 40);
    for (final angle in [-0.8, -0.3, 0.2, 0.7, 1.2]) {
      final endX = top.dx + math.cos(angle) * 18;
      final endY = top.dy + math.sin(angle) * 14 - 5;
      final path = Path();
      path.moveTo(top.dx, top.dy);
      path.quadraticBezierTo(
        top.dx + math.cos(angle) * 10,
        top.dy - 8,
        endX, endY,
      );
      canvas.drawPath(path, frondPaint);
    }
  }

  void _drawBahayKubo(Canvas canvas, Size size, double opacity, double cx, double cy) {
    final paint = Paint()
      ..color = const Color(0xFF8B6914).withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.fill;

    final w = 24.0;
    final h = 16.0;

    // Stilts
    final stiltPaint = Paint()
      ..color = const Color(0xFF8B6914).withValues(alpha: opacity * 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - w * 0.3, cy), Offset(cx - w * 0.3, cy + h * 0.5), stiltPaint);
    canvas.drawLine(Offset(cx + w * 0.3, cy), Offset(cx + w * 0.3, cy + h * 0.5), stiltPaint);

    // Body
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - h * 0.1), width: w * 0.7, height: h * 0.5), paint);

    // Roof (triangle)
    final roofPath = Path();
    roofPath.moveTo(cx, cy - h * 0.6);
    roofPath.lineTo(cx - w * 0.55, cy - h * 0.1);
    roofPath.lineTo(cx + w * 0.55, cy - h * 0.1);
    roofPath.close();

    paint.color = StageColors.amber.withValues(alpha: opacity * 0.45);
    canvas.drawPath(roofPath, paint);
  }

  void _drawJeepney(Canvas canvas, Size size, double opacity, double cx, double cy) {
    final paint = Paint()
      ..color = StageColors.blue.withValues(alpha: opacity * 0.4)
      ..style = PaintingStyle.fill;

    // Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 32, height: 14),
      const Radius.circular(3),
    );
    canvas.drawRRect(bodyRect, paint);

    // Roof rack
    canvas.drawRect(
      Rect.fromLTWH(cx - 14, cy - 10, 28, 3),
      Paint()..color = StageColors.amber.withValues(alpha: opacity * 0.3),
    );

    // Wheels
    final wheelPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: opacity * 0.4);
    canvas.drawCircle(Offset(cx - 9, cy + 7), 3, wheelPaint);
    canvas.drawCircle(Offset(cx + 9, cy + 7), 3, wheelPaint);
  }

  void _drawMountain(Canvas canvas, Size size, double opacity, double cx, double cy, double h) {
    final paint = Paint()
      ..color = StageColors.emerald.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(cx, cy - h);
    path.lineTo(cx + h * 0.7, cy);
    path.lineTo(cx - h * 0.7, cy);
    path.close();
    canvas.drawPath(path, paint);

    // Snow cap
    final snowPath = Path();
    snowPath.moveTo(cx, cy - h);
    snowPath.lineTo(cx + h * 0.15, cy - h * 0.75);
    snowPath.lineTo(cx - h * 0.15, cy - h * 0.75);
    snowPath.close();
    canvas.drawPath(snowPath, Paint()..color = Colors.white.withValues(alpha: opacity * 0.5));
  }

  void _drawWaves(Canvas canvas, Size size, double opacity) {
    final paint = Paint()
      ..color = StageColors.blue.withValues(alpha: opacity * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int row = 0; row < 3; row++) {
      final y = size.height - 30 + row * 12.0;
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 30) {
        path.quadraticBezierTo(x + 7.5, y - 5, x + 15, y);
        path.quadraticBezierTo(x + 22.5, y + 5, x + 30, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
