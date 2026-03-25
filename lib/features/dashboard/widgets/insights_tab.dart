import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../budgets/providers/budget_providers.dart';
import 'dashboard_widgets.dart';

class InsightsTab extends ConsumerWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final recentTxns = ref.watch(recentTransactionsProvider);
    final summaryAsync = ref.watch(transactionsSummaryProvider);
    final budgetsAsync = ref.watch(budgetsProvider);

    return recentTxns.when(
      data: (txns) {
        final expenses = txns.where((t) => t.amount < 0).toList();
        final topCategory = expenses.isNotEmpty ? expenses.first.category : 'N/A';
        final totalCount = txns.length;
        final avgAmount = expenses.isNotEmpty
            ? expenses.fold(0.0, (s, t) => s + t.amount.abs()) / expenses.length : 0.0;
        final largestExpense = expenses.isNotEmpty
            ? expenses.map((t) => t.amount.abs()).reduce((a, b) => a > b ? a : b) : 0.0;

        // --- Average Daily Spend ---
        final now = DateTime.now();
        final daysElapsed = now.day;
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final daysRemaining = daysInMonth - daysElapsed;
        final totalExpenses = summaryAsync.valueOrNull?.expenses ?? 0.0;
        final totalBudget = (budgetsAsync.valueOrNull ?? []).fold(0.0, (double s, b) => s + b.amount);
        final avgDailySpend = daysElapsed > 0 ? totalExpenses / daysElapsed : 0.0;
        final dailyBudgetRemaining = daysRemaining > 0 && totalBudget > 0
            ? (totalBudget - totalExpenses) / daysRemaining
            : 0.0;

        // --- Top Merchants (by description) ---
        final merchantTotals = <String, ({double total, int count})>{};
        for (final t in expenses) {
          final payee = t.description.isNotEmpty ? t.description : t.category;
          final existing = merchantTotals[payee];
          merchantTotals[payee] = (
            total: (existing?.total ?? 0) + t.amount.abs(),
            count: (existing?.count ?? 0) + 1,
          );
        }
        final topMerchants = merchantTotals.entries.toList()
          ..sort((a, b) => b.value.total.compareTo(a.value.total));
        final top5Merchants = topMerchants.take(5).toList();

        return Column(children: [
          // This Month's Activity
          OverviewCard(
            child: Semantics(
              label: 'Monthly activity summary: $totalCount transactions, top category $topCategory',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("This Month's Activity",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Top Spending', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    Text(topCategory, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ])),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Total Transactions', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    Text('$totalCount', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ])),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Average Amount', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    Text(formatCurrency(avgAmount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Largest Expense', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    Text(formatCurrency(largestExpense), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Average Daily Spend
          OverviewCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(LucideIcons.calendar, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                const Text('Average Daily Spend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Daily Average', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  Text(formatCurrency(avgDailySpend), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ])),
                if (totalBudget > 0)
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Daily Budget Left', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    Text(formatCurrency(dailyBudgetRemaining < 0 ? 0.0 : dailyBudgetRemaining),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                            color: dailyBudgetRemaining > 0 ? AppColors.income : const Color(0xFFEF4444))),
                  ])),
              ]),
              if (totalBudget > 0 && daysRemaining > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (dailyBudgetRemaining > 0 ? AppColors.income : const Color(0xFFEF4444)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dailyBudgetRemaining > 0
                        ? 'You can spend ~${formatCurrency(dailyBudgetRemaining)}/day to stay on track'
                        : 'You have exceeded your budget for this month',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                        color: dailyBudgetRemaining > 0 ? AppColors.income : const Color(0xFFEF4444)),
                  ),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 12),

          // Top Merchants
          if (top5Merchants.isNotEmpty) ...[
            OverviewCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(LucideIcons.shoppingBag, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  const Text('Top Merchants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                ...top5Merchants.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  return Semantics(
                    label: 'Rank ${i + 1}: ${e.key}, ${e.value.count} transactions, ${formatCurrency(e.value.total)}',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(child: Text('${i + 1}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${e.value.count} transaction${e.value.count == 1 ? '' : 's'}',
                              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                        ])),
                        Text(formatCurrency(e.value.total),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  );
                }),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Recent Transactions
          OverviewCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (txns.isEmpty)
                Center(child: Text('No transactions yet',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)))
              else
                ...txns.map((t) {
                  final isIncome = t.isIncome;
                  final isTransfer = t.isTransfer;
                  final iconColor = isTransfer ? AppColors.transfer : (isIncome ? AppColors.income : colorScheme.onSurfaceVariant);
                  final amountColor = isIncome ? AppColors.income : colorScheme.onSurface;
                  final icon = isTransfer ? LucideIcons.arrowLeftRight
                      : (isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight);
                  final description = t.description.isNotEmpty ? t.description : t.category;
                  return Semantics(
                    label: '${isIncome ? 'Income' : 'Expense'}: $description, ${formatCurrency(t.amount.abs())}, category ${t.category}',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        Container(width: 32, height: 32,
                            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Icon(icon, size: 14, color: iconColor)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(description,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(t.category, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                        ])),
                        Text('${isIncome ? '+' : '-'}${formatCurrency(t.amount.abs())}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: amountColor)),
                      ]),
                    ),
                  );
                }),
            ]),
          ),
        ]);
      },
      loading: () => Column(children: List.generate(2, (_) => const Padding(
        padding: EdgeInsets.only(bottom: 12), child: ShimmerCard(height: 120)))),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
