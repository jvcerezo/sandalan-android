import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../accounts/providers/account_providers.dart';
import '../../budgets/providers/budget_providers.dart';
import '../../tools/providers/tool_providers.dart';
import 'dashboard_widgets.dart';
import 'net_worth_chart.dart';

class HealthTab extends ConsumerWidget {
  const HealthTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final summary = ref.watch(transactionsSummaryProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final billsSummary = ref.watch(billsSummaryProvider);
    final debtSummary = ref.watch(debtSummaryProvider);
    final insuranceSummary = ref.watch(insuranceSummaryProvider);
    final budgets = ref.watch(budgetsProvider);
    final transactions = ref.watch(last6MonthsTransactionsProvider);

    return summary.when(
      data: (s) {
        final savingsRate = s.income > 0 ? ((s.income - s.expenses) / s.income * 100) : 0.0;
        final monthlyBills = billsSummary.valueOrNull?.monthlyTotal ?? 0.0;
        final monthlyDebtMin = debtSummary.valueOrNull?.totalMinMonthly ?? 0.0;
        final monthlyInsurance = (insuranceSummary.valueOrNull?.annualPremium ?? 0.0) / 12;
        final monthlyObligations = monthlyBills + monthlyDebtMin + monthlyInsurance;

        // Real budget limits total
        final budgetList_ = budgets.valueOrNull ?? [];
        final budgetLimitsTotal = budgetList_.fold<double>(0.0, (sum, b) => sum + b.amount);

        // Real goal contributions this month
        final txnList_ = transactions.valueOrNull ?? [];
        final now_ = DateTime.now();
        final thisMonth_ = '${now_.year}-${now_.month.toString().padLeft(2, '0')}';
        final goalContributions = txnList_
            .where((t) => t.category.toLowerCase() == 'goal funding' && t.amount < 0 && t.date.substring(0, 7) == thisMonth_)
            .fold<double>(0.0, (sum, t) => sum + t.amount.abs());

        final safeToSpend = s.income - budgetLimitsTotal - goalContributions - monthlyObligations;
        final emergencyMonths = s.expenses > 0 ? totalBalance / (s.expenses > 0 ? s.expenses : 1) : 0.0;

        // --- Compute Real Financial Health Score ---
        final savingsRateScore = s.income > 0
            ? ((savingsRate / 20) * 100).clamp(0.0, 100.0)
            : 0.0;

        double budgetAdherenceScore = 50.0;
        String budgetAdherenceText = 'No budgets set';
        final budgetList = budgets.valueOrNull ?? [];
        final txnList = transactions.valueOrNull ?? [];
        if (budgetList.isNotEmpty) {
          final now = DateTime.now();
          final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
          final expensesByCategory = <String, double>{};
          for (final t in txnList) {
            if (t.amount >= 0 || t.category.toLowerCase() == 'transfer') continue;
            if (t.date.substring(0, 7) == thisMonth) {
              expensesByCategory[t.category] = (expensesByCategory[t.category] ?? 0) + t.amount.abs();
            }
          }
          int underLimit = 0;
          for (final b in budgetList) {
            final spent = expensesByCategory[b.category] ?? 0;
            if (spent <= b.amount) underLimit++;
          }
          budgetAdherenceScore = (underLimit / budgetList.length * 100).clamp(0.0, 100.0);
          budgetAdherenceText = '${underLimit}/${budgetList.length} under limit';
        }

        final emergencyFundScore = (emergencyMonths / 3 * 100).clamp(0.0, 100.0);

        final monthlyDebt = debtSummary.valueOrNull?.totalMinMonthly ?? 0;
        final debtToIncomeScore = s.income > 0
            ? ((1 - monthlyDebt / s.income) * 100).clamp(0.0, 100.0)
            : (monthlyDebt > 0 ? 0.0 : 100.0);

        final healthScore = (savingsRateScore * 0.25 +
            budgetAdherenceScore * 0.25 +
            emergencyFundScore * 0.25 +
            debtToIncomeScore * 0.25).clamp(0.0, 100.0);

        final healthLabel = healthScore >= 91 ? 'Excellent'
            : healthScore >= 71 ? 'Great'
            : healthScore >= 51 ? 'Good'
            : healthScore >= 31 ? 'Fair'
            : 'Needs Work';
        final healthColor = healthScore >= 71 ? AppColors.income
            : healthScore >= 51 ? const Color(0xFFEAB308)
            : healthScore >= 31 ? const Color(0xFFF97316)
            : const Color(0xFFEF4444);

        // --- Spending Velocity ---
        Widget? spendingVelocityWidget;
        if (txnList.isNotEmpty) {
          final now = DateTime.now();
          final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
          final lastMonthDt = DateTime(now.year, now.month - 1);
          final lastMonthStr = '${lastMonthDt.year}-${lastMonthDt.month.toString().padLeft(2, '0')}';
          final dayOfMonth = now.day;

          double thisMonthSpend = 0;
          double lastMonthSpendSamePoint = 0;
          for (final t in txnList) {
            if (t.amount >= 0 || t.category.toLowerCase() == 'transfer') continue;
            final txMonth = t.date.substring(0, 7);
            if (txMonth == thisMonth) {
              thisMonthSpend += t.amount.abs();
            } else if (txMonth == lastMonthStr) {
              final txDay = int.tryParse(t.date.substring(8, 10)) ?? 0;
              if (txDay <= dayOfMonth) {
                lastMonthSpendSamePoint += t.amount.abs();
              }
            }
          }

          if (lastMonthSpendSamePoint > 0) {
            final velocityPct = ((thisMonthSpend - lastMonthSpendSamePoint) / lastMonthSpendSamePoint * 100);
            final isFaster = velocityPct > 0;
            spendingVelocityWidget = OverviewCard(
              child: Semantics(
                label: 'Spending velocity: ${velocityPct.abs().toStringAsFixed(0)} percent ${isFaster ? 'faster' : 'slower'} than last month',
                child: Row(children: [
                  Icon(isFaster ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                      size: 20, color: isFaster ? const Color(0xFFEF4444) : AppColors.income),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Spending Velocity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Spending ${velocityPct.abs().toStringAsFixed(0)}% ${isFaster ? 'faster' : 'slower'} than last month',
                        style: TextStyle(fontSize: 12, color: isFaster ? const Color(0xFFEF4444) : AppColors.income)),
                  ])),
                ]),
              ),
            );
          }
        }

        return Column(children: [
          // Net Worth History Chart
          const NetWorthChart(),
          const SizedBox(height: 12),

          // Financial Health Score
          OverviewCard(
            child: Semantics(
              label: 'Financial health score: ${healthScore.toInt()} out of 100, rated $healthLabel',
              child: Column(children: [
                const Align(alignment: Alignment.centerLeft,
                    child: Text('Financial Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: CustomPaint(
                    size: const Size(120, 100),
                    painter: GaugePainter(value: healthScore, color: healthColor, label: healthLabel),
                  ),
                ),
                const SizedBox(height: 12),
                HealthRow(label: 'Savings Rate', value: '${savingsRate.toStringAsFixed(0)}% of income saved',
                    color: savingsRateScore >= 50 ? AppColors.income : const Color(0xFFF97316), progress: savingsRateScore / 100),
                HealthRow(label: 'Budget Adherence', value: budgetAdherenceText,
                    color: budgetAdherenceScore >= 50 ? AppColors.income : const Color(0xFFF97316), progress: budgetAdherenceScore / 100),
                HealthRow(label: 'Emergency Fund', value: '${emergencyMonths.toStringAsFixed(1)} of 3 months',
                    color: emergencyFundScore >= 50 ? AppColors.income : const Color(0xFFF97316), progress: emergencyFundScore / 100),
                HealthRow(label: 'Debt-to-Income', value: s.income > 0 ? '${(monthlyDebt / s.income * 100).toStringAsFixed(0)}% of income' : 'No income data',
                    color: debtToIncomeScore >= 50 ? AppColors.income : const Color(0xFFF97316), progress: debtToIncomeScore / 100),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Spending Velocity Indicator
          if (spendingVelocityWidget != null) ...[
            spendingVelocityWidget,
            const SizedBox(height: 12),
          ],

          // Safe to Spend
          OverviewCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(LucideIcons.zap, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                const Text('Safe to Spend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 12),
              AnimatedCurrency(value: safeToSpend,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.income)),
              Text('freely available this month',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              BreakdownRow(icon: LucideIcons.landmark, label: 'Monthly Income',
                  value: '+ ${formatCurrency(s.income)}', color: AppColors.income),
              BreakdownRow(icon: LucideIcons.trendingDown, label: 'Budget Limits',
                  value: '- ${formatCurrency(budgetLimitsTotal)}', color: colorScheme.onSurfaceVariant),
              BreakdownRow(icon: LucideIcons.target, label: 'Goal Contributions',
                  value: '- ${formatCurrency(goalContributions)}', color: colorScheme.onSurfaceVariant),
              BreakdownRow(icon: LucideIcons.receipt, label: 'Bills, Debts & More',
                  value: '- ${formatCurrency(monthlyObligations)}', color: colorScheme.onSurfaceVariant),
            ]),
          ),
          const SizedBox(height: 12),

          // Monthly Savings
          OverviewCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Monthly Savings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text('${savingsRate.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.income)),
              Text('of income saved this month',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Row(children: [
                MiniStatLabel(label: 'Income', value: formatCurrency(s.income)),
                const SizedBox(width: 16),
                MiniStatLabel(label: 'Expenses', value: formatCurrency(s.expenses)),
                const SizedBox(width: 16),
                MiniStatLabel(label: 'Saved', value: formatCurrency(s.income - s.expenses), color: AppColors.income),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          // Emergency Fund
          OverviewCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(LucideIcons.shield, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                const Text('Emergency Fund', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${emergencyMonths.toStringAsFixed(1)} of 3 months covered',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                Text('Target: ${formatCurrency(s.expenses * 3)}',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              ]),
              const SizedBox(height: 4),
              AnimatedCurrency(value: totalBalance,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (emergencyMonths / 3).clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: AppColors.income,
                ),
              ),
              const SizedBox(height: 8),
              if (emergencyMonths >= 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.income.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check, size: 14, color: AppColors.income),
                    const SizedBox(width: 4),
                    const Text("You're fully covered for 3 months!",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.income)),
                  ]),
                ),
            ]),
          ),
        ]);
      },
      loading: () => Column(children: List.generate(3, (_) => const Padding(
        padding: EdgeInsets.only(bottom: 12), child: ShimmerCard(height: 120)))),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
