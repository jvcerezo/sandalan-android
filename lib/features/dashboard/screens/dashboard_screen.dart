import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../accounts/providers/account_providers.dart';
import '../../goals/providers/goal_providers.dart';
import '../../budgets/providers/budget_providers.dart';
import '../../tools/providers/tool_providers.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/trends_tab.dart';
import '../widgets/planning_tab.dart';
import '../widgets/health_tab.dart';
import '../widgets/insights_tab.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedTab = 0;
  static const _tabLabels = ['Trends', 'Planning', 'Health', 'Insights'];

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    ref.invalidate(transactionsSummaryProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(currentMonthTransactionsProvider);
    ref.invalidate(last6MonthsTransactionsProvider);
    ref.invalidate(goalsSummaryProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(budgetsProvider);
    await ref.read(transactionsSummaryProvider.future);
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0: return const TrendsTab();
      case 1: return const PlanningTab();
      case 2: return const HealthTab();
      case 3: return const InsightsTab();
      default: return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final summary = ref.watch(transactionsSummaryProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final hideBalances = ref.watch(hideBalancesProvider);
    String fc(double v) => hideBalances ? '••••' : formatCurrency(v);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ── Header ──────────────────────────────────────────────
          Row(children: [
            const Expanded(child: Text('Dashboard',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3))),
            Consumer(builder: (context, ref, _) {
              final hidden = ref.watch(hideBalancesProvider);
              return IconButton(
                onPressed: () => ref.read(hideBalancesProvider.notifier).state = !hidden,
                icon: Icon(hidden ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                tooltip: hidden ? 'Show balances' : 'Hide balances',
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
              );
            }),
          ]),
          const SizedBox(height: 2),
          Text('Your finances at a glance',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),

          // ── OVERVIEW ────────────────────────────────────────────
          const SectionLabel('OVERVIEW'),
          const SizedBox(height: 8),

          // ── Section 1: Hero Card — Net Worth + monthly summary ──
          Builder(builder: (_) {
            final debtSummary = ref.watch(debtSummaryProvider);
            final goalsSummary = ref.watch(goalsSummaryProvider);
            final totalDebt = debtSummary.valueOrNull?.totalDebt ?? 0.0;
            final totalGoalSavings = goalsSummary.valueOrNull?.totalSaved ?? 0.0;
            final netWorth = totalBalance + totalGoalSavings - totalDebt;

            return Semantics(
              label: 'Net worth: ${fc(netWorth)}',
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: colorScheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Container(
                    width: 4,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('NET WORTH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            letterSpacing: 0.8, color: colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 6),
                        hideBalances
                            ? Text('••••', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                                color: colorScheme.primary))
                            : AnimatedCurrency(value: netWorth,
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                                    color: colorScheme.primary)),
                        const SizedBox(height: 12),
                        summary.when(
                          data: (s) {
                            final saved = s.income - s.expenses;
                            return Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Income', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                                const SizedBox(height: 2),
                                Row(children: [
                                  Icon(LucideIcons.trendingUp, size: 12, color: AppColors.income),
                                  const SizedBox(width: 3),
                                  Flexible(child: Text(fc(s.income),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.income),
                                      overflow: TextOverflow.ellipsis)),
                                ]),
                              ])),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Expenses', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                                const SizedBox(height: 2),
                                Row(children: [
                                  Icon(LucideIcons.trendingDown, size: 12, color: AppColors.expense),
                                  const SizedBox(width: 3),
                                  Flexible(child: Text(fc(s.expenses),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.expense),
                                      overflow: TextOverflow.ellipsis)),
                                ]),
                              ])),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Saved', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                                const SizedBox(height: 2),
                                Row(children: [
                                  Icon(LucideIcons.piggyBank, size: 12, color: saved >= 0 ? AppColors.income : AppColors.expense),
                                  const SizedBox(width: 3),
                                  Flexible(child: Text(fc(saved.abs()),
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                          color: saved >= 0 ? AppColors.income : AppColors.expense),
                                      overflow: TextOverflow.ellipsis)),
                                ]),
                              ])),
                            ]);
                          },
                          loading: () => const ShimmerLoading(height: 16),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
            );
          }),
          const SizedBox(height: 10),

          // ── Section 2: Quick Stats Row — Accounts, Goals, Debts ──
          Builder(builder: (_) {
            final accounts = ref.watch(accountsProvider);
            final goalsSummary = ref.watch(goalsSummaryProvider);
            final debtSummary = ref.watch(debtSummaryProvider);

            final accountCount = accounts.valueOrNull?.length ?? 0;
            final goalSaved = goalsSummary.valueOrNull?.totalSaved ?? 0.0;
            final activeGoals = goalsSummary.valueOrNull?.active ?? 0;
            final totalDebt = debtSummary.valueOrNull?.totalDebt ?? 0.0;
            final activeDebts = debtSummary.valueOrNull?.activeCount ?? 0;

            return Row(children: [
              QuickStat(icon: LucideIcons.landmark,
                  label: 'Accounts',
                  value: fc(totalBalance),
                  subtitle: '$accountCount account${accountCount == 1 ? '' : 's'}'),
              const SizedBox(width: 8),
              QuickStat(icon: LucideIcons.target,
                  label: 'Goals',
                  value: fc(goalSaved),
                  subtitle: '$activeGoals active'),
              const SizedBox(width: 8),
              QuickStat(icon: LucideIcons.creditCard,
                  label: 'Debts',
                  value: fc(totalDebt),
                  subtitle: '$activeDebts active'),
            ]);
          }),
          const SizedBox(height: 10),

          // ── Section 3: This Month Bar — savings vs expenses ──
          summary.when(
            data: (s) {
              final income = s.income;
              final expenses = s.expenses;
              final saved = income - expenses;
              final savingsRatio = income > 0 ? (saved / income).clamp(0.0, 1.0) : 0.0;
              final expenseRatio = income > 0 ? (expenses / income).clamp(0.0, 1.0) : 0.0;
              final pct = (savingsRatio * 100).toInt();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: colorScheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 10,
                      child: Row(children: [
                        if (expenseRatio > 0)
                          Expanded(
                            flex: (expenseRatio * 100).round().clamp(1, 100),
                            child: Container(color: AppColors.expense),
                          ),
                        if (savingsRatio > 0)
                          Expanded(
                            flex: (savingsRatio * 100).round().clamp(1, 100),
                            child: Container(color: AppColors.income),
                          ),
                        if (income == 0)
                          Expanded(child: Container(color: colorScheme.surfaceContainerHighest)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    income > 0
                        ? (saved >= 0
                            ? 'You saved $pct% of your income this month'
                            : 'You\'ve spent ${fc(expenses)} of ${fc(income)} income')
                        : 'No income recorded this month',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                ]),
              );
            },
            loading: () => const ShimmerCard(height: 50),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          // ── DASHBOARD SECTIONS ──────────────────────────────────
          const SectionLabel('DASHBOARD SECTIONS'),
          const SizedBox(height: 8),

          // Tab bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: List.generate(_tabLabels.length, (i) => Expanded(
                child: Semantics(
                  label: '${_tabLabels[i]} tab',
                  selected: _selectedTab == i,
                  button: true,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTab = i);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == i ? colorScheme.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selectedTab == i ? [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                        ] : null,
                      ),
                      child: Center(
                        child: Text(_tabLabels[i],
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                color: _selectedTab == i ? colorScheme.onSurface : colorScheme.onSurfaceVariant)),
                      ),
                    ),
                  ),
                ),
              )),
            ),
          ),
          const SizedBox(height: 10),

          // Helper text
          if (_selectedTab == 0) ...[
            Row(children: [
              Icon(LucideIcons.cornerDownRight, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('Trends selected \u2014 choose a trend view below',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 14),
          ] else ...[
            const SizedBox(height: 6),
          ],

          // Tab content — lazy: only builds the active tab
          _buildTabContent(),

          // Bottom padding so FAB doesn't cover content
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
