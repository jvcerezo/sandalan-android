import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../investments/screens/investments_screen.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/trends_tab.dart';
import '../widgets/planning_tab.dart';
import '../widgets/health_tab.dart';
import '../widgets/insights_tab.dart';
import '../widgets/net_worth_chart.dart';
import '../widgets/ai_insights_section.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedTab = 0;
  static const _tabLabels = ['Trends', 'Planning', 'Health', 'Insights'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Invalidate providers to force refresh when returning from other screens
    ref.invalidate(transactionsSummaryProvider);
    ref.invalidate(currentMonthTransactionsProvider);
    ref.invalidate(last6MonthsTransactionsProvider);
    ref.invalidate(categoryTotalsProvider);
    ref.invalidate(monthlyTotalsProvider);
    ref.invalidate(monthlyNetTotalsProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(goalsSummaryProvider);
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    ref.invalidate(transactionsSummaryProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(currentMonthTransactionsProvider);
    ref.invalidate(last6MonthsTransactionsProvider);
    ref.invalidate(goalsSummaryProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(budgetsProvider);
    ref.invalidate(categoryTotalsProvider);
    ref.invalidate(netWorthHistoryProvider);
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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

          // ── Hero: Safe to Spend ──────────────────────────────────
          summary.when(
            data: (s) {
              // Safe to spend = income - expenses (this cutoff period)
              final safeToSpend = s.income - s.expenses;
              final now = DateTime.now();
              // Filipino salary cycle: 15th and 30th
              final nextCutoff = now.day <= 15
                  ? DateTime(now.year, now.month, 15)
                  : DateTime(now.year, now.month + 1, 1) .subtract(const Duration(days: 1));
              final daysLeft = nextCutoff.difference(now).inDays + 1;
              final isHealthy = safeToSpend > 0;

              return InkWell(
                onTap: () => context.go('/transactions'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border.all(color: colorScheme.surfaceContainerHighest),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('SAFE TO SPEND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          letterSpacing: 0.8, color: colorScheme.onSurfaceVariant)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isHealthy ? AppColors.income : AppColors.expense).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('$daysLeft day${daysLeft == 1 ? '' : 's'} left',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                color: isHealthy ? AppColors.income : AppColors.expense)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: hideBalances
                          ? Text('••••', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold,
                              color: isHealthy ? colorScheme.primary : AppColors.expense))
                          : AnimatedCurrency(value: safeToSpend.abs(),
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold,
                                  color: isHealthy ? colorScheme.primary : AppColors.expense)),
                    ),
                    if (!isHealthy && !hideBalances)
                      Text('Over budget by ${formatCurrency(safeToSpend.abs())}',
                          style: const TextStyle(fontSize: 12, color: AppColors.expense)),
                    const SizedBox(height: 14),
                    // Income / Expenses / Saved compact row
                    Row(children: [
                      _MiniStat(label: 'Income', value: s.income, color: AppColors.income, hidden: hideBalances),
                      const SizedBox(width: 12),
                      _MiniStat(label: 'Expenses', value: s.expenses, color: AppColors.expense, hidden: hideBalances),
                      const SizedBox(width: 12),
                      _MiniStat(label: 'Saved', value: (s.income - s.expenses).abs(),
                          color: s.income >= s.expenses ? AppColors.income : AppColors.expense, hidden: hideBalances),
                    ]),
                  ]),
                ),
              );
            },
            loading: () => const ShimmerCard(height: 120),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),

          // Tab bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
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
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
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

          // ── AI INSIGHTS ────────────────────────────────────────
          const SizedBox(height: 20),
          const AiInsightsSection(),
        ],
      ),
    );
  }
}

/// A QuickStat-like card without the built-in Expanded wrapper,
/// so the parent can control sizing via its own Expanded.
class _QuickStatContent extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String value;
  final String subtitle;
  const _QuickStatContent({required this.icon, this.label, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          if (label != null) ...[
            const SizedBox(width: 5),
            Text(label!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                letterSpacing: 0.5, color: colorScheme.onSurfaceVariant)),
          ],
        ]),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

/// Compact stat for the hero card (Income / Expenses / Saved).
class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool hidden;
  const _MiniStat({required this.label, required this.value, required this.color, this.hidden = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 2),
      Text(hidden ? '••••' : formatCurrency(value),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ]));
  }
}
