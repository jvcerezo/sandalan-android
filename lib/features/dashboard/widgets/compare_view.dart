import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import 'dashboard_widgets.dart';

/// Comparison table showing spending by category: this month vs last month.
/// Accepts pre-aggregated compare totals from SQL (rows with {category, month, total}).
class CompareView extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> compareTotals;

  const CompareView({super.key, required this.compareTotals});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OverviewCard(
      child: compareTotals.when(
        data: (rows) {
          final now = DateTime.now();
          final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
          final lastMonth = DateTime(now.year, now.month - 1);
          final lastMonthStr = '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';

          final thisMonthTotals = <String, double>{};
          final lastMonthTotals = <String, double>{};
          for (final r in rows) {
            final cat = r['category'] as String;
            final month = r['month'] as String;
            final total = (r['total'] as num).toDouble();
            if (month == thisMonth) {
              thisMonthTotals[cat] = total;
            } else if (month == lastMonthStr) {
              lastMonthTotals[cat] = total;
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
