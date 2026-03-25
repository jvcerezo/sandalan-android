import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/milestone_service.dart';
import '../providers/milestone_providers.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark milestones as viewed
    MilestoneService.markViewed();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final earnedAsync = ref.watch(earnedMilestonesProvider);

    return earnedAsync.when(
      data: (earned) => _buildContent(context, earned, colorScheme),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, String> earned,
    ColorScheme colorScheme,
  ) {
    final allMilestones = MilestoneService.getAllMilestones();
    final earnedCount = earned.length;
    final totalCount = allMilestones.length;

    // Group by category
    final grouped = <MilestoneCategory, List<Milestone>>{};
    for (final m in allMilestones) {
      grouped.putIfAbsent(m.category, () => []).add(m);
    }

    // All categories in display order
    final categoryOrder = [
      MilestoneCategory.financial,
      MilestoneCategory.debtFreedom,
      MilestoneCategory.streaks,
      MilestoneCategory.transactions,
      MilestoneCategory.goalsSavings,
      MilestoneCategory.adultingJourney,
      MilestoneCategory.toolsFeatures,
      MilestoneCategory.special,
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Header — no separate title since shell provides it
        Text(
          '$earnedCount of $totalCount earned',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Category sections
        for (final category in categoryOrder) ...[
          if (grouped.containsKey(category)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Text(
                MilestoneService.categoryName(category),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: grouped[category]!.length,
              itemBuilder: (context, index) {
                final milestone = grouped[category]![index];
                final isEarned = earned.containsKey(milestone.id);
                final earnedDate = isEarned ? earned[milestone.id] : null;

                return _BadgeTile(
                  milestone: milestone,
                  isEarned: isEarned,
                  earnedDate: earnedDate,
                  colorScheme: colorScheme,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Milestone milestone;
  final bool isEarned;
  final String? earnedDate;
  final ColorScheme colorScheme;

  const _BadgeTile({
    required this.milestone,
    required this.isEarned,
    this.earnedDate,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Semantics(
        label:
            '${milestone.title}${isEarned ? ', earned' : ', not yet earned'}',
        child: Container(
          decoration: BoxDecoration(
            color: isEarned
                ? colorScheme.primary.withValues(alpha: 0.08)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: isEarned
                ? null
                : Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    style: BorderStyle.solid,
                  ),
          ),
          child: Opacity(
            opacity: isEarned ? 1.0 : 0.45,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      milestone.icon,
                      size: 32,
                      color: isEarned
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    if (!isEarned)
                      Positioned(
                        right: -4, bottom: -4,
                        child: Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.lock, size: 10,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    milestone.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isEarned
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isEarned && earnedDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(earnedDate!),
                    style: TextStyle(
                      fontSize: 9,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(milestone.icon, size: 36, color: colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                milestone.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (milestone.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  milestone.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (isEarned && earnedDate != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Earned on ${_formatDateFull(earnedDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ] else if (!isEarned) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.lock_outline, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text('Not yet earned', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  ]),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return '';
    }
  }

  String _formatDateFull(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (_) {
      return '';
    }
  }
}
