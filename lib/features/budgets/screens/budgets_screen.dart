import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/budget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/budget_providers.dart';
import '../widgets/add_budget_dialog.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final budgets = ref.watch(budgetsProvider);
    final period = ref.watch(budgetPeriodProvider);
    final month = ref.watch(budgetMonthProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Budgets', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          FilledButton.icon(
            onPressed: () => _showAddBudget(context, ref),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Add'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
        ]),
        const SizedBox(height: 12),

        // Period tabs
        Row(children: [
          _PeriodTab(label: 'Monthly', isSelected: period == 'monthly',
              onTap: () => ref.read(budgetPeriodProvider.notifier).state = 'monthly'),
          const SizedBox(width: 6),
          _PeriodTab(label: 'Weekly', isSelected: period == 'weekly',
              onTap: () => ref.read(budgetPeriodProvider.notifier).state = 'weekly'),
          const SizedBox(width: 6),
          _PeriodTab(label: 'Quarterly', isSelected: period == 'quarterly',
              onTap: () => ref.read(budgetPeriodProvider.notifier).state = 'quarterly'),
        ]),
        const SizedBox(height: 12),

        // Month nav
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            onPressed: () {
              final prev = DateTime(month.year, month.month - 1, 1);
              ref.read(budgetMonthProvider.notifier).state = prev;
            },
            icon: const Icon(LucideIcons.chevronLeft, size: 18),
          ),
          Text(DateFormat('MMMM yyyy').format(month),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          IconButton(
            onPressed: () {
              final next = DateTime(month.year, month.month + 1, 1);
              ref.read(budgetMonthProvider.notifier).state = next;
            },
            icon: const Icon(LucideIcons.chevronRight, size: 18),
          ),
        ]),
        const SizedBox(height: 12),

        // Budget list
        budgets.when(
          data: (list) {
            if (list.isEmpty) {
              return EmptyState(
                icon: LucideIcons.pieChart,
                title: 'No budgets for this period',
                subtitle: 'Create budgets to track your spending by category.',
                action: FilledButton.icon(
                  onPressed: () => _showAddBudget(context, ref),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Add Budget'),
                ),
              );
            }

            final totalBudget = list.fold(0.0, (s, b) => s + b.amount);

            return Column(children: [
              // Summary
              Row(children: [
                _SummaryCard(label: 'Total Budget', value: formatCurrency(totalBudget),
                    color: colorScheme.primary),
              ]),
              const SizedBox(height: 12),
              ...list.map((b) => _BudgetCard(budget: b)),
            ]);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }

  void _showAddBudget(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddBudgetDialog(),
    ).then((_) => ref.invalidate(budgetsProvider));
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _PeriodTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant)),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Simple display — actual spent data requires cross-referencing transactions
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(budget.category,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(formatCurrency(budget.amount),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.primary)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0, // Would be spent/budget ratio
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${formatCurrency(0)} spent',
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
            Text('${formatCurrency(budget.amount)} remaining',
                style: TextStyle(fontSize: 11, color: AppColors.income)),
          ]),
          if (budget.rollover) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(LucideIcons.refreshCw, size: 10, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Rollover enabled',
                  style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
            ]),
          ],
        ]),
      ),
    );
  }
}
