import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../accounts/providers/account_providers.dart';
import '../../../data/models/transaction.dart';
import 'dashboard_widgets.dart';

class TrendsTab extends ConsumerStatefulWidget {
  const TrendsTab({super.key});

  @override
  ConsumerState<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends ConsumerState<TrendsTab> {
  int _trendView = 0;
  static const _views = ['Spending', 'Monthly', 'Net Worth', 'Compare'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentMonthTxns = ref.watch(currentMonthTransactionsProvider);
    final last6MonthsTxns = ref.watch(last6MonthsTransactionsProvider);

    return Column(children: [
      const SectionLabel('TREND VIEWS'),
      const SizedBox(height: 8),
      // Sub-tabs
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
                setState(() => _trendView = i);
              },
              borderRadius: BorderRadius.circular(7),
              child: Semantics(
                label: '${_views[i]} trend view',
                selected: _trendView == i,
                button: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _trendView == i ? colorScheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: _trendView == i ? [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                    ] : null,
                  ),
                  child: Center(child: Text(_views[i],
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: _trendView == i ? colorScheme.onSurface : colorScheme.onSurfaceVariant))),
                ),
              ),
            ),
          ),
        ))),
      ),
      const SizedBox(height: 12),

      // View content based on selected trend view
      if (_trendView == 0) _buildSpendingView(context, currentMonthTxns),
      if (_trendView == 1) _buildMonthlyView(context, last6MonthsTxns),
      if (_trendView == 2) _buildNetWorthView(context),
      if (_trendView == 3) _buildCompareView(context),
    ]);
  }

  Widget _buildSpendingView(BuildContext context, AsyncValue<List<Transaction>> transactions) {
    final chartColors = [
      const Color(0xFFEF4444), const Color(0xFFF97316), const Color(0xFFEAB308),
      const Color(0xFF22C55E), const Color(0xFF3B82F6), const Color(0xFF8B5CF6),
      const Color(0xFFEC4899), const Color(0xFF14B8A6),
    ];

    return OverviewCard(
      child: transactions.when(
        data: (txns) {
          final expenses = txns.where((t) => t.amount < 0 && t.category.toLowerCase() != 'transfer' && t.category.toLowerCase() != 'goal funding').toList();
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

          return Semantics(
            label: 'Spending breakdown chart showing ${sorted.length} categories totaling ${formatCurrency(total)}',
            child: Column(children: [
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
            ]),
          );
        },
        loading: () => const ShimmerCard(height: 200),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildMonthlyView(BuildContext context, AsyncValue<List<Transaction>> transactions) {
    return OverviewCard(
      child: transactions.when(
        data: (txns) {
          final now = DateTime.now();
          final last6Months = List.generate(6, (i) {
            final d = DateTime(now.year, now.month - 5 + i);
            return '${d.year}-${d.month.toString().padLeft(2, '0')}';
          });

          final monthlyData = <String, ({double income, double expenses})>{};
          for (final t in txns) {
            final cat = t.category.toLowerCase();
            if (cat == 'transfer' || cat == 'goal funding') continue;
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

          return Semantics(
            label: 'Monthly income and expenses bar chart for the last 6 months',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                            formatCompactCurrency(value),
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
                              child: Text(formatMonth(last6Months[idx]),
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
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(formatYAxisLabel(value),
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
              // Net line as a separate small LineChart
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
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(formatYAxisLabel(value),
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
                LegendDot(color: AppColors.income, label: 'Income'),
                const SizedBox(width: 16),
                LegendDot(color: Colors.grey.shade400, label: 'Expenses'),
                const SizedBox(width: 16),
                LegendDot(color: AppColors.info, label: 'Net'),
              ]),
            ]),
          );
        },
        loading: () => const ShimmerCard(height: 200),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildNetWorthView(BuildContext context) {
    final transactions = ref.watch(last6MonthsTransactionsProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return OverviewCard(
      child: transactions.when(
        data: (txns) {
          final now = DateTime.now();
          final last6Months = List.generate(6, (i) {
            final d = DateTime(now.year, now.month - 5 + i);
            return '${d.year}-${d.month.toString().padLeft(2, '0')}';
          });

          final monthlyNet = <String, double>{};
          for (final t in txns) {
            if (t.category.toLowerCase() == 'transfer') continue;
            final month = t.date.substring(0, 7);
            monthlyNet[month] = (monthlyNet[month] ?? 0) + t.amount;
          }

          double cumulative = totalBalance;
          final cumulativeValues = <double>[];
          final netsForMonths = last6Months.map((m) => monthlyNet[m] ?? 0.0).toList();
          for (int i = 5; i >= 0; i--) {
            cumulativeValues.insert(0, cumulative);
            if (i > 0) cumulative -= netsForMonths[i];
          }

          final currentValue = cumulativeValues.last;
          final minVal = cumulativeValues.reduce(math.min);
          final maxVal = cumulativeValues.reduce(math.max);
          final range = maxVal - minVal;

          return Semantics(
            label: 'Net worth trend chart. Current net worth: ${formatCurrency(currentValue)}',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                              child: Text(formatMonth(last6Months[idx]),
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
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(formatYAxisLabel(value),
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
                            '${formatMonth(last6Months[idx])}\n',
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
            ]),
          );
        },
        loading: () => const ShimmerCard(height: 200),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCompareView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final transactions = ref.watch(last6MonthsTransactionsProvider);

    return OverviewCard(
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
            final cat = t.category.toLowerCase();
            if (cat == 'transfer' || cat == 'goal funding') continue;
            final month = t.date.substring(0, 7);
            if (month == thisMonth) {
              thisMonthTotals[t.category] = (thisMonthTotals[t.category] ?? 0) + t.amount.abs();
            } else if (month == lastMonthStr) {
              lastMonthTotals[t.category] = (lastMonthTotals[t.category] ?? 0) + t.amount.abs();
            }
          }

          final allCategories = {...thisMonthTotals.keys, ...lastMonthTotals.keys}.toList()..sort();

          return Semantics(
            label: 'Spending comparison table: this month versus last month across ${allCategories.length} categories',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Spending: This vs Last Month',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
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
                  const Expanded(flex: 2, child: Text('\u0394', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
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
                          '${delta > 0 ? '\u2191' : delta < 0 ? '\u2193' : '\u2014'} ${delta.abs().toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: deltaColor),
                          textAlign: TextAlign.right)),
                    ]),
                  );
                }),
            ]),
          );
        },
        loading: () => const ShimmerCard(height: 200),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
