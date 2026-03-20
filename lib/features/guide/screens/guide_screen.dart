import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/color_tokens.dart';

class _StageData {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  const _StageData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const _stages = [
  _StageData(id: 'unang-hakbang', title: 'Unang Hakbang', subtitle: 'Fresh Grad / First Job',
      description: 'Government IDs, first payslip, learning the basics',
      icon: LucideIcons.graduationCap, color: StageColors.blue),
  _StageData(id: 'pundasyon', title: 'Pundasyon', subtitle: 'Building Foundations',
      description: 'Saving, budgeting, building credit',
      icon: LucideIcons.toyBrick, color: StageColors.emerald),
  _StageData(id: 'tahanan', title: 'Tahanan', subtitle: 'Establishing a Home',
      description: 'Renting, buying property, starting a family',
      icon: LucideIcons.home, color: StageColors.violet),
  _StageData(id: 'tugatog', title: 'Tugatog', subtitle: 'Career Peak',
      description: 'Growing wealth, investments, insurance',
      icon: LucideIcons.mountain, color: StageColors.amber),
  _StageData(id: 'paghahanda', title: 'Paghahanda', subtitle: 'Pre-Retirement',
      description: 'Estate planning, retirement preparation',
      icon: LucideIcons.clock, color: StageColors.rose),
  _StageData(id: 'gintong-taon', title: 'Gintong Taon', subtitle: 'Golden Years',
      description: 'Enjoying retirement, legacy planning',
      icon: LucideIcons.gem, color: StageColors.yellow),
];

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Your Adulting Journey',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Level up through every stage of Filipino adult life.',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 20),

        // Overall progress placeholder
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Overall Progress',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text('0% complete · 0 of 6 stages',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 24),

        // Journey map
        ..._buildJourneyMap(context),
      ],
    );
  }

  List<Widget> _buildJourneyMap(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final widgets = <Widget>[];

    for (int i = 0; i < _stages.length; i++) {
      final stage = _stages[i];
      final isLast = i == _stages.length - 1;
      final isLeft = i.isEven;

      widgets.add(
        Row(
          mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: _StageCard(stage: stage, index: i),
            ),
          ],
        ),
      );

      // Connector line
      if (!isLast) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Center(
              child: CustomPaint(
                size: const Size(40, 32),
                painter: _ConnectorPainter(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  goRight: isLeft,
                ),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

class _StageCard extends StatelessWidget {
  final _StageData stage;
  final int index;

  const _StageCard({required this.stage, required this.index});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to stage detail
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: stage.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(stage.icon, size: 24, color: stage.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: stage.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Stage ${index + 1}',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: stage.color)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(stage.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text(stage.subtitle,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(stage.description,
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
            Icon(LucideIcons.chevronRight, size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          ]),
        ),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final Color color;
  final bool goRight;

  _ConnectorPainter({required this.color, required this.goRight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width / 2, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
