import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/transaction_providers.dart';
import '../widgets/add_transaction_dialog.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _selectedType = 'all';
  String _selectedCategory = 'all';
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(transactionFiltersProvider.notifier).state = TransactionFilters(
      type: _selectedType == 'all' ? null : _selectedType,
      category: _selectedCategory == 'all' ? null : _selectedCategory,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final transactions = ref.watch(transactionsProvider);
    final count = ref.watch(transactionsCountProvider);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Transactions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            count.when(
              data: (c) => Text('$c transactions',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ]),
          Row(children: [
            IconButton(
              onPressed: () => setState(() => _showFilters = !_showFilters),
              icon: Icon(LucideIcons.filter, size: 20,
                  color: _showFilters ? colorScheme.primary : colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            FilledButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            ),
          ]),
        ]),
      ),

      if (_showFilters) ...[
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onSubmitted: (_) => _applyFilters(),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _FilterChip(label: 'All', isSelected: _selectedType == 'all',
                onTap: () { setState(() => _selectedType = 'all'); _applyFilters(); }),
            const SizedBox(width: 6),
            _FilterChip(label: 'Income', isSelected: _selectedType == 'income',
                color: AppColors.income,
                onTap: () { setState(() => _selectedType = 'income'); _applyFilters(); }),
            const SizedBox(width: 6),
            _FilterChip(label: 'Expense', isSelected: _selectedType == 'expense',
                color: AppColors.expense,
                onTap: () { setState(() => _selectedType = 'expense'); _applyFilters(); }),
            const Spacer(),
            DropdownButton<String>(
              value: _selectedCategory,
              underline: const SizedBox.shrink(),
              isDense: true,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All categories')),
                ...kCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: (v) { setState(() => _selectedCategory = v ?? 'all'); _applyFilters(); },
            ),
          ]),
        ),
      ],
      const SizedBox(height: 12),

      Expanded(
        child: transactions.when(
          data: (txns) => txns.isEmpty
              ? EmptyState(
                  icon: LucideIcons.receipt,
                  title: 'No transactions yet',
                  subtitle: 'Add your first income or expense to get started.',
                  action: FilledButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Add Transaction'),
                  ),
                )
              : _TransactionList(transactions: txns),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    ]);
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddTransactionDialog(),
    ).then((_) {
      ref.invalidate(transactionsProvider);
      ref.invalidate(transactionsCountProvider);
      ref.invalidate(transactionsSummaryProvider);
      ref.invalidate(recentTransactionsProvider);
    });
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? c.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(color: isSelected ? c : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
            color: isSelected ? c : Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Transaction>>{};
    for (final t in transactions) {
      final key = formatDate(DateTime.parse(t.date));
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: grouped.length,
      itemBuilder: (context, i) {
        final date = grouped.keys.elementAt(i);
        final txns = grouped[date]!;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Text(date, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          ...txns.map((t) => _TransactionRow(transaction: t)),
        ]);
      },
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction transaction;
  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIncome = transaction.isIncome;
    final isTransfer = transaction.isTransfer;
    final color = isTransfer ? AppColors.transfer : (isIncome ? AppColors.income : AppColors.expense);
    final icon = isTransfer ? LucideIcons.arrowLeftRight
        : (isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(transaction.description.isNotEmpty ? transaction.description : transaction.category,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(transaction.category,
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
          ]),
        ),
        Text('${isIncome ? '+' : '-'}${formatCurrency(transaction.amount.abs())}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}
