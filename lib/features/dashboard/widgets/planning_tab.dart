import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../goals/providers/goal_providers.dart';
import '../../budgets/providers/budget_providers.dart';
import 'dashboard_widgets.dart';

class PlanningTab extends ConsumerWidget {
  const PlanningTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final budgets = ref.watch(budgetsProvider);
    final goals = ref.watch(goalsProvider);
    final transactions = ref.watch(currentMonthTransactionsProvider);

    return Column(children: [
      // Budget Status with Progress Bars
      OverviewCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Budget Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              InkWell(
                onTap: () => context.go('/budgets'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Manage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                    const SizedBox(width: 2),
                    Icon(LucideIcons.arrowRight, size: 12, color: colorScheme.primary),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          budgets.when(
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(height: 8),
                    Text('No budgets set this month.',
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => context.go('/budgets'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Set up budgets', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                          const SizedBox(width: 4),
                          Icon(LucideIcons.arrowRight, size: 14, color: colorScheme.primary),
                        ]),
                      ),
                    ),
                  ]),
                );
              }

              final now = DateTime.now();
              final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
              final txnList = transactions.valueOrNull ?? [];
              final spentByCategory = <String, double>{};
              for (final t in txnList) {
                if (t.amount >= 0 || t.category.toLowerCase() == 'transfer') continue;
                if (t.date.substring(0, 7) == thisMonth) {
                  spentByCategory[t.category] = (spentByCategory[t.category] ?? 0) + t.amount.abs();
                }
              }

              return Column(children: list.map((b) {
                final spent = spentByCategory[b.category] ?? 0;
                final ratio = b.amount > 0 ? spent / b.amount : 0.0;
                final progressColor = ratio > 0.9 ? const Color(0xFFEF4444)
                    : ratio > 0.75 ? const Color(0xFFEAB308)
                    : AppColors.income;
                final isOver = ratio > 1.0;

                return Semantics(
                  label: '${b.category} budget: ${formatCurrency(spent)} spent of ${formatCurrency(b.amount)}${isOver ? ', over budget' : ''}',
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text(b.category, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                        Flexible(
                          child: Text('${formatCurrency(spent)} / ${formatCurrency(b.amount)}',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0, 1).toDouble(),
                          minHeight: 8,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: progressColor,
                        ),
                      ),
                      if (isOver) ...[
                        const SizedBox(height: 4),
                        Text('Over budget by ${formatCurrency(spent - b.amount)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFEF4444))),
                      ],
                    ]),
                  ),
                );
              }).toList());
            },
            loading: () => const ShimmerLoading(height: 40),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // Active Goals
      OverviewCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active Goals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              InkWell(
                onTap: () => context.go('/goals'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Manage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                    const SizedBox(width: 2),
                    Icon(LucideIcons.arrowRight, size: 12, color: colorScheme.primary),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          goals.when(
            data: (list) {
              final active = list.where((g) => !g.isCompleted).toList();
              if (active.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(height: 8),
                    Icon(LucideIcons.target, size: 32, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    Text('No active goals yet', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.go('/goals'),
                      icon: const Icon(LucideIcons.plus, size: 14),
                      label: const Text('New Goal'),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                    ),
                  ]),
                );
              }
              return Column(children: active.map((g) => Semantics(
                label: 'Goal: ${g.name}, ${g.progressPercent.toStringAsFixed(0)} percent complete',
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(child: Text(g.name, style: const TextStyle(fontSize: 13))),
                    Text('${g.progressPercent.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                  ]),
                ),
              )).toList());
            },
            loading: () => const ShimmerLoading(height: 60),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ]),
      ),
    ]);
  }
}
