import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import 'dashboard_widgets.dart';

/// Bar chart showing monthly income and expenses for the last 6 months,
/// with a small net-income line chart below.
/// Accepts pre-aggregated monthly totals from SQL (rows with {month, income, expenses}).
class MonthlyComparisonChart extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> monthlyTotals;

  const MonthlyComparisonChart({super.key, required this.monthlyTotals});

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      child: monthlyTotals.when(
        data: (rows) {
          final now = DateTime.now();
          final last6Months = List.generate(6, (i) {
            final d = DateTime(now.year, now.month - 5 + i);
            return '${d.year}-${d.month.toString().padLeft(2, '0')}';
          });

          final monthlyData = <String, ({double income, double expenses})>{};
          for (final r in rows) {
            final month = r['month'] as String;
            monthlyData[month] = (
              income: (r['income'] as num).toDouble(),
              expenses: (r['expenses'] as num).toDouble(),
            );
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
                        color: colorScheme.outline.withOpacity(0.08),
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
                            color: AppColors.info.withOpacity(0.08),
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
}
