import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import 'dashboard_widgets.dart';

/// Pie chart showing spending breakdown by category for the current month.
/// Accepts pre-aggregated category totals from SQL (rows with {category, total}).
class SpendingChart extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> categoryTotals;

  const SpendingChart({super.key, required this.categoryTotals});

  static const _chartColors = [
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFEAB308),
    Color(0xFF22C55E), Color(0xFF3B82F6), Color(0xFF8B5CF6),
    Color(0xFFEC4899), Color(0xFF14B8A6),
  ];

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      child: categoryTotals.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No spending data yet', style: TextStyle(fontSize: 13))),
            );
          }
          final sorted = rows.map((r) => MapEntry(r['category'] as String, (r['total'] as num).toDouble())).toList();
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
                        color: _chartColors[i % _chartColors.length],
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
                      decoration: BoxDecoration(color: _chartColors[i % _chartColors.length], shape: BoxShape.circle)),
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
}
