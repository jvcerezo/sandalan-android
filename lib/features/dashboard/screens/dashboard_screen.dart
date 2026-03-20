import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
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

          // Total Balance & Net Worth
          Row(children: [
            Expanded(
              child: _OverviewCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('TOTAL BALANCE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            letterSpacing: 0.8, color: colorScheme.onSurfaceVariant)),
                    Icon(LucideIcons.landmark, size: 18, color: colorScheme.onSurfaceVariant),
                  ]),
                  const SizedBox(height: 12),
                  AnimatedCurrency(value: totalBalance,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Builder(builder: (_) {
                // Net worth = total assets (accounts) - total liabilities (debts)
                final debtSummary = ref.watch(debtSummaryProvider);
                final totalDebt = debtSummary.valueOrNull?.totalDebt ?? 0.0;
                final netWorth = totalBalance - totalDebt;
                return _OverviewCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('NET WORTH',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              letterSpacing: 0.8, color: colorScheme.onSurfaceVariant)),
                      Icon(netWorth >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                          size: 18, color: netWorth >= 0 ? AppColors.income : AppColors.expense),
                    ]),
                    const SizedBox(height: 12),
                    AnimatedCurrency(value: netWorth,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                            color: netWorth >= 0 ? AppColors.income : AppColors.expense)),
                  ]),
                );
              }),
            ),
          ]),
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
                child: Text('Spending This Month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: sorted.asMap().entries.map((entry) {
                    final i = entry.key;
                    final e = entry.value;
                    final pct = (e.value / total * 100);
                    return PieChartSectionData(
                      color: chartColors[i % chartColors.length],
                      value: e.value,
                      title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      radius: 45,
                    );
                  }).toList(),
                  centerSpaceColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
            // Center text overlay
            Transform.translate(
              offset: const Offset(0, -120),
              child: SizedBox(
                height: 0,
                child: OverflowBox(
                  maxHeight: 40,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(formatCurrency(total),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('Total', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 8),
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
          // Build last 6 months list (always show 6 months even without data)
          final now = DateTime.now();
          final last6Months = List.generate(6, (i) {
            final d = DateTime(now.year, now.month - 5 + i);
            return '${d.year}-${d.month.toString().padLeft(2, '0')}';
          });

          // Group transactions by month
          final monthlyData = <String, ({double income, double expenses})>{};
          for (final t in txns) {
            if (t.category.toLowerCase() == 'transfer') continue;
            final month = t.date.substring(0, 7);
            final existing = monthlyData[month] ?? (income: 0.0, expenses: 0.0);
            monthlyData[month] = t.amount > 0
                ? (income: existing.income + t.amount, expenses: existing.expenses)
                : (income: existing.income, expenses: existing.expenses + t.amount.abs());
          }

          final incomes = last6Months.map((m) => monthlyData[m]?.income ?? 0.0).toList();
          final expenses = last6Months.map((m) => monthlyData[m]?.expenses ?? 0.0).toList();
          final nets = List.generate(6, (i) => incomes[i] - expenses[i]);
          final maxVal = [...incomes, ...expenses].fold(0.0, (a, b) => math.max(a, b));
          final allNets = [...nets, 0.0];
          final minNet = allNets.reduce(math.min);
          final maxNet = allNets.reduce(math.max);

          if (maxVal == 0) {
            return const Padding(padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No data yet', style: TextStyle(fontSize: 13))));
          }

          final colorScheme = Theme.of(context).colorScheme;

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Monthly Income & Expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.25,
                  barTouchData: BarTouchData(
                    enabled: false,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBorderRadius: BorderRadius.circular(6),
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      getTooltipColor: (_) => Colors.transparent,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final value = rodIndex == 0 ? incomes[groupIndex] : expenses[groupIndex];
                        if (value == 0) return null;
                        return BarTooltipItem(
                          _formatCompactCurrency(value),
                          TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                              color: rodIndex == 0 ? AppColors.income : Colors.grey.shade500),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= last6Months.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_formatMonth(last6Months[idx]),
                                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min) return const SizedBox.shrink();
                          String label;
                          if (value >= 1000000) {
                            label = '${(value / 1000000).toStringAsFixed(1)}M';
                          } else if (value >= 1000) {
                            label = '${(value / 1000).toStringAsFixed(0)}K';
                          } else {
                            label = value.toStringAsFixed(0);
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text('\u20B1$label',
                                style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
                                textAlign: TextAlign.right),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outline.withValues(alpha: 0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(6, (i) => BarChartGroupData(
                    x: i,
                    showingTooltipIndicators: [
                      if (incomes[i] > 0) 0,
                      if (expenses[i] > 0) 1,
                    ],
                    barRods: [
                      BarChartRodData(
                        toY: incomes[i],
                        color: AppColors.income,
                        width: 14,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3), topRight: Radius.circular(3)),
                      ),
                      BarChartRodData(
                        toY: expenses[i],
                        color: Colors.grey.shade400,
                        width: 14,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3), topRight: Radius.circular(3)),
                      ),
                    ],
                  )),
                  extraLinesData: ExtraLinesData(
                    extraLinesOnTop: true,
                  ),
                ),
              ),
            ),
            // Net line as a separate small LineChart overlay description
            if (nets.any((n) => n != 0)) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: LineChart(
                  LineChartData(
                    minY: minNet < 0 ? minNet * 1.2 : 0,
                    maxY: maxNet > 0 ? maxNet * 1.2 : 1,
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(6, (i) => FlSpot(i.toDouble(), nets[i])),
                        isCurved: true,
                        color: AppColors.info,
                        barWidth: 2,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(radius: 3, color: AppColors.info, strokeWidth: 0),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.info.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 46,
                          getTitlesWidget: (value, meta) {
                            if (value == meta.max || value == meta.min) return const SizedBox.shrink();
                            String label;
                            final absVal = value.abs();
                            if (absVal >= 1000000) {
                              label = '${(value / 1000000).toStringAsFixed(1)}M';
                            } else if (absVal >= 1000) {
                              label = '${(value / 1000).toStringAsFixed(0)}K';
                            } else {
                              label = value.toStringAsFixed(0);
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text('\u20B1$label',
                                  style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
                                  textAlign: TextAlign.right),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBorderRadius: BorderRadius.circular(8),
                        getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                          return LineTooltipItem(
                            'Net: ${formatCurrency(spot.y)}',
                            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.info),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _LegendDot(color: AppColors.income, label: 'Income'),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.grey.shade400, label: 'Expenses'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.info, label: 'Net'),
            ]),
          ]);
        },
        loading: () => const ShimmerCard(height: 200),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildNetWorthView(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return _OverviewCard(
      child: transactions.when(
        data: (txns) {
          // Build cumulative net worth over last 6 months
          final now = DateTime.now();
          final last6Months = List.generate(6, (i) {
            final d = DateTime(now.year, now.month - 5 + i);
            return '${d.year}-${d.month.toString().padLeft(2, '0')}';
          });

          // Calculate running balance per month
          final monthlyNet = <String, double>{};
          for (final t in txns) {
            if (t.category.toLowerCase() == 'transfer') continue;
            final month = t.date.substring(0, 7);
            monthlyNet[month] = (monthlyNet[month] ?? 0) + t.amount;
          }

          // Build cumulative values - work backwards from totalBalance
          double cumulative = totalBalance;
          final cumulativeValues = <double>[];
          // First pass: compute net per month for last 6 months
          final netsForMonths = last6Months.map((m) => monthlyNet[m] ?? 0.0).toList();
          // Work backwards from current balance
          for (int i = 5; i >= 0; i--) {
            cumulativeValues.insert(0, cumulative);
            if (i > 0) cumulative -= netsForMonths[i];
          }

          final currentValue = cumulativeValues.last;
          final minVal = cumulativeValues.reduce(math.min);
          final maxVal = cumulativeValues.reduce(math.max);
          final range = maxVal - minVal;

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Net Worth Over Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatCurrency(currentValue),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.income)),
                Text('Current', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
              ]),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: range > 0 ? minVal - range * 0.1 : 0,
                  maxY: range > 0 ? maxVal + range * 0.1 : maxVal * 1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(6, (i) => FlSpot(i.toDouble(), cumulativeValues[i])),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: AppColors.income,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          if (index == 5) {
                            // Highlight current value with larger dot
                            return FlDotCirclePainter(
                              radius: 5,
                              color: AppColors.income,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          }
                          return FlDotCirclePainter(
                            radius: 2.5,
                            color: AppColors.income,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.income.withValues(alpha: 0.25),
                            AppColors.income.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= last6Months.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_formatMonth(last6Months[idx]),
                                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min) return const SizedBox.shrink();
                          String label;
                          final absVal = value.abs();
                          if (absVal >= 1000000) {
                            label = '${(value / 1000000).toStringAsFixed(1)}M';
                          } else if (absVal >= 1000) {
                            label = '${(value / 1000).toStringAsFixed(0)}K';
                          } else {
                            label = value.toStringAsFixed(0);
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text('\u20B1$label',
                                style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
                                textAlign: TextAlign.right),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: range > 0 ? range / 4 : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outline.withValues(alpha: 0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBorderRadius: BorderRadius.circular(8),
                      getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                        final idx = spot.spotIndex;
                        return LineTooltipItem(
                          '${_formatMonth(last6Months[idx])}\n',
                          TextStyle(fontSize: 11, color: colorScheme.onSurface),
                          children: [
                            TextSpan(
                              text: formatCurrency(spot.y),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.income),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ]);
        },
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

  String _formatCompactCurrency(double value) {
    if (value >= 1000000) {
      return '₱${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '₱${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return '₱${value.toStringAsFixed(0)}';
    }
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
    final transactions = ref.watch(transactionsProvider);

    return Column(children: [
      // Budget Status with Progress Bars
      _OverviewCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Budget Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                    GestureDetector(
                      onTap: () => context.go('/budgets'),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Set up budgets', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                        const SizedBox(width: 4),
                        Icon(LucideIcons.arrowRight, size: 14, color: colorScheme.primary),
                      ]),
                    ),
                  ]),
                );
              }

              // Compute spending per budget category
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

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(b.category, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                      Text('${formatCurrency(spent)} / ${formatCurrency(b.amount)}',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
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
    final budgets = ref.watch(budgetsProvider);
    final transactions = ref.watch(transactionsProvider);

    return summary.when(
      data: (s) {
        final savingsRate = s.income > 0 ? ((s.income - s.expenses) / s.income * 100) : 0.0;
        final monthlyObligations = (billsSummary.valueOrNull?.monthlyTotal ?? 0) +
            (debtSummary.valueOrNull?.totalMinMonthly ?? 0);
        final safeToSpend = s.income - s.expenses;
        final emergencyMonths = s.expenses > 0 ? totalBalance / (s.expenses > 0 ? s.expenses : 1) : 0.0;

        // --- Compute Real Financial Health Score ---
        // 1) Savings Rate score (25%): 20% savings = perfect
        final savingsRateScore = s.income > 0
            ? ((savingsRate / 20) * 100).clamp(0.0, 100.0)
            : 0.0;

        // 2) Budget Adherence score (25%): % of budgets under limit
        double budgetAdherenceScore = 50.0; // default if no budgets
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

        // 3) Emergency Fund score (25%): 3 months = perfect
        final emergencyFundScore = (emergencyMonths / 3 * 100).clamp(0.0, 100.0);

        // 4) Debt-to-Income score (25%)
        final monthlyDebt = debtSummary.valueOrNull?.totalMinMonthly ?? 0;
        final debtToIncomeScore = s.income > 0
            ? ((1 - monthlyDebt / s.income) * 100).clamp(0.0, 100.0)
            : (monthlyDebt > 0 ? 0.0 : 100.0);

        // Weighted total
        final healthScore = (savingsRateScore * 0.25 +
            budgetAdherenceScore * 0.25 +
            emergencyFundScore * 0.25 +
            debtToIncomeScore * 0.25).clamp(0.0, 100.0);

        // Label and color
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
            spendingVelocityWidget = _OverviewCard(
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
            );
          }
        }

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
                  painter: _GaugePainter(value: healthScore, color: healthColor, label: healthLabel),
                ),
              ),
              const SizedBox(height: 12),
              // Metrics
              _HealthRow(label: 'Savings Rate', value: '${savingsRate.toStringAsFixed(0)}% of income saved',
                  color: savingsRateScore >= 50 ? AppColors.income : const Color(0xFFF97316), progress: savingsRateScore / 100),
              _HealthRow(label: 'Budget Adherence', value: budgetAdherenceText,
                  color: budgetAdherenceScore >= 50 ? AppColors.income : const Color(0xFFF97316), progress: budgetAdherenceScore / 100),
              _HealthRow(label: 'Emergency Fund', value: '${emergencyMonths.toStringAsFixed(1)} of 3 months',
                  color: emergencyFundScore >= 50 ? AppColors.income : const Color(0xFFF97316), progress: emergencyFundScore / 100),
              _HealthRow(label: 'Debt-to-Income', value: s.income > 0 ? '${(monthlyDebt / s.income * 100).toStringAsFixed(0)}% of income' : 'No income data',
                  color: debtToIncomeScore >= 50 ? AppColors.income : const Color(0xFFF97316), progress: debtToIncomeScore / 100),
            ]),
          ),
          const SizedBox(height: 12),

          // Spending Velocity Indicator
          if (spendingVelocityWidget != null) ...[
            spendingVelocityWidget,
            const SizedBox(height: 12),
          ],

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

          // Average Daily Spend
          _OverviewCard(
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
                    color: (dailyBudgetRemaining > 0 ? AppColors.income : const Color(0xFFEF4444)).withValues(alpha: 0.1),
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
            _OverviewCard(
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
                  return Padding(
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
                  );
                }),
              ]),
            ),
            const SizedBox(height: 12),
          ],

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

// ─── Custom painters removed — replaced by fl_chart widgets ────────────────────

// ─── Gauge Painter ─────────────────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  final double value; // 0-100
  final Color color;
  final String label;

  _GaugePainter({required this.value, required this.color, this.label = 'Fair'});

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
        text: label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, Offset(center.dx - labelPainter.width / 2, center.dy - 2));
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
