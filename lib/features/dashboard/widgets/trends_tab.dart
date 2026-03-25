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
import 'dashboard_widgets.dart';
import 'spending_chart.dart';
import 'monthly_comparison_chart.dart';
import 'compare_view.dart';

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

    return Column(children: [
      const SectionLabel('TREND VIEWS'),
      const SizedBox(height: 8),
      // Sub-tabs
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
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

      // View content based on selected trend view (using SQL aggregates)
      if (_trendView == 0) SpendingChart(categoryTotals: ref.watch(categoryTotalsProvider)),
      if (_trendView == 1) MonthlyComparisonChart(monthlyTotals: ref.watch(monthlyTotalsProvider)),
      if (_trendView == 2) _buildNetWorthView(context),
      if (_trendView == 3) CompareView(compareTotals: ref.watch(compareCategoryTotalsProvider)),
    ]);
  }

  Widget _buildNetWorthView(BuildContext context) {
    final monthlyNetAsync = ref.watch(monthlyNetTotalsProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return OverviewCard(
      child: monthlyNetAsync.when(
        data: (rows) {
          final now = DateTime.now();
          final last6Months = List.generate(6, (i) {
            final d = DateTime(now.year, now.month - 5 + i);
            return '${d.year}-${d.month.toString().padLeft(2, '0')}';
          });

          final monthlyNet = <String, double>{};
          for (final r in rows) {
            monthlyNet[r['month'] as String] = (r['net'] as num).toDouble();
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
                              AppColors.income.withOpacity(0.25),
                              AppColors.income.withOpacity(0.02),
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
                        color: colorScheme.outline.withOpacity(0.08),
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
}
