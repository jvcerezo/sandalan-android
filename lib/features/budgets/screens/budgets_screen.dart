import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/budget.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../providers/budget_providers.dart';
import '../widgets/add_budget_dialog.dart';
import '../widgets/budget_rollover_dialog.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  bool _rolloverCheckDone = false;

  @override
  void initState() {
    super.initState();
    // Schedule the rollover check after the first frame so providers are available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRollover();
    });
  }

  Future<void> _checkRollover() async {
    if (_rolloverCheckDone) return;
    _rolloverCheckDone = true;

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final prefs = await SharedPreferences.getInstance();
    final shownKey = 'budget_rollover_shown_$monthKey';
    final alreadyShown = prefs.getBool(shownKey) ?? false;
    if (alreadyShown) return;

    // Check if viewing current month and budgets are empty
    final viewedMonth = ref.read(budgetMonthProvider);
    if (viewedMonth.year != currentMonth.year || viewedMonth.month != currentMonth.month) return;

    // Wait for budgets to load
    final repo = ref.read(budgetRepositoryProvider);
    final currentBudgets = await repo.getBudgets(currentMonth, 'monthly');
    if (currentBudgets.isNotEmpty) {
      // Already has budgets for this month, mark as shown
      await prefs.setBool(shownKey, true);
      return;
    }

    // Check if there were budgets last month (otherwise nothing to roll over)
    final lastMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    final lastMonthBudgets = await repo.getBudgets(lastMonth, 'monthly');
    if (lastMonthBudgets.isEmpty) return;

    // Check for auto-rollover preference
    final autoRollover = prefs.getBool('budget_auto_rollover') ?? false;
    if (autoRollover) {
      await _performRollover(currentMonth, lastMonth);
      await prefs.setBool(shownKey, true);
      return;
    }

    // Show the popup
    if (!mounted) return;
    final result = await showDialog<BudgetRolloverResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BudgetRolloverDialog(currentMonth: currentMonth),
    );

    if (result == null || result.choice == BudgetRolloverChoice.dismiss) return;

    // Save auto-rollover preference if checked
    if (result.autoRollover) {
      await prefs.setBool('budget_auto_rollover', true);
    }

    // Mark as shown for this month
    await prefs.setBool(shownKey, true);

    if (result.choice == BudgetRolloverChoice.rollover) {
      await _performRollover(currentMonth, lastMonth);
    }
    // If startFresh, do nothing — no budgets created
  }

  Future<void> _performRollover(DateTime currentMonth, DateTime lastMonth) async {
    final repo = ref.read(budgetRepositoryProvider);

    // Compute spending by category for last month from transactions
    final lastMonthStart = lastMonth;
    final lastMonthEnd = DateTime(currentMonth.year, currentMonth.month, 0); // last day of previous month
    final txnRepo = ref.read(transactionRepositoryProvider);
    final transactions = await txnRepo.getTransactions(TransactionFilters(
      startDate: lastMonthStart,
      endDate: lastMonthEnd,
    ));

    final spentByCategory = <String, double>{};
    for (final t in transactions) {
      if (t.amount >= 0 || t.category.toLowerCase() == 'transfer') continue;
      spentByCategory[t.category] = (spentByCategory[t.category] ?? 0) + t.amount.abs();
    }

    final created = await repo.rolloverBudgets(
      fromMonth: lastMonth,
      toMonth: currentMonth,
      spentByCategory: spentByCategory,
    );

    ref.invalidate(budgetsProvider);

    if (mounted && created > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rolled over $created budget${created == 1 ? '' : 's'} with unused amounts')),
      );
    }
  }

  void _showAddBudget(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddBudgetDialog(),
    ).then((_) => ref.invalidate(budgetsProvider));
  }

  Future<void> _copyFromLastMonth(BuildContext context, DateTime currentMonth) async {
    final lastMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    final repo = ref.read(budgetRepositoryProvider);

    // Get last month's budgets
    final lastMonthBudgets = await repo.getBudgets(lastMonth, 'monthly');

    if (!context.mounted) return;

    if (lastMonthBudgets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No budgets found for ${DateFormat('MMMM yyyy').format(lastMonth)}')),
      );
      return;
    }

    // Confirm
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Copy Budgets'),
        content: Text('Copy ${lastMonthBudgets.length} budget${lastMonthBudgets.length == 1 ? '' : 's'} '
            'from ${DateFormat('MMMM').format(lastMonth)} to ${DateFormat('MMMM').format(currentMonth)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Copy')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Copy each budget
    int copied = 0;
    for (final budget in lastMonthBudgets) {
      try {
        await repo.createBudget(
          category: budget.category,
          amount: budget.amount,
          month: currentMonth,
          period: 'monthly',
        );
        copied++;
      } catch (_) {
        // Skip duplicates
      }
    }

    ref.invalidate(budgetsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied $copied budget${copied == 1 ? '' : 's'} from ${DateFormat('MMMM').format(lastMonth)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final budgets = ref.watch(budgetsProvider);
    final period = ref.watch(budgetPeriodProvider);
    final month = ref.watch(budgetMonthProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Budgets', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          FilledButton.icon(
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add'),
            onPressed: () => _showAddBudget(context),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
        ]),
        const SizedBox(height: 12),

        // Period filter tabs
        Row(children: [
          Expanded(child: Wrap(spacing: 6, runSpacing: 4, children: [
            {'label': 'All', 'value': 'all'},
            {'label': 'Weekly', 'value': 'weekly'},
            {'label': 'Monthly', 'value': 'monthly'},
            {'label': 'Quarterly', 'value': 'quarterly'},
          ].map((p) {
            final selected = period == p['value'];
            return _PeriodTab(
              label: p['label']!,
              isSelected: selected,
              onTap: () => ref.read(budgetPeriodProvider.notifier).state = p['value']!,
            );
          }).toList())),
          TextButton.icon(
            onPressed: () => _copyFromLastMonth(context, month),
            icon: Icon(LucideIcons.copy, size: 14, color: colorScheme.primary),
            label: Text('Copy last month', style: TextStyle(fontSize: 12, color: colorScheme.primary)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
          ),
        ]),
        const SizedBox(height: 12),

        // Month nav
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            onPressed: () {
              final prev = DateTime(month.year, month.month - 1, 1);
              ref.read(budgetMonthProvider.notifier).state = prev;
            },
            icon: const Icon(LucideIcons.chevronLeft, size: 18),
          ),
          Text(DateFormat('MMMM yyyy').format(month),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          IconButton(
            onPressed: () {
              final next = DateTime(month.year, month.month + 1, 1);
              ref.read(budgetMonthProvider.notifier).state = next;
            },
            icon: const Icon(LucideIcons.chevronRight, size: 18),
          ),
        ]),
        const SizedBox(height: 12),

        // Budget list
        budgets.when(
          data: (list) {
            if (list.isEmpty) {
              return EmptyState(
                icon: LucideIcons.pieChart,
                title: 'No budgets for this period',
                subtitle: 'Create budgets to track your spending by category.',
                action: FilledButton.icon(
                  onPressed: () => _showAddBudget(context),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Add Budget'),
                ),
              );
            }

            final totalBudget = list.fold(0.0, (s, b) => s + b.amount);

            return Column(children: [
              // Summary
              Row(children: [
                _SummaryCard(label: 'Total Budget', value: formatCurrency(totalBudget),
                    color: colorScheme.primary),
              ]),
              const SizedBox(height: 12),
              ...list.map((b) => _BudgetCard(budget: b)),
            ]);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _PeriodTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant)),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  const _BudgetCard({required this.budget});

  String _periodLabel() {
    final now = DateTime.now();
    switch (budget.period) {
      case 'weekly':
        // Monday of current week to Sunday
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        final mFmt = '${_monthAbbr(monday.month)} ${monday.day}';
        final sFmt = '${sunday.day}';
        return 'Weekly ($mFmt-$sFmt)';
      case 'quarterly':
        final q = ((now.month - 1) ~/ 3) + 1;
        return 'Quarterly (Q$q ${now.year})';
      default:
        return 'Monthly';
    }
  }

  static String _monthAbbr(int m) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m];
  }

  Color _periodColor(ColorScheme cs) {
    switch (budget.period) {
      case 'weekly': return const Color(0xFF3B82F6);
      case 'quarterly': return const Color(0xFF8B5CF6);
      default: return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Simple display — actual spent data requires cross-referencing transactions
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Row(children: [
              Flexible(child: Text(budget.category,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _periodColor(colorScheme).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_periodLabel(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                        color: _periodColor(colorScheme))),
              ),
            ])),
            Text(formatCurrency(budget.amount),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.primary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0, // Would be spent/budget ratio
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${formatCurrency(0)} spent',
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${formatCurrency(budget.amount)} remaining',
                style: TextStyle(fontSize: 11, color: AppColors.income),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
          if (budget.rollover) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(LucideIcons.refreshCw, size: 10, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Rollover enabled',
                  style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
            ]),
          ],
        ]),
      ),
    );
  }
}
