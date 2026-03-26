import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/widgets/error_retry.dart';
import '../providers/report_providers.dart';

class ReportsListScreen extends ConsumerWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final reportsAsync = ref.watch(allReportsProvider);

    return reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.barChart3,
                    size: 48,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reports yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate your first monthly report',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(LucideIcons.plusCircle, size: 14),
                    label: const Text('Generate Report'),
                    onPressed: () {
                      final now = DateTime.now();
                      final targetMonth = now.day <= 3 ? now.month - 1 : now.month;
                      final targetYear = targetMonth <= 0 ? now.year - 1 : now.year;
                      final month = targetMonth <= 0 ? 12 + targetMonth : targetMonth;
                      context.push('/reports/$targetYear/$month');
                    },
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Monthly financial summaries', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    FilledButton.icon(
                      icon: const Icon(LucideIcons.plusCircle, size: 14),
                      label: const Text('Generate'),
                      onPressed: () {
                        final now = DateTime.now();
                        final targetMonth = now.day <= 3 ? now.month - 1 : now.month;
                        final targetYear = targetMonth <= 0 ? now.year - 1 : now.year;
                        final month = targetMonth <= 0 ? 12 + targetMonth : targetMonth;
                        context.push('/reports/$targetYear/$month');
                      },
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    ),
                  ],
                );
              }
              final adjustedIndex = index - 1;
              final report = reports[adjustedIndex];
              final monthName = DateFormat('MMMM yyyy').format(
                DateTime(report.year, report.month),
              );

              return InkWell(
                onTap: () =>
                    context.go('/reports/${report.year}/${report.month}'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Grade badge
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _gradeColor(report.grade).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            report.grade,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _gradeColor(report.grade),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monthName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Savings rate: ${report.savingsRate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorRetry(
          message: 'Could not load reports',
          onRetry: () => ref.invalidate(allReportsProvider),
        ),
      );
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return AppColors.income;
      case 'B+':
      case 'B':
        return AppColors.info;
      case 'C+':
      case 'C':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }
}
