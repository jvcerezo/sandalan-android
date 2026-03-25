import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/weekly_recap_service.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/utils/formatters.dart';

/// Weekly financial recap card showing spending summary.
class WeeklyRecapCard extends StatelessWidget {
  final WeeklyRecap recap;
  final VoidCallback onDismiss;

  const WeeklyRecapCard({
    super.key,
    required this.recap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateRange = '${DateFormat('MMM d').format(recap.weekStart)}-${DateFormat('d').format(recap.weekEnd)}';
    final vsImproved = recap.vsLastWeekPercent > 0;
    final vsText = recap.vsLastWeekPercent.abs() < 0.5
        ? 'vs last week: about the same'
        : 'vs last week: spent ${recap.vsLastWeekPercent.abs().toStringAsFixed(0)}% ${vsImproved ? 'less' : 'more'}';
    final vsColor = vsImproved ? AppColors.success : colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue left accent bar
          Container(
            width: 4,
            constraints: const BoxConstraints(minHeight: 140),
            color: AppColors.info,
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'WEEKLY RECAP \u00B7 $dateRange',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Semantics(
                        label: 'Dismiss recap',
                        button: true,
                        child: InkWell(
                          onTap: onDismiss,
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: Icon(
                                LucideIcons.x,
                                size: 14,
                                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 3 stat columns
                  Row(
                    children: [
                      _RecapStat(
                        icon: LucideIcons.trendingDown,
                        iconColor: colorScheme.onSurfaceVariant,
                        label: 'Spent',
                        value: formatCurrency(recap.spent),
                      ),
                      const SizedBox(width: 16),
                      _RecapStat(
                        icon: LucideIcons.piggyBank,
                        iconColor: AppColors.success,
                        label: 'Saved',
                        value: formatCurrency(recap.saved),
                        valueColor: recap.saved >= 0 ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 16),
                      _RecapStat(
                        icon: LucideIcons.tag,
                        iconColor: colorScheme.onSurfaceVariant,
                        label: 'Top Category',
                        value: recap.topCategory,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Comparison line
                  Text(
                    vsText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: vsColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Dashboard link
                  GestureDetector(
                    onTap: () => context.go('/dashboard'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See Full Dashboard',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(LucideIcons.arrowRight, size: 12, color: colorScheme.primary),
                      ],
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
}

class _RecapStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _RecapStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
