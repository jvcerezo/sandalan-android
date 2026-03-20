import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../accounts/providers/account_providers.dart';
import '../../goals/providers/goal_providers.dart';
import '../../budgets/providers/budget_providers.dart';
import '../../tools/providers/tool_providers.dart';
import '../../../data/models/transaction.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedTab = 0;
  int _trendView = 0;
  static const _tabLabels = ['Trends', 'Planning', 'Health', 'Insights'];

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    ref.invalidate(transactionsSummaryProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(goalsSummaryProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(budgetsProvider);
    await ref.read(transactionsSummaryProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final summary = ref.watch(transactionsSummaryProvider);
    final totalBalance = ref.watch(totalBalanceProvider);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ─── Header ──────────────────────────────────────────────
          const Text('Dashboard',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text('Your finances at a glance',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),

          // ─── OVERVIEW ────────────────────────────────────────────
          _SectionLabel('OVERVIEW'),
          const SizedBox(height: 8),

          // Total Balance
          _OverviewCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('TOTAL BALANCE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        letterSpacing: 0.8, color: colorScheme.onSurfaceVariant)),
                Icon(LucideIcons.landmark, size: 18, color: colorScheme.onSurfaceVariant),
              ]),
              const SizedBox(height: 12),
              AnimatedCurrency(value: totalBalance,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 12),

          // Income / Expenses
          summary.when(
            data: (s) => Row(children: [
              Expanded(child: _OverviewCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('INCOME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        letterSpacing: 0.8, color: colorScheme.onSurfaceVariant)),
                    Icon(LucideIcons.trendingUp, size: 16, color: AppColors.income),
                  ]),
                  const SizedBox(height: 8),
                  AnimatedCurrency(value: s.income,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.income)),
                ]),
              )),
              const SizedBox(width: 8),
              Expanded(child: _OverviewCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('EXPENSES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        letterSpacing: 0.8, color: colorScheme.onSurfaceVariant)),
                    Icon(LucideIcons.trendingDown, size: 16, color: colorScheme.onSurfaceVariant),
                  ]),
                  const SizedBox(height: 8),
                  AnimatedCurrency(value: s.expenses,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
              )),
            ]),
            loading: () => const ShimmerStatRow(count: 2),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),

          // Accounts / Goals / Budgets row
          Row(children: [
            _MiniStat(icon: LucideIcons.landmark, label: 'ACCOUNTS',
                value: formatCurrency(totalBalance)),
            const SizedBox(width: 6),
            _MiniStat(icon: LucideIcons.target, label: 'GOALS',
                value: ref.watch(goalsSummaryProvider).valueOrNull != null
                    ? formatCurrency(ref.watch(goalsSummaryProvider).value!.totalSaved)
                    : '₱0.00'),
            const SizedBox(width: 6),
            _MiniStat(icon: LucideIcons.coins, label: 'BUDGETS',
                value: ref.watch(budgetsProvider).valueOrNull != null
                    ? formatCurrency(ref.watch(budgetsProvider).value!.fold(0.0, (s, b) => s + b.amount))
                    : '₱0.00'),
          ]),
          const SizedBox(height: 20),

          // ─── DASHBOARD SECTIONS ──────────────────────────────────
          _SectionLabel('DASHBOARD SECTIONS'),
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
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedTab = i);
                  },
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
              )),
            ),
          ),
          const SizedBox(height: 10),

          // Helper text
          if (_selectedTab == 0) ...[
            Row(children: [
              Icon(LucideIcons.cornerDownRight, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('Trends selected — choose a trend view below',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 14),
          ] else ...[
            const SizedBox(height: 6),
          ],

          // Tab content
          if (_selectedTab == 0) _TrendsTab(ref: ref, trendView: _trendView,
              onTrendViewChanged: (v) => setState(() => _trendView = v)),
          if (_selectedTab == 1) _PlanningTab(ref: ref),
          if (_selectedTab == 2) _HealthTab(ref: ref),
          if (_selectedTab == 3) _InsightsTab(ref: ref),

          // Bottom padding so FAB doesn't cover content
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─── Trends Tab ────────────────────────────────────────────────────────────────

class _TrendsTab extends StatelessWidget {
  final WidgetRef ref;
  final int trendView;
  final ValueChanged<int> onTrendViewChanged;
  static const _views = ['Spending', 'Monthly', 'Net Worth', 'Compare'];

  const _TrendsTab({required this.ref, required this.trendView, required this.onTrendViewChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final transactions = ref.watch(transactionsProvider);

    return Column(children: [
      _SectionLabel('TREND VIEWS'),
      const SizedBox(height: 8),
      // Sub-tabs — use Material InkWell for reliable tapping
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: List.generate(_views.length, (i) => Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onTrendViewChanged(i);
              },
              borderRadius: BorderRadius.circular(7),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: trendView == i ? colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: trendView == i ? [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                  ] : null,
                ),
                child: Center(child: Text(_views[i],
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: trendView == i ? colorScheme.onSurface : colorScheme.onSurfaceVariant))),
              ),
            ),
          ),
        ))),
      ),
      const SizedBox(height: 12),

      // View content based on selected trend view
      if (trendView == 0) _buildSpendingView(context, transactions),
      if (trendView == 1) _buildMonthlyView(context, transactions),
      if (trendView == 2) _buildNetWorthView(context),
      if (trendView == 3) _buildCompareView(context),
    ]);
  }

  Widget _buildSpendingView(BuildContext context, AsyncValue<List<Transaction>> transactions) {
    final chartColors = [
      const Color(0xFFEF4444), const Color(0xFFF97316), const Color(0xFFEAB308),
      const Color(0xFF22C55E), const Color(0xFF3B82F6), const Color(0xFF8B5CF6),
      const Color(0xFFEC4899), const Color(0xFF14B8A6),
    ];

    return _OverviewCard(
      child: transactions.when(
        data: (txns) {
          final expenses = txns.where((t) => t.amount < 0 && t.category.toLowerCase() != 'transfer').toList();
          if (expenses.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No spending data yet', style: TextStyle(fontSize: 13))),
            );
          }
          final categoryTotals = <String, double>{};
          for (final t in expenses) {
            categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount.abs();
          }
          final sorted = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final total = sorted.fold(0.0, (s, e) => s + e.value);

          return Column(children: [
            const Align(alignment: Alignment.centerLeft,
                child: Text('Spending by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            const SizedBox(height: 16),
            SizedBox(height: 180, child: CustomPaint(size: const Size(180, 180),
                painter: _DonutChartPainter(
                  values: sorted.map((e) => e.value).toList(),
                  colors: List.generate(sorted.length, (i) => chartColors[i % chartColors.length])))),
            const SizedBox(height: 16),
            ...sorted.asMap().entries.map((entry) {
              final i = entry.key; final e = entry.value;
              final pct = (e.value / total * 100).toStringAsFixed(1);
              return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: chartColors[i % chartColors.length], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(formatCurrency(e.value), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('$pct%', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ]),
              ]));
            }),
          ]);
        },
        loading: () => const ShimmerCard(height: 200),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildMonthlyView(BuildContext context, AsyncValue<List<Transaction>> transactions) {
    return _OverviewCard(
      child: transactions.when(
        data: (txns) {
          // Group transactions by month
          final monthlyData = <String, ({double income, double expenses})>{};
          for (final t in txns) {
            if (t.category.toLowerCase() == 'transfer') continue;
            final month = t.date.substring(0, 7); // YYYY-MM
            final existing = monthlyData[month] ?? (income: 0.0, expenses: 0.0);
            monthlyData[month] = t.amount > 0
                ? (income: existing.income + t.amount, expenses: existing.expenses)
                : (income: existing.income, expenses: existing.expenses + t.amount.abs());
          }
          final sorted = monthlyData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
          final last6 = sorted.length > 6 ? sorted.sublist(sorted.length - 6) : sorted;

          if (last6.isEmpty) {
            return const Padding(padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No data yet', style: TextStyle(fontSize: 13))));
          }

          final maxVal = last6.fold(0.0, (m, e) =>
              math.max(m, math.max(e.value.income, e.value.expenses)));

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Monthly Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CustomPaint(
                size: const Size(double.infinity, 200),
                painter: _BarChartPainter(
                  months: last6.map((e) => _formatMonth(e.key)).toList(),
                  incomes: last6.map((e) => e.value.income).toList(),
                  expenses: last6.map((e) => e.value.expenses).toList(),
                  maxValue: maxVal,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _LegendDot(color: Colors.grey.shade400, label: 'Expenses'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.income, label: 'Income'),
              const SizedBox(width: 16),
              Row(children: [
                Icon(LucideIcons.arrowRight, size: 10, color: AppColors.info),
                const SizedBox(width: 4),
                Text('Net', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            ]),
          ]);
        },
        loading: () => const ShimmerCard(height: 200),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildNetWorthView(BuildContext context) {
    final summary = ref.watch(transactionsSummaryProvider);
    return _OverviewCard(
      child: summary.when(
        data: (s) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Net Worth Over Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _LineChartPainter(
                value: s.balance,
                color: AppColors.income,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
        ]),
        loading: () => const ShimmerCard(height: 200),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCompareView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final transactions = ref.watch(transactionsProvider);

    return _OverviewCard(
      child: transactions.when(
        data: (txns) {
          final now = DateTime.now();
          final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
          final lastMonth = DateTime(now.year, now.month - 1);
          final lastMonthStr = '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';

          final thisMonthTotals = <String, double>{};
          final lastMonthTotals = <String, double>{};
          for (final t in txns) {
            if (t.amount >= 0) continue;
            final month = t.date.substring(0, 7);
            if (month == thisMonth) {
              thisMonthTotals[t.category] = (thisMonthTotals[t.category] ?? 0) + t.amount.abs();
            } else if (month == lastMonthStr) {
              lastMonthTotals[t.category] = (lastMonthTotals[t.category] ?? 0) + t.amount.abs();
            }
          }

          final allCategories = {...thisMonthTotals.keys, ...lastMonthTotals.keys}.toList()..sort();

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Spending: This vs Last Month',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Expanded(flex: 3, child: Text('CATEGORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5))),
                Expanded(flex: 2, child: Text('THIS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5), textAlign: TextAlign.right)),
                Expanded(flex: 2, child: Text('LAST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5), textAlign: TextAlign.right)),
                const Expanded(flex: 2, child: Text('Δ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              ]),
            ),
            if (allCategories.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No spending data', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant))))
            else
              ...allCategories.map((cat) {
                final thisVal = thisMonthTotals[cat] ?? 0;
                final lastVal = lastMonthTotals[cat] ?? 0;
                final delta = lastVal > 0 ? ((thisVal - lastVal) / lastVal * 100) : (thisVal > 0 ? 100 : 0);
                final deltaColor = delta > 0 ? AppColors.expense : AppColors.income;

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.08))),
                  ),
                  child: Row(children: [
                    Expanded(flex: 3, child: Text(cat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                    Expanded(flex: 2, child: Text(formatCurrency(thisVal), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text(formatCurrency(lastVal),
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text(
                        '${delta > 0 ? '↑' : delta < 0 ? '↓' : '—'} ${delta.abs().toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: deltaColor),
                        textAlign: TextAlign.right)),
                  ]),
                );
              }),
          ]);
        },
        loading: () => const ShimmerCard(height: 200),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  String _formatMonth(String ym) {
    final parts = ym.split('-');
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final y = parts[0].substring(2);
    final m = int.parse(parts[1]);
    return "${months[m]} '$y";
  }
}

// ─── Planning Tab ──────────────────────────────────────────────────────────────

class _PlanningTab extends StatelessWidget {
  final WidgetRef ref;
  const _PlanningTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final budgets = ref.watch(budgetsProvider);
    final goals = ref.watch(goalsProvider);

    return Column(children: [
      // Budget Status
      _OverviewCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Budget Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          budgets.when(
            data: (list) => list.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(height: 8),
                      Text('No budgets set this month.',
                          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => context.go('/budgets'),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Set up budgets', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                          const SizedBox(width: 4),
                          Icon(LucideIcons.arrowRight, size: 14, color: colorScheme.primary),
                        ]),
                      ),
                    ]),
                  )
                : Column(children: list.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(b.category, style: const TextStyle(fontSize: 13)),
                      Text(formatCurrency(b.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  )).toList()),
            loading: () => const ShimmerLoading(height: 40),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // Active Goals
      _OverviewCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Active Goals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
              return Column(children: active.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Text(g.name, style: const TextStyle(fontSize: 13))),
                  Text('${g.progressPercent.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                ]),
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

// ─── Health Tab ────────────────────────────────────────────────────────────────

class _HealthTab extends StatelessWidget {
  final WidgetRef ref;
  const _HealthTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final summary = ref.watch(transactionsSummaryProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final billsSummary = ref.watch(billsSummaryProvider);
    final debtSummary = ref.watch(debtSummaryProvider);

    return summary.when(
      data: (s) {
        final savingsRate = s.income > 0 ? ((s.income - s.expenses) / s.income * 100) : 0.0;
        final monthlyObligations = (billsSummary.valueOrNull?.monthlyTotal ?? 0) +
            (debtSummary.valueOrNull?.totalMinMonthly ?? 0);
        final safeToSpend = s.income - s.expenses;
        final emergencyMonths = s.expenses > 0 ? totalBalance / (s.expenses > 0 ? s.expenses : 1) : 0.0;

        return Column(children: [
          // Financial Health Score
          _OverviewCard(
            child: Column(children: [
              const Align(alignment: Alignment.centerLeft,
                  child: Text('Financial Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
              const SizedBox(height: 16),
              // Score gauge
              SizedBox(
                height: 100,
                child: CustomPaint(
                  size: const Size(120, 100),
                  painter: _GaugePainter(value: 50, color: AppColors.warning),
                ),
              ),
              const SizedBox(height: 12),
              // Metrics
              _HealthRow(label: 'Savings Rate', value: '${savingsRate.toStringAsFixed(0)}% of income saved',
                  color: AppColors.income, progress: savingsRate / 100),
              _HealthRow(label: 'Budget Adherence', value: 'No budgets set',
                  color: colorScheme.onSurfaceVariant, progress: 0),
              _HealthRow(label: 'Goal Progress', value: 'No active goals',
                  color: colorScheme.onSurfaceVariant, progress: 0),
              _HealthRow(label: 'Emergency Fund', value: '${formatCurrency(totalBalance)} in accounts',
                  color: AppColors.income, progress: (emergencyMonths / 3).clamp(0, 1)),
            ]),
          ),
          const SizedBox(height: 12),

          // Safe to Spend
          _OverviewCard(
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
              // Breakdown
              _BreakdownRow(icon: LucideIcons.landmark, label: 'Monthly Income',
                  value: '+ ${formatCurrency(s.income)}', color: AppColors.income),
              _BreakdownRow(icon: LucideIcons.trendingDown, label: 'Budget Limits',
                  value: '- ${formatCurrency(0)}', color: colorScheme.onSurfaceVariant),
              _BreakdownRow(icon: LucideIcons.target, label: 'Goal Contributions',
                  value: '- ${formatCurrency(0)}', color: colorScheme.onSurfaceVariant),
              _BreakdownRow(icon: LucideIcons.receipt, label: 'Bills, Debts & More',
                  value: '- ${formatCurrency(monthlyObligations)}', color: colorScheme.onSurfaceVariant),
            ]),
          ),
          const SizedBox(height: 12),

          // Monthly Savings
          _OverviewCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Monthly Savings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text('${savingsRate.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.income)),
              Text('of income saved this month',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Row(children: [
                _MiniStatLabel(label: 'Income', value: formatCurrency(s.income)),
                const SizedBox(width: 16),
                _MiniStatLabel(label: 'Expenses', value: formatCurrency(s.expenses)),
                const SizedBox(width: 16),
                _MiniStatLabel(label: 'Saved', value: formatCurrency(s.income - s.expenses), color: AppColors.income),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          // Emergency Fund
          _OverviewCard(
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
                    color: AppColors.income.withValues(alpha: 0.1),
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

// ─── Insights Tab ──────────────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final WidgetRef ref;
  const _InsightsTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final recentTxns = ref.watch(recentTransactionsProvider);

    return recentTxns.when(
      data: (txns) {
        final expenses = txns.where((t) => t.amount < 0).toList();
        final topCategory = expenses.isNotEmpty ? expenses.first.category : 'N/A';
        final totalCount = txns.length;
        final avgAmount = expenses.isNotEmpty
            ? expenses.fold(0.0, (s, t) => s + t.amount.abs()) / expenses.length : 0.0;
        final largestExpense = expenses.isNotEmpty
            ? expenses.map((t) => t.amount.abs()).reduce((a, b) => a > b ? a : b) : 0.0;

        return Column(children: [
          // This Month's Activity
          _OverviewCard(
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
                  Text(formatCurrency(avgAmount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ])),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Largest Expense', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  Text(formatCurrency(largestExpense), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ])),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          // Recent Transactions
          _OverviewCard(
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Container(width: 32, height: 32,
                          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Icon(icon, size: 14, color: iconColor)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t.description.isNotEmpty ? t.description : t.category,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(t.category, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                      ])),
                      Text('${isIncome ? '+' : '-'}${formatCurrency(t.amount.abs())}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: amountColor)),
                    ]),
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

// ─── Shared Widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
        letterSpacing: 0.8, color: Theme.of(context).colorScheme.onSurfaceVariant));
  }
}

class _OverviewCard extends StatelessWidget {
  final Widget child;
  const _OverviewCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MiniStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.10)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 11, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                letterSpacing: 0.5, color: colorScheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _MiniStatLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _MiniStatLabel({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double progress;
  const _HealthRow({required this.label, required this.value, required this.color, required this.progress});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.primary)),
          Text(value, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 4,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: color,
          ),
        ),
      ]),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _BreakdownRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }
}

// ─── Donut Chart Painter ───────────────────────────────────────────────────────

class _DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (s, v) => s + v);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final strokeWidth = radius * 0.35;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle, sweep, false, paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Gauge Painter ─────────────────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  final double value; // 0-100
  final Color color;

  _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.8);
    final radius = size.width / 2 - 12;

    // Background arc
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, math.pi, false, bgPaint,
    );

    // Value arc
    final valPaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, math.pi * (value / 100), false, valPaint,
    );

    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${value.toInt()}',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height - 4));

    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'Fair',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, Offset(center.dx - labelPainter.width / 2, center.dy - 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Bar Chart Painter (Monthly Trend) ─────────────────────────────────────────

class _BarChartPainter extends CustomPainter {
  final List<String> months;
  final List<double> incomes;
  final List<double> expenses;
  final double maxValue;
  final bool isDark;

  _BarChartPainter({
    required this.months,
    required this.incomes,
    required this.expenses,
    required this.maxValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty || maxValue == 0) return;

    final leftPad = 45.0;
    final bottomPad = 24.0;
    final chartW = size.width - leftPad - 20;
    final chartH = size.height - bottomPad - 8;
    final barGroupWidth = chartW / months.length;
    final barWidth = barGroupWidth * 0.25;

    final gridColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);
    final labelStyle = TextStyle(fontSize: 9, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4));

    // Y-axis grid lines + labels
    for (int i = 0; i <= 4; i++) {
      final y = 8 + chartH * (1 - i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - 20, y), Paint()..color = gridColor);
      final val = (maxValue * i / 4);
      final label = val >= 1000 ? '${(val / 1000).toStringAsFixed(0)}K' : val.toStringAsFixed(0);
      final tp = TextPainter(text: TextSpan(text: label, style: labelStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    // Bars + X labels
    for (int i = 0; i < months.length; i++) {
      final cx = leftPad + barGroupWidth * i + barGroupWidth / 2;

      // Expense bar (grey)
      final expH = (expenses[i] / maxValue) * chartH;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - barWidth - 1, 8 + chartH - expH, barWidth, expH), const Radius.circular(2)),
        Paint()..color = isDark ? Colors.grey.shade600 : Colors.grey.shade300,
      );

      // Income bar (green)
      final incH = (incomes[i] / maxValue) * chartH;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx + 1, 8 + chartH - incH, barWidth, incH), const Radius.circular(2)),
        Paint()..color = AppColors.income,
      );

      // X label
      final tp = TextPainter(text: TextSpan(text: months[i], style: labelStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, size.height - bottomPad + 6));
    }

    // Net line
    final linePaint = Paint()
      ..color = AppColors.info
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final linePath = Path();
    for (int i = 0; i < months.length; i++) {
      final cx = leftPad + barGroupWidth * i + barGroupWidth / 2;
      final net = incomes[i] - expenses[i];
      final y = 8 + chartH * (1 - net / maxValue).clamp(0, 1);
      if (i == 0) linePath.moveTo(cx, y); else linePath.lineTo(cx, y);
    }
    canvas.drawPath(linePath, linePaint);

    // Net dots
    for (int i = 0; i < months.length; i++) {
      final cx = leftPad + barGroupWidth * i + barGroupWidth / 2;
      final net = incomes[i] - expenses[i];
      final y = 8 + chartH * (1 - net / maxValue).clamp(0, 1);
      canvas.drawCircle(Offset(cx, y), 3, Paint()..color = AppColors.info);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Line Chart Painter (Net Worth) ────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  final double value;
  final Color color;
  final bool isDark;

  _LineChartPainter({required this.value, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final leftPad = 50.0;
    final bottomPad = 24.0;
    final chartW = size.width - leftPad - 20;
    final chartH = size.height - bottomPad - 8;

    final gridColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);
    final labelStyle = TextStyle(fontSize: 9, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4));

    // Y-axis
    for (int i = 0; i <= 4; i++) {
      final y = 8 + chartH * (1 - i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - 20, y), Paint()..color = gridColor);
      final val = value * i / 4;
      final label = val >= 1000 ? '₱${(val / 1000).toStringAsFixed(0)}K' : '₱${val.toStringAsFixed(0)}';
      final tp = TextPainter(text: TextSpan(text: label, style: labelStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    // Simulated growth line (flat then sharp rise to current value)
    final months = ["May '25", "Aug '25", "Nov '25", 'Jan', 'Mar'];
    final values = [0.0, 0.0, 0.0, value * 0.3, value];

    final linePaint = Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();

    for (int i = 0; i < months.length; i++) {
      final x = leftPad + chartW * i / (months.length - 1);
      final y = 8 + chartH * (1 - values[i] / value).clamp(0, 1);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);

      // X label
      final tp = TextPainter(text: TextSpan(text: months[i], style: labelStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - bottomPad + 6));
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Legend Dot ────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}
