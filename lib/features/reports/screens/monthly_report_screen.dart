import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/theme/color_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/monthly_report.dart';
import '../providers/report_providers.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  final int year;
  final int month;

  const MonthlyReportScreen({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  final _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(
      monthlyReportProvider((year: widget.year, month: widget.month)),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/reports');
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/reports'),
        ),
        title: Text(
          DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month)),
        ),
        actions: [
          if (reportAsync.hasValue)
            IconButton(
              icon: const Icon(LucideIcons.share2),
              tooltip: 'Share report card',
              onPressed: () => _shareReport(reportAsync.value!),
            ),
        ],
      ),
      body: reportAsync.when(
        data: (report) => _buildReport(context, report),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error generating report: $e')),
      ),
    ));
  }

  Widget _buildReport(BuildContext context, MonthlyReport report) {
    final colorScheme = Theme.of(context).colorScheme;
    final monthName = DateFormat('MMMM yyyy').format(
      DateTime(report.year, report.month),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'Monthly Financial Report',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Sandwich report cards
          if (report.positiveHighlight.isNotEmpty)
            _SandwichCard(
              text: report.positiveHighlight,
              accentColor: const Color(0xFF22C55E), // green
              icon: LucideIcons.star,
            ),
          if (report.positiveHighlight.isNotEmpty) const SizedBox(height: 8),
          if (report.hardTruth.isNotEmpty)
            _SandwichCard(
              text: report.hardTruth,
              accentColor: const Color(0xFFF59E0B), // amber
              icon: LucideIcons.alertTriangle,
            ),
          if (report.hardTruth.isNotEmpty) const SizedBox(height: 8),
          if (report.encouragement.isNotEmpty)
            _SandwichCard(
              text: report.encouragement,
              accentColor: colorScheme.primary,
              icon: LucideIcons.lightbulb,
            ),
          if (report.encouragement.isNotEmpty) const SizedBox(height: 16),

          // Grade hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  monthName,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report.grade,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _gradeLabel(report.grade),
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Income & Spending summary
          _SectionCard(
            title: 'Income & Spending',
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Income',
                  value: formatCurrency(report.totalIncome),
                  color: AppColors.income,
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Expenses',
                  value: formatCurrency(report.totalExpenses),
                  color: AppColors.error,
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Net Saved',
                  value: formatCurrency(report.netSaved),
                  color: report.netSaved >= 0
                      ? AppColors.income
                      : AppColors.error,
                  bold: true,
                ),
                const SizedBox(height: 12),
                // Mini bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        Expanded(
                          flex: report.totalIncome > 0
                              ? ((report.totalIncome /
                                          (report.totalIncome +
                                              report.totalExpenses)) *
                                      100)
                                  .round()
                              : 50,
                          child: Container(color: AppColors.income),
                        ),
                        Expanded(
                          flex: report.totalExpenses > 0
                              ? ((report.totalExpenses /
                                          (report.totalIncome +
                                              report.totalExpenses)) *
                                      100)
                                  .round()
                              : 50,
                          child: Container(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Top 5 categories
          if (report.topCategories.isNotEmpty)
            _SectionCard(
              title: 'Top Spending Categories',
              child: Column(
                children: [
                  for (int i = 0; i < report.topCategories.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _CategoryBar(
                      category: report.topCategories[i],
                      colorScheme: colorScheme,
                      index: i,
                    ),
                  ],
                ],
              ),
            ),
          if (report.topCategories.isNotEmpty) const SizedBox(height: 12),

          // Savings rate
          _SectionCard(
            title: 'Savings Rate',
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${report.savingsRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: report.savingsRate >= 20
                            ? AppColors.income
                            : report.savingsRate >= 10
                                ? AppColors.warning
                                : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        report.savingsRate >= 20
                            ? 'Great!'
                            : report.savingsRate >= 10
                                ? 'Good'
                                : 'Needs work',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Goals progress
          _SectionCard(
            title: 'Goals',
            child: Row(
              children: [
                Icon(
                  report.goalsContributed > 0
                      ? LucideIcons.checkCircle2
                      : LucideIcons.circle,
                  size: 20,
                  color: report.goalsContributed > 0
                      ? AppColors.income
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Text(
                  report.goalsContributed > 0
                      ? '${report.goalsContributed} contributions this month'
                      : 'No goal contributions this month',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Streak stats
          _SectionCard(
            title: 'Activity',
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.flame, size: 20, color: AppColors.warning),
                    const SizedBox(width: 10),
                    Text(
                      '${report.daysActive} of ${DateTime(report.year, report.month + 1, 0).day} days active',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(LucideIcons.zap, size: 20, color: AppColors.toolAmber),
                    const SizedBox(width: 10),
                    Text(
                      'Best streak: ${report.bestStreak} days',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Health score
          _SectionCard(
            title: 'Health Score',
            child: Row(
              children: [
                Text(
                  report.healthScore.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: report.healthScore >= 71
                        ? AppColors.income
                        : report.healthScore >= 51
                            ? AppColors.warning
                            : AppColors.error,
                  ),
                ),
                const SizedBox(width: 8),
                Text('/100', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                const SizedBox(width: 12),
                if (report.healthScoreDelta != 0)
                  Row(
                    children: [
                      Icon(
                        report.healthScoreDelta > 0
                            ? LucideIcons.arrowUp
                            : LucideIcons.arrowDown,
                        size: 16,
                        color: report.healthScoreDelta > 0
                            ? AppColors.income
                            : AppColors.error,
                      ),
                      Text(
                        '${report.healthScoreDelta.abs().toStringAsFixed(1)} vs last month',
                        style: TextStyle(
                          fontSize: 12,
                          color: report.healthScoreDelta > 0
                              ? AppColors.income
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _gradeLabel(String grade) {
    switch (grade) {
      case 'A+':
        return 'Outstanding!';
      case 'A':
        return 'Excellent!';
      case 'B+':
        return 'Very Good';
      case 'B':
        return 'Good';
      case 'C+':
        return 'Above Average';
      case 'C':
        return 'Average';
      default:
        return 'Needs Improvement';
    }
  }

  Future<void> _shareReport(MonthlyReport report) async {
    try {
      // Build a share image using RepaintBoundary
      final image = await _buildShareImage(report);
      if (image == null) return;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/sandalan_report_${report.year}_${report.month}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My ${DateFormat('MMMM yyyy').format(DateTime(report.year, report.month))} financial report card from Sandalan!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share: $e')),
        );
      }
    }
  }

  Future<ui.Image?> _buildShareImage(MonthlyReport report) async {
    final colorScheme = Theme.of(context).colorScheme;
    final monthName = DateFormat('MMMM yyyy').format(
      DateTime(report.year, report.month),
    );

    // Create a widget for the share card
    final widget = MediaQuery(
      data: const MediaQueryData(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: RepaintBoundary(
            key: _shareKey,
            child: Container(
              width: 390,
              height: 690,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sandalan branding
                  Text(
                    'Sandalan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Grade
                  Text(
                    report.grade,
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 2x2 stats grid (NO peso amounts)
                  Row(
                    children: [
                      Expanded(
                        child: _ShareStat(
                          label: 'Savings Rate',
                          value: '${report.savingsRate.toStringAsFixed(1)}%',
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ShareStat(
                          label: 'Days Active',
                          value: '${report.daysActive}',
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ShareStat(
                          label: 'Health Score',
                          value: report.healthScore.toStringAsFixed(0),
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ShareStat(
                          label: 'Grade',
                          value: report.grade,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Footer
                  Text(
                    'Track your finances with Sandalan',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onPrimary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Render the widget to an image
    final repaintBoundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: const BoxConstraints(
          maxWidth: 390,
          maxHeight: 690,
        ),
        devicePixelRatio: 3.0,
      ),
    );

    final pipelineOwner = PipelineOwner();
    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final buildOwner = BuildOwner(focusManager: FocusManager());
    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: widget,
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 3.0);
    buildOwner.finalizeTree();

    return image;
  }
}

class _ShareStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ShareStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final CategoryBreakdown category;
  final ColorScheme colorScheme;
  final int index;

  const _CategoryBar({
    required this.category,
    required this.colorScheme,
    required this.index,
  });

  static const _colors = [
    AppColors.toolBlue,
    AppColors.toolOrange,
    AppColors.toolGreen,
    AppColors.toolIndigo,
    AppColors.toolTeal,
  ];

  @override
  Widget build(BuildContext context) {
    final barColor = _colors[index % _colors.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category.category,
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              '${category.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: (category.percentage / 100).clamp(0.0, 1.0),
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _SandwichCard extends StatelessWidget {
  final String text;
  final Color accentColor;
  final IconData icon;

  const _SandwichCard({
    required this.text,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
