import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/models/goal.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../providers/goal_providers.dart';
import '../widgets/add_goal_dialog.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final goals = ref.watch(goalsProvider);
    final summary = ref.watch(goalsSummaryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        ref.invalidate(goalsProvider);
        ref.invalidate(goalsSummaryProvider);
        await ref.read(goalsProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Goals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          FilledButton.icon(
            onPressed: () => _showAddGoal(context),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Add'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
        ]),
        const SizedBox(height: 16),

        // Summary cards
        summary.when(
          data: (gs) => Row(children: [
            _StatCard(label: 'Total', value: '${gs.total}', icon: LucideIcons.target),
            const SizedBox(width: 8),
            _StatCard(label: 'Active', value: '${gs.active}', icon: LucideIcons.flame),
            const SizedBox(width: 8),
            _StatCard(label: 'Completed', value: '${gs.completed}', icon: LucideIcons.checkCircle2),
            const SizedBox(width: 8),
            _StatCard(label: 'Progress', value: '${(gs.overallProgress * 100).toStringAsFixed(0)}%',
                icon: LucideIcons.trendingUp),
          ]),
          loading: () => const ShimmerStatRow(count: 4),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),

        // Tabs
        Row(children: [
          _TabButton(label: 'Active', isSelected: !_showCompleted,
              onTap: () => setState(() => _showCompleted = false)),
          const SizedBox(width: 8),
          _TabButton(label: 'Completed', isSelected: _showCompleted,
              onTap: () => setState(() => _showCompleted = true)),
        ]),
        const SizedBox(height: 12),

        // Goals list
        goals.when(
          data: (list) {
            final filtered = list.where((g) => g.isCompleted == _showCompleted).toList();
            if (filtered.isEmpty) {
              return EmptyState(
                icon: _showCompleted ? LucideIcons.checkCircle2 : LucideIcons.target,
                title: _showCompleted ? 'No completed goals yet' : 'No active goals',
                subtitle: _showCompleted ? 'Keep working toward your goals!' : 'Set a goal to start saving.',
              );
            }
            return Column(children: filtered.asMap().entries.map((e) =>
                StaggeredFadeIn(index: e.key, child: _GoalCard(goal: e.value))).toList());
          },
          loading: () => Column(children: List.generate(3, (_) => const ShimmerCard())),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    ),
    );
  }

  void _showAddGoal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddGoalDialog(),
    ).then((_) {
      ref.invalidate(goalsProvider);
      ref.invalidate(goalsSummaryProvider);
    });
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant)),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = goal.progressPercent / 100;
    final color = goal.isCompleted ? AppColors.income : colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(goal.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(goal.category,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
            ),
          ]),
          const SizedBox(height: 8),
          AnimatedProgressBar(
            value: progress,
            minHeight: 6,
            color: color,
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${formatCurrency(goal.currentAmount)} / ${formatCurrency(goal.targetAmount)}',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            Text('${goal.progressPercent.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ]),
          if (goal.deadline != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(LucideIcons.calendar, size: 10, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Due ${formatDate(DateTime.parse(goal.deadline!))}',
                  style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
            ]),
          ],
        ]),
      ),
    );
  }
}
