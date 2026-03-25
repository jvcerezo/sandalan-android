import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../../../data/guide/guide_data.dart';

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

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  Set<String> _completedItems = {};
  Set<String> _readGuides = {};
  String? _userLifeStage;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userLifeStage = prefs.getString('life_stage');
        _completedItems = (prefs.getStringList('checklist_done') ?? []).toSet();
        _readGuides = (prefs.getStringList('guides_read') ?? []).toSet();
      });
    }
  }

  String _stageProgress(LifeStage stage) {
    final total = stage.guides.length + stage.checklist.length;
    final done = stage.guides.where((g) => _readGuides.contains(g.slug)).length +
        stage.checklist.where((c) => _completedItems.contains(c.id)).length;
    return '$done/$total';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Compute overall progress from guide data
    int totalItems = 0;
    int completedTotal = 0;
    for (final stage in kLifeStages) {
      totalItems += stage.guides.length + stage.checklist.length;
      completedTotal += stage.guides.where((g) => _readGuides.contains(g.slug)).length;
      completedTotal += stage.checklist.where((c) => _completedItems.contains(c.id)).length;
    }

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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: colorScheme.surfaceContainerHighest),
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
                          Text('$completedTotal/$totalItems completed',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: AnimatedProgressBar(
                        value: totalItems > 0 ? completedTotal / totalItems : 0,
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
          child: _JourneyMap(
            stageProgress: kLifeStages.map((s) => _stageProgress(s)).toList(),
            userLifeStage: _userLifeStage,
          ),
        ),
      ],
    );
  }
}

// ─── Journey Map ───────────────────────────────────────────────────────────────

class _JourneyMap extends StatelessWidget {
  final List<String> stageProgress;
  final String? userLifeStage;
  const _JourneyMap({required this.stageProgress, this.userLifeStage});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                children: [
                  for (int i = 0; i < _stages.length; i++) ...[
                    _JourneyNode(stage: _stages[i], index: i,
                      dynamicProgress: i < stageProgress.length ? stageProgress[i] : null,
                      isUserStage: _stages[i].id == userLifeStage),
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
        ],
      );
    }
  }

// ─── Journey Node (Circle icon + label) ────────────────────────────────────────

class _JourneyNode extends StatelessWidget {
  final _StageData stage;
  final int index;
  final String? dynamicProgress;
  final bool isUserStage;

  const _JourneyNode({required this.stage, required this.index, this.dynamicProgress, this.isUserStage = false});

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
            context.push('/guide/${_stages[index].id}');
          },
          child: SizedBox(
            width: 160,
            child: Column(
              children: [
                // Circle icon with "Your stage" badge
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: isUserStage ? 78 : 72,
                      height: isUserStage ? 78 : 72,
                      decoration: BoxDecoration(
                        color: stage.color,
                        shape: BoxShape.circle,
                        border: isUserStage ? Border.all(color: Colors.white, width: 3) : null,
                        boxShadow: [
                          BoxShadow(
                            color: stage.color.withOpacity(isUserStage ? 0.5 : 0.35),
                            blurRadius: isUserStage ? 20 : 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(stage.icon, size: 30, color: Colors.white),
                    ),
                    if (isUserStage)
                      Positioned(
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: stage.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('You',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                  ],
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
                Text(dynamicProgress ?? stage.progress,
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
        fromColor.withOpacity(0.5),
        toColor.withOpacity(0.5),
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

