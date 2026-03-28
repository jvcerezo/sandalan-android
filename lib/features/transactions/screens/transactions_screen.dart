import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/provider_utils.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/error_retry.dart';
import '../providers/transaction_providers.dart';
import '../../../data/models/account.dart';
import '../../accounts/providers/account_providers.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/transaction_filters_panel.dart';
import '../widgets/export_dialog.dart';
import '../widgets/import_dialog.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTypeTab = 0; // 0=All, 1=Income, 2=Expenses
  final _searchController = TextEditingController();
  bool _showFilters = false;
  String _dateRange = 'all';
  String _categoryFilter = 'All';
  static const _typeLabels = ['All', 'Income', 'Expenses'];
  late final TabController _typeTabController;

  @override
  void initState() {
    super.initState();
    _typeTabController = TabController(length: 3, vsync: this);
    _typeTabController.addListener(() {
      if (!_typeTabController.indexIsChanging && _selectedTypeTab != _typeTabController.index) {
        setState(() => _selectedTypeTab = _typeTabController.index);
        _applyFilters();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _typeTabController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final transactions = ref.watch(transactionsProvider);
    final count = ref.watch(transactionsCountProvider);

    return RefreshIndicator(
      onRefresh: () async {
        invalidateTransactionProviders(ref);
        // Wait for the provider to reload
        await ref.read(transactionsProvider.future);
      },
      child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        // Title + Export button
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Transactions',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
            count.when(
              data: (c) => Text('Manage and review all your financial activity',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ])),
          IconButton(
            icon: Icon(LucideIcons.upload, size: 18, color: colorScheme.onSurfaceVariant),
            tooltip: 'Import CSV',
            onPressed: () => showImportDialog(context),
          ),
          IconButton(
            icon: Icon(LucideIcons.download, size: 18, color: colorScheme.onSurfaceVariant),
            tooltip: 'Export CSV',
            onPressed: () => showExportDialog(context),
          ),
        ]),
        const SizedBox(height: 14),

        // All / Income / Expenses tabs (same style as Money screen tabs)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _typeTabController,
            onTap: (_) => HapticFeedback.selectionClick(),
            indicator: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerHeight: 0,
            labelColor: colorScheme.onSurface,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            labelPadding: EdgeInsets.zero,
            tabs: _typeLabels.map((t) => Tab(height: 32, text: t)).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Search + filter card
        TransactionFiltersPanel(
          searchController: _searchController,
          showFilters: _showFilters,
          dateRange: _dateRange,
          categoryFilter: _categoryFilter,
          onSearch: _applyFilters,
          onToggleFilters: () => setState(() => _showFilters = !_showFilters),
          onDateRangeChanged: (v) {
            setState(() => _dateRange = v);
            _applyFilters();
          },
          onCategoryChanged: (v) {
            setState(() => _categoryFilter = v);
            _applyFilters();
          },
        ),
        // Active filter chips
        if (_dateRange != 'all' || _categoryFilter != 'All' || _searchController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4, children: [
            if (_dateRange != 'all')
              _FilterChip(
                label: _dateRange == 'month' ? 'This month'
                    : _dateRange == 'lastMonth' ? 'Last month'
                    : 'Last 3 months',
                onRemove: () {
                  setState(() => _dateRange = 'all');
                  _applyFilters();
                },
              ),
            if (_categoryFilter != 'All')
              _FilterChip(
                label: _categoryFilter,
                onRemove: () {
                  setState(() => _categoryFilter = 'All');
                  _applyFilters();
                },
              ),
            if (_searchController.text.isNotEmpty)
              _FilterChip(
                label: '"${_searchController.text}"',
                onRemove: () {
                  _searchController.clear();
                  _applyFilters();
                },
              ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _dateRange = 'all';
                  _categoryFilter = 'All';
                  _searchController.clear();
                  _showFilters = false;
                });
                _applyFilters();
              },
              child: Text('Clear all',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: colorScheme.primary)),
            ),
          ]),
        ],
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
                  Icon(LucideIcons.receipt, size: 40, color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
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
                    onTap: () => showTransactionDetailSheet(context, ref, t, accounts),
                  )),
                ],
              )).toList(),
            );
          },
          loading: () => const ShimmerList(itemCount: 6),
          error: (_, __) => ErrorRetry(
            message: 'Could not load transactions',
            onRetry: () => ref.invalidate(transactionsProvider),
          ),
        ),
      ],
    ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.primary)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: Icon(LucideIcons.x, size: 12, color: cs.primary),
        ),
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

    final tags = transaction.tags?.where((tag) =>
      !RegExp(r'^[0-9a-f]{8}-').hasMatch(tag) &&
      !const ['bill', 'debt', 'insurance', 'contribution', 'auto-generated'].contains(tag.toLowerCase())
    ).toList();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36, height: 36,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
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
                  children: [
                    Expanded(
                      child: Text(
                        transaction.description.isNotEmpty ? transaction.description : transaction.category,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
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
