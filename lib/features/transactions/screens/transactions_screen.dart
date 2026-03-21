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
import '../../../data/models/account.dart';
import '../../accounts/providers/account_providers.dart';
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
    DateTime? startDate;
    DateTime? endDate;
    final now = DateTime.now();

    switch (_dateRange) {
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
      case 'lastMonth':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0);
      case '3months':
        startDate = DateTime(now.year, now.month - 2, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
      case 'all':
      default:
        startDate = null;
        endDate = null;
    }

    ref.read(transactionFiltersProvider.notifier).state = TransactionFilters(
      type: _selectedTypeTab == 0 ? null : (_selectedTypeTab == 1 ? 'income' : 'expense'),
      category: _categoryFilter == 'All' ? null : _categoryFilter,
      search: _searchController.text.isEmpty ? null : _searchController.text,
      startDate: startDate,
      endDate: endDate,
    );
  }

  void _showTransactionDetail(BuildContext context, WidgetRef ref, Transaction t, List<Account> accounts) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTransfer = t.transferId != null;
    final isIncome = !isTransfer && t.amount > 0;
    final accountName = accounts.where((a) => a.id == t.accountId).firstOrNull?.name ?? 'Unknown';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Drag handle
          Center(child: Container(
            width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2)),
          )),

          // Header
          Row(children: [
            const Text('Transaction Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Icon(LucideIcons.x, size: 20, color: colorScheme.onSurfaceVariant),
            ),
          ]),
          const SizedBox(height: 16),

          // Amount
          Text(
            isTransfer
                ? formatCurrency(t.amount.abs())
                : '${isIncome ? '+' : '-'}${formatCurrency(t.amount.abs())}',
            style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w600,
              color: isTransfer ? colorScheme.onSurface : (isIncome ? AppColors.income : colorScheme.onSurface),
            ),
          ),
          const SizedBox(height: 16),

          // Detail rows
          _DetailRow(label: 'Category', value: t.category, colorScheme: colorScheme),
          if (t.description.isNotEmpty)
            _DetailRow(label: 'Description', value: t.description, colorScheme: colorScheme),
          _DetailRow(label: 'Date', value: formatDate(DateTime.parse(t.date)), colorScheme: colorScheme),
          _DetailRow(label: 'Account', value: accountName, colorScheme: colorScheme),
          if (t.tags != null && t.tags!.isNotEmpty)
            _DetailRow(label: 'Tags', value: t.tags!.map((tag) => '#$tag').join(', '), colorScheme: colorScheme),
          const SizedBox(height: 20),

          // Action buttons
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddTransactionDialog(
                    isIncome: isIncome,
                    defaultAccountId: t.accountId,
                    editTransaction: t,
                  ),
                ).then((result) {
                  if (result == true) {
                    ref.invalidate(transactionsProvider);
                    ref.invalidate(transactionsCountProvider);
                    ref.invalidate(transactionsSummaryProvider);
                  }
                });
              },
              icon: const Icon(LucideIcons.pencil, size: 16),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _confirmDelete(context, ref, t);
              },
              icon: Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
              label: Text('Delete', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
              ),
            )),
          ]),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Transaction t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(transactionRepositoryProvider).deleteTransaction(t.id);
              ref.invalidate(transactionsProvider);
              ref.invalidate(transactionsCountProvider);
              ref.invalidate(transactionsSummaryProvider);
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(12),
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
          skipLoadingOnRefresh: true,
          skipLoadingOnReload: true,
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

            // Merge transfer pairs: keep only the outgoing (negative) one
            // and build a display title "Transfer from X to Y"
            final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
            final accountMap = {for (final a in accounts) a.id: a.name};
            final seenTransferIds = <String>{};
            final displayTxns = <Transaction>[];

            for (final t in txns) {
              if (t.isTransfer && t.transferId != null) {
                if (seenTransferIds.contains(t.transferId)) continue;
                seenTransferIds.add(t.transferId!);
                // Find the pair
                final pair = txns.where((x) => x.transferId == t.transferId).toList();
                final outgoing = pair.firstWhere((x) => x.amount < 0, orElse: () => t);
                final incoming = pair.where((x) => x.amount > 0).firstOrNull;

                final fromName = accountMap[outgoing.accountId] ?? 'Account';
                final toName = incoming != null ? (accountMap[incoming.accountId] ?? 'Account') : 'Account';

                // Create a merged display transaction using the outgoing one
                displayTxns.add(Transaction(
                  id: outgoing.id,
                  createdAt: outgoing.createdAt,
                  userId: outgoing.userId,
                  amount: outgoing.amount.abs(), // store as positive for display
                  category: 'Transfer',
                  description: 'Transfer from $fromName to $toName',
                  date: outgoing.date,
                  currency: outgoing.currency,
                  accountId: outgoing.accountId,
                  transferId: outgoing.transferId,
                  tags: outgoing.tags,
                ));
              } else {
                displayTxns.add(t);
              }
            }

            // Group by date
            final grouped = <String, List<Transaction>>{};
            for (final t in displayTxns) {
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
                    accounts: accounts,
                    onTap: () => _showTransactionDetail(context, ref, t, accounts),
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

// ─── Detail Row (used in transaction detail modal) ──────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _DetailRow({required this.label, required this.value, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

// ─── Transaction Row ───────────────────────────────────────────────────────────

class _TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final List<Account> accounts;
  final VoidCallback onTap;

  const _TransactionRow({
    required this.transaction,
    required this.accounts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTransfer = transaction.transferId != null;
    final isIncome = !isTransfer && transaction.amount > 0;
    final iconColor = isTransfer
        ? AppColors.transfer
        : (isIncome ? AppColors.income : colorScheme.onSurfaceVariant);
    final amountColor = isTransfer
        ? colorScheme.onSurface
        : (isIncome ? AppColors.income : colorScheme.onSurface);
    final icon = isTransfer
        ? LucideIcons.arrowLeftRight
        : (isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight);

    final subtitle = isTransfer
        ? 'Transfer \u00b7 ${formatDateRelative(DateTime.parse(transaction.date))}'
        : '${transaction.category} \u00b7 ${formatDateRelative(DateTime.parse(transaction.date))}';

    final tags = transaction.tags;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
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
                      isTransfer
                          ? formatCurrency(transaction.amount.abs())
                          : '${isIncome ? '+' : '-'}${formatCurrency(transaction.amount.abs())}',
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
                      border: Border.all(color: colorScheme.surfaceContainerHighest),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('#$tag', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                  )).toList()),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
