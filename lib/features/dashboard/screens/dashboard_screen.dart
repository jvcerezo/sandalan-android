import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../goals/providers/goal_providers.dart';
import '../../../data/models/transaction.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final summary = ref.watch(transactionsSummaryProvider);
    final recentTxns = ref.watch(recentTransactionsProvider);
    final goalsSummary = ref.watch(goalsSummaryProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Dashboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Row(children: [
              _ActionChip(label: 'Income', color: AppColors.income,
                  onTap: () => context.go('/transactions')),
              const SizedBox(width: 8),
              _ActionChip(label: 'Expense', color: AppColors.expense,
                  onTap: () => context.go('/transactions')),
            ]),
          ],
        ),
        const SizedBox(height: 20),

        // Balance card
        summary.when(
          data: (s) => _BalanceCard(balance: s.balance, income: s.income, expenses: s.expenses),
          loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error loading summary', style: TextStyle(color: colorScheme.error)),
          )),
        ),
        const SizedBox(height: 16),

        // Quick links
        Row(children: [
          _QuickLink(icon: LucideIcons.arrowLeftRight, label: 'Transactions',
              onTap: () => context.go('/transactions')),
          const SizedBox(width: 8),
          _QuickLink(icon: LucideIcons.landmark, label: 'Accounts',
              onTap: () => context.go('/accounts')),
          const SizedBox(width: 8),
          _QuickLink(icon: LucideIcons.pieChart, label: 'Budgets',
              onTap: () => context.go('/budgets')),
          const SizedBox(width: 8),
          _QuickLink(icon: LucideIcons.target, label: 'Goals',
              onTap: () => context.go('/goals')),
        ]),
        const SizedBox(height: 20),

        // Goals snapshot
        goalsSummary.when(
          data: (gs) => gs.total > 0 ? _GoalsSnapshot(
            active: gs.active, completed: gs.completed, progress: gs.overallProgress,
          ) : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Recent transactions
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Transactions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            GestureDetector(
              onTap: () => context.go('/transactions'),
              child: Text('See all', style: TextStyle(fontSize: 13, color: colorScheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        recentTxns.when(
          data: (txns) => txns.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No transactions yet',
                      style: TextStyle(color: colorScheme.onSurfaceVariant))),
                )
              : Column(children: txns.map((t) => _TransactionTile(transaction: t)).toList()),
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance, income, expenses;
  const _BalanceCard({required this.balance, required this.income, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Total Balance', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(formatCurrency(balance), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
            _BalanceStat(label: 'Income', value: income, color: AppColors.income, icon: LucideIcons.trendingUp),
            const SizedBox(width: 16),
            _BalanceStat(label: 'Expenses', value: expenses, color: AppColors.expense, icon: LucideIcons.trendingDown),
          ]),
        ]),
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  const _BalanceStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(formatCurrency(value), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ]),
      ]),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

class _GoalsSnapshot extends StatelessWidget {
  final int active, completed;
  final double progress;
  const _GoalsSnapshot({required this.active, required this.completed, required this.progress});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Goals', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text('$active active · $completed done',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest, color: AppColors.income),
          ),
          const SizedBox(height: 4),
          Text('${(progress * 100).toStringAsFixed(0)}% overall',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIncome = transaction.isIncome;
    final color = isIncome ? AppColors.income : AppColors.expense;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(transaction.description.isNotEmpty ? transaction.description : transaction.category,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${transaction.category} · ${formatDateRelative(DateTime.parse(transaction.date))}',
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
          ]),
        ),
        Text('${isIncome ? '+' : '-'}${formatCurrency(transaction.amount.abs())}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}
