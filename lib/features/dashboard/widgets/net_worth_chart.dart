import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../core/services/net_worth_service.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../auth/providers/auth_provider.dart';
import 'dashboard_widgets.dart';

/// Provider that fetches and caches net worth history.
final netWorthHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id ?? GuestModeService.getGuestIdSync() ?? 'guest';
  final service = NetWorthService(AppDatabase.instance, userId);
  return service.getHistory(months: 6);
});

/// Line chart showing net worth over the last 6 months.
class NetWorthChart extends ConsumerWidget {
  const NetWorthChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(netWorthHistoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return historyAsync.when(
      data: (snapshots) => _buildChart(context, snapshots, colorScheme),
      loading: () => const ShimmerCard(height: 220),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<Map<String, dynamic>> snapshots,
    ColorScheme colorScheme,
  ) {
    if (snapshots.isEmpty) {
      return OverviewCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(LucideIcons.trendingUp, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              const Text('Net Worth History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 16),
            Center(
              child: Column(children: [
                Icon(LucideIcons.lineChart, size: 32, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
                const SizedBox(height: 8),
                Text('Net worth tracking starts today',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('Come back tomorrow to see your trend',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withOpacity(0.6))),
              ]),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    // Sort ascending for the chart (oldest first)
    final sorted = List<Map<String, dynamic>>.from(snapshots)
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    final currentNetWorth = (sorted.last['total'] as num).toDouble();

    // Compute change from first to last
    final firstNetWorth = (sorted.first['total'] as num).toDouble();
    final change = currentNetWorth - firstNetWorth;
    final changePercent = firstNetWorth != 0 ? (change / firstNetWorth.abs() * 100) : 0.0;
    final isPositive = change >= 0;

    // Build spots
    final spots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), (sorted[i]['total'] as num).toDouble()));
    }

    // Y-axis range
    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range > 0 ? range * 0.15 : maxY.abs() * 0.1 + 100;
    final chartMinY = minY - padding;
    final chartMaxY = maxY + padding;

    final lineColor = isPositive ? AppColors.income : AppColors.expense;

    return OverviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.trendingUp, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            const Text('Net Worth History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),

          // Current net worth prominently
          Text(formatCurrency(currentNetWorth),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary)),
          const SizedBox(height: 2),

          // Change indicator
          Row(children: [
            Icon(isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                size: 14, color: lineColor),
            const SizedBox(width: 4),
            Text(
              '${isPositive ? '+' : ''}${formatCurrency(change)} (${changePercent.toStringAsFixed(1)}%)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: lineColor),
            ),
            const SizedBox(width: 4),
            Text('past ${sorted.length} days',
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ((chartMaxY - chartMinY) / 4).clamp(1, double.infinity),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.surfaceContainerHighest,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _compactCurrency(value),
                          style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: _bottomInterval(sorted.length),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                        final date = DateTime.tryParse(sorted[idx]['date'] as String);
                        if (date == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('MMM d').format(date),
                            style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: chartMinY,
                maxY: chartMaxY,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final dateStr = idx >= 0 && idx < sorted.length
                            ? sorted[idx]['date'] as String
                            : '';
                        return LineTooltipItem(
                          '${formatCurrency(spot.y)}\n$dateStr',
                          TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: lineColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: sorted.length <= 14,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: lineColor,
                        strokeWidth: 1.5,
                        strokeColor: colorScheme.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact currency formatting for Y-axis labels.
  String _compactCurrency(double value) {
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    if (abs >= 1000000) return '$sign${(abs / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '$sign${(abs / 1000).toStringAsFixed(0)}K';
    return '${sign}${abs.toStringAsFixed(0)}';
  }

  /// Calculate a reasonable interval for bottom axis labels to avoid crowding.
  double _bottomInterval(int dataPoints) {
    if (dataPoints <= 7) return 1;
    if (dataPoints <= 14) return 2;
    if (dataPoints <= 31) return 5;
    if (dataPoints <= 90) return 14;
    return 30;
  }
}
