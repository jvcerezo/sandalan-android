import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../providers/transaction_providers.dart';
import '../widgets/add_transaction_dialog.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  int _selectedTypeTab = 0; // 0=All, 1=Income, 2=Expenses
  final _searchController = TextEditingController();
  bool _showFilters = false;
  String _dateRange = 'all';
  String _categoryFilter = 'All';
  static const _typeLabels = ['All', 'Income', 'Expenses'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(transactionFiltersProvider.notifier).state = TransactionFilters(
      type: _selectedTypeTab == 0 ? null : (_selectedTypeTab == 1 ? 'income' : 'expense'),
      category: _categoryFilter == 'All' ? null : _categoryFilter,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final transactions = ref.watch(transactionsProvider);
    final count = ref.watch(transactionsCountProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        // ← Dashboard back link
        GestureDetector(
          onTap: () => context.go('/dashboard'),
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.arrowLeft, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Dashboard', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),

        // Title + Add button
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Transactions',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
            count.when(
              data: (c) => Text('Manage and review all your financial activity',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ]),
        ]),
        const SizedBox(height: 14),

        // Import CSV button
        OutlinedButton.icon(
          onPressed: () {
            // TODO: CSV import
          },
          icon: const Icon(LucideIcons.upload, size: 16),
          label: const Text('Import CSV'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 14),

        // All / Income / Expenses tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: List.generate(3, (i) => Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedTypeTab = i);
                    _applyFilters();
                  },
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedTypeTab == i ? colorScheme.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: _selectedTypeTab == i ? [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                      ] : null,
                    ),
                    child: Center(child: Text(_typeLabels[i],
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: _selectedTypeTab == i ? colorScheme.onSurface : colorScheme.onSurfaceVariant))),
                  ),
                ),
              ),
            )),
          ),
        ),
        const SizedBox(height: 14),

        // Search + filter card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            // Search row
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(LucideIcons.search, size: 16),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => _applyFilters(),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(LucideIcons.download, size: 18, color: colorScheme.onSurfaceVariant),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showFilters = !_showFilters);
                },
                icon: Icon(LucideIcons.slidersHorizontal, size: 18,
                    color: _showFilters ? colorScheme.primary : colorScheme.onSurfaceVariant),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ]),

            // Expandable filters
            if (_showFilters) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Date Range
              _FilterSection(label: 'DATE RANGE', child: Wrap(
                spacing: 6, runSpacing: 6,
                children: [
                  _FilterPill(label: 'All Time', isSelected: _dateRange == 'all',
                      onTap: () => setState(() => _dateRange = 'all')),
                  _FilterPill(label: 'This Month', isSelected: _dateRange == 'month',
                      onTap: () => setState(() => _dateRange = 'month')),
                  _FilterPill(label: 'Last Month', isSelected: _dateRange == 'lastMonth',
                      onTap: () => setState(() => _dateRange = 'lastMonth')),
                  _FilterPill(label: 'Last 3 Months', isSelected: _dateRange == '3months',
                      onTap: () => setState(() => _dateRange = '3months')),
                ],
              )),
              const SizedBox(height: 12),

              // Category
              _FilterSection(label: 'CATEGORY', child: Wrap(
                spacing: 6, runSpacing: 6,
                children: ['All', ...kCategories].map((c) => _FilterPill(
                  label: c,
                  isSelected: _categoryFilter == c,
                  onTap: () => setState(() => _categoryFilter = c),
                )).toList(),
              )),
              const SizedBox(height: 12),

              // Done button
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    _applyFilters();
                    setState(() => _showFilters = false);
                  },
                  child: Text('Done', style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w600, color: colorScheme.primary)),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 16),

        // Transaction list
        transactions.when(
          data: (txns) {
            if (txns.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(LucideIcons.receipt, size: 40, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('No transactions yet',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('Add your first income or expense to get started.',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ])),
              );
            }

            // Group by date
            final grouped = <String, List<Transaction>>{};
            for (final t in txns) {
              final key = formatDate(DateTime.parse(t.date));
              grouped.putIfAbsent(key, () => []).add(t);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: grouped.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(entry.key, style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
                  ),
                  ...entry.value.map((t) => _TransactionRow(
                    transaction: t,
                    onEdit: () {},
                    onDelete: () async {
                      await ref.read(transactionRepositoryProvider).deleteTransaction(t.id);
                      ref.invalidate(transactionsProvider);
                      ref.invalidate(transactionsCountProvider);
                      ref.invalidate(transactionsSummaryProvider);
                    },
                  )),
                ],
              )).toList(),
            );
          },
          loading: () => const ShimmerList(itemCount: 6),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }
}

// ─── Filter Section ────────────────────────────────────────────────────────────

class _FilterSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _FilterSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
          letterSpacing: 0.8, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      child,
    ]);
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterPill({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant)),
      ),
    );
  }
}

// ─── Transaction Row ───────────────────────────────────────────────────────────

class _TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionRow({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIncome = transaction.isIncome;
    final isTransfer = transaction.isTransfer;
    final iconColor = isTransfer
        ? AppColors.transfer
        : (isIncome ? AppColors.income : colorScheme.onSurfaceVariant);
    final amountColor = isIncome ? AppColors.income : colorScheme.onSurface;
    final icon = isTransfer
        ? LucideIcons.arrowLeftRight
        : (isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight);

    final subtitle = isTransfer
        ? '${transaction.amount > 0 ? 'Incoming' : 'Outgoing'} Transfer · ${formatDateRelative(DateTime.parse(transaction.date))}'
        : '${transaction.category} · ${formatDateRelative(DateTime.parse(transaction.date))}';

    final tags = transaction.tags;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 36, height: 36,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Title + amount row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      transaction.description.isNotEmpty ? transaction.description : transaction.category,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isIncome ? '+' : '-'}${formatCurrency(transaction.amount.abs())}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: amountColor),
                  ),
                ],
              ),
              const SizedBox(height: 2),

              // Subtitle
              Text(subtitle, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),

              // Tags
              if (tags != null && tags.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(spacing: 4, children: tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('#$tag', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                )).toList()),
              ],

              // Action icons row
              const SizedBox(height: 4),
              Row(children: [
                _ActionIcon(icon: LucideIcons.paperclip, onTap: () {}),
                _ActionIcon(icon: LucideIcons.gitBranch, onTap: () {}),
                _ActionIcon(icon: LucideIcons.pencil, onTap: onEdit),
                _ActionIcon(icon: LucideIcons.trash2, onTap: onDelete),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
        child: Icon(icon, size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
      ),
    );
  }
}
