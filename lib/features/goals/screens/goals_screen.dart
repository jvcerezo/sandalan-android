import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/milestone_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/models/goal.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/milestone_celebration.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../../accounts/providers/account_providers.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Header
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Goals', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              summary.when(
                data: (gs) => Text(
                  gs.total == 0 ? 'Set savings targets and track progress'
                      : '${gs.active} active · ${(gs.overallProgress * 100).toStringAsFixed(0)}% overall',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ])),
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add'),
              onPressed: () => _showAddGoal(context),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
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
          error: (_, __) => _InlineError(onRetry: () => ref.invalidate(goalsSummaryProvider)),
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

class _GoalCard extends ConsumerWidget {
  final Goal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = goal.progressPercent / 100;
    final color = goal.isCompleted ? AppColors.income : colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      // Celebratory border for completed goals
      shape: goal.isCompleted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.income, width: 2),
            )
          : null,
      child: InkWell(
        onLongPress: () => _showDeleteDialog(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Row(children: [
              if (goal.isCompleted) ...[
                Icon(LucideIcons.trophy, size: 16, color: AppColors.income),
                const SizedBox(width: 6),
              ],
              Expanded(child: Text(goal.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(goal.isCompleted ? 'Completed!' : goal.category,
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
            Flexible(
              child: Text('${formatCurrency(goal.currentAmount)} / ${formatCurrency(goal.targetAmount)}',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
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
          // Action buttons
          if (!goal.isCompleted) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddFundsDialog(context, ref),
                  icon: const Icon(LucideIcons.plus, size: 14),
                  label: const Text('Add Funds'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              if (goal.currentAmount > 0) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showReleaseFundsDialog(context, ref),
                  icon: const Icon(LucideIcons.arrowDownLeft, size: 14),
                  label: const Text('Release'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ]),
          ],
        ]),
      ),
      ),
    );
  }

  Future<void> _checkGoalMilestones(BuildContext ctx, WidgetRef ref) async {
    try {
      final goals = await ref.read(goalRepositoryProvider).getGoals();
      final funded = goals.where((g) => g.isCompleted).length;
      final thresholds = {1: 'first_goal_funded', 2: 'goal_2', 3: 'goal_3'};
      for (final entry in thresholds.entries) {
        if (funded >= entry.key) {
          final milestone = await MilestoneService.checkAndTrigger(entry.value);
          if (milestone != null && ctx.mounted) {
            showMilestoneCelebration(ctx, milestone);
            return;
          }
        }
      }
    } catch (_) {}
  }

  void _showAddFundsDialog(BuildContext context, WidgetRef ref) {
    final amountCtl = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    final remaining = goal.targetAmount - goal.currentAmount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Add Funds to ${goal.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Remaining: ${formatCurrency(remaining)}',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              maxLength: 12,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              decoration: InputDecoration(
                prefixText: '₱ ',
                hintText: '0.00',
                labelText: 'Amount',
                counterText: '',
                helperText: goal.accountId != null ? 'Will be deducted from linked account' : null,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtl.text.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid amount')));
                    return;
                  }
                  if (amount > remaining) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Amount exceeds remaining (${formatCurrency(remaining)})')));
                    return;
                  }
                  // Need an account to deduct from
                  final accounts = ref.read(accountsProvider).valueOrNull ?? [];
                  final accountId = goal.accountId ?? (accounts.isNotEmpty ? accounts.first.id : null);
                  if (accountId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No account available to deduct from')));
                    return;
                  }
                  Navigator.pop(context);
                  try {
                    await ref.read(goalRepositoryProvider).addFunds(
                      goalId: goal.id,
                      accountId: accountId,
                      amount: amount,
                    );
                    ref.invalidate(goalsProvider);
                    ref.invalidate(accountsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added ${formatCurrency(amount)} to ${goal.name}')));
                      // Check goal milestones if this funding completes the goal
                      final newAmount = goal.currentAmount + amount;
                      if (newAmount >= goal.targetAmount) {
                        _checkGoalMilestones(context, ref);
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e')));
                    }
                  }
                },
                child: const Text('Add Funds'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete "${goal.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(goalRepositoryProvider).deleteGoal(goal.id);
                ref.invalidate(goalsProvider);
                ref.invalidate(goalsSummaryProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')));
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  void _showReleaseFundsDialog(BuildContext context, WidgetRef ref) {
    final amountCtl = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Release Funds from ${goal.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Available: ${formatCurrency(goal.currentAmount)}',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              maxLength: 12,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              decoration: InputDecoration(
                prefixText: '₱ ',
                hintText: '0.00',
                labelText: 'Amount',
                counterText: '',
                helperText: goal.accountId != null ? 'Will be returned to linked account' : null,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtl.text.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid amount')));
                    return;
                  }
                  if (amount > goal.currentAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Amount exceeds available (${formatCurrency(goal.currentAmount)})')));
                    return;
                  }
                  final accounts = ref.read(accountsProvider).valueOrNull ?? [];
                  final accountId = goal.accountId ?? (accounts.isNotEmpty ? accounts.first.id : null);
                  if (accountId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No account available to return funds to')));
                    return;
                  }
                  Navigator.pop(context);
                  try {
                    await ref.read(goalRepositoryProvider).releaseFunds(
                      goalId: goal.id,
                      accountId: accountId,
                      amount: amount,
                    );
                    ref.invalidate(goalsProvider);
                    ref.invalidate(accountsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Released ${formatCurrency(amount)} from ${goal.name}')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e')));
                    }
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: colorScheme.onSurfaceVariant),
                child: const Text('Release Funds'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final VoidCallback onRetry;
  const _InlineError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: cs.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(LucideIcons.alertCircle, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Text('Could not load data', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const Spacer(),
        GestureDetector(
          onTap: onRetry,
          child: Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
        ),
      ]),
    );
  }
}
