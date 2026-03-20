/// Universal search overlay — searches across all app data.
/// Triggered by the search icon in the app header bar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/utils/formatters.dart';
import '../../data/guide/guide_data.dart';
import '../../features/transactions/providers/transaction_providers.dart';
import '../../features/accounts/providers/account_providers.dart';
import '../../features/budgets/providers/budget_providers.dart';
import '../../features/goals/providers/goal_providers.dart';
import '../../features/tools/providers/tool_providers.dart';

// ─── Search Result Types ────────────────────────────────────────────────────

enum SearchResultType {
  transaction,
  account,
  budget,
  goal,
  bill,
  debt,
  insurance,
  guide,
  checklist,
  tool,
  settings,
}

class SearchResult {
  final SearchResultType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  const SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}

// ─── Static entries (tools, settings, guides, checklists) ───────────────────

const _staticTools = [
  SearchResult(
    type: SearchResultType.tool,
    title: 'All Tools',
    subtitle: 'View all financial tools',
    icon: LucideIcons.wrench,
    route: '/tools',
  ),
  SearchResult(
    type: SearchResultType.tool,
    title: 'Contributions',
    subtitle: 'SSS, PhilHealth, Pag-IBIG tracker',
    icon: LucideIcons.landmark,
    route: '/tools/contributions',
  ),
  SearchResult(
    type: SearchResultType.tool,
    title: 'Bills',
    subtitle: 'Track recurring bills',
    icon: LucideIcons.receipt,
    route: '/tools/bills',
  ),
  SearchResult(
    type: SearchResultType.tool,
    title: 'Debts',
    subtitle: 'Manage loans and credit cards',
    icon: LucideIcons.creditCard,
    route: '/tools/debts',
  ),
  SearchResult(
    type: SearchResultType.tool,
    title: 'Insurance',
    subtitle: 'Track insurance policies',
    icon: LucideIcons.shield,
    route: '/tools/insurance',
  ),
  SearchResult(
    type: SearchResultType.tool,
    title: 'Taxes',
    subtitle: 'Tax computation and records',
    icon: LucideIcons.receipt,
    route: '/tools/taxes',
  ),
  SearchResult(
    type: SearchResultType.tool,
    title: 'Retirement Calculator',
    subtitle: 'Plan your retirement savings',
    icon: LucideIcons.piggyBank,
    route: '/tools/retirement',
  ),
  SearchResult(
    type: SearchResultType.tool,
    title: 'Rent vs Buy',
    subtitle: 'Compare renting and buying a home',
    icon: LucideIcons.home,
    route: '/tools/rent-vs-buy',
  ),
  SearchResult(
    type: SearchResultType.tool,
    title: '13th Month Pay',
    subtitle: 'Calculate 13th month pay',
    icon: LucideIcons.banknote,
    route: '/tools/13th-month',
  ),
  SearchResult(
    type: SearchResultType.tool,
    title: 'Panganay Mode',
    subtitle: 'Family financial support tracker',
    icon: LucideIcons.users,
    route: '/tools/panganay',
  ),
  SearchResult(
    type: SearchResultType.tool,
    title: 'Calculators',
    subtitle: 'Financial calculators',
    icon: LucideIcons.calculator,
    route: '/tools/calculators',
  ),
];

const _staticSettings = [
  SearchResult(
    type: SearchResultType.settings,
    title: 'Settings',
    subtitle: 'App preferences and account settings',
    icon: LucideIcons.settings,
    route: '/settings',
  ),
];

const _staticPages = [
  SearchResult(
    type: SearchResultType.settings,
    title: 'Home',
    subtitle: 'App home screen',
    icon: LucideIcons.home,
    route: '/home',
  ),
  SearchResult(
    type: SearchResultType.settings,
    title: 'Dashboard',
    subtitle: 'Financial overview',
    icon: LucideIcons.layoutDashboard,
    route: '/dashboard',
  ),
  SearchResult(
    type: SearchResultType.settings,
    title: 'Transactions',
    subtitle: 'View all transactions',
    icon: LucideIcons.arrowLeftRight,
    route: '/transactions',
  ),
  SearchResult(
    type: SearchResultType.settings,
    title: 'Accounts',
    subtitle: 'Manage bank accounts',
    icon: LucideIcons.landmark,
    route: '/accounts',
  ),
  SearchResult(
    type: SearchResultType.settings,
    title: 'Budgets',
    subtitle: 'Budget management',
    icon: LucideIcons.pieChart,
    route: '/budgets',
  ),
  SearchResult(
    type: SearchResultType.settings,
    title: 'Goals',
    subtitle: 'Savings goals',
    icon: LucideIcons.target,
    route: '/goals',
  ),
  SearchResult(
    type: SearchResultType.settings,
    title: 'Guide',
    subtitle: 'Adulting journey guide',
    icon: LucideIcons.bookOpen,
    route: '/guide',
  ),
];

// ─── Build guide/checklist results from static data ─────────────────────────

List<SearchResult> _buildGuideResults() {
  final results = <SearchResult>[];
  for (final stage in kLifeStages) {
    for (final guide in stage.guides) {
      results.add(SearchResult(
        type: SearchResultType.guide,
        title: guide.title,
        subtitle: '${guide.category} \u00b7 ${guide.readMinutes} min read',
        icon: LucideIcons.bookOpen,
        route: '/guide/${stage.slug}/${guide.slug}',
      ));
    }
  }
  return results;
}

List<SearchResult> _buildChecklistResults() {
  final results = <SearchResult>[];
  for (final stage in kLifeStages) {
    for (final itemId in stage.checklistItemIds) {
      final item = kChecklistItems[itemId];
      if (item != null) {
        results.add(SearchResult(
          type: SearchResultType.checklist,
          title: item.title,
          subtitle: stage.title,
          icon: LucideIcons.checkCircle2,
          route: '/guide/${stage.slug}/checklist/${item.id}',
        ));
      }
    }
  }
  return results;
}

// ─── Search Overlay ─────────────────────────────────────────────────────────

void showUniversalSearch(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _UniversalSearchSheet(),
  );
}

class _UniversalSearchSheet extends ConsumerStatefulWidget {
  const _UniversalSearchSheet();

  @override
  ConsumerState<_UniversalSearchSheet> createState() => _UniversalSearchSheetState();
}

class _UniversalSearchSheetState extends ConsumerState<_UniversalSearchSheet> {
  final _controller = TextEditingController();
  String _query = '';

  // Pre-build static results once
  late final List<SearchResult> _guideResults = _buildGuideResults();
  late final List<SearchResult> _checklistResults = _buildChecklistResults();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(String text, String query) {
    return text.toLowerCase().contains(query.toLowerCase());
  }

  List<SearchResult> _search(String query) {
    if (query.trim().isEmpty) return [];

    final results = <SearchResult>[];
    final q = query.trim();

    // Search transactions
    final transactions = ref.read(transactionsProvider).valueOrNull ?? [];
    for (final t in transactions) {
      final amountStr = t.amount.abs().toStringAsFixed(2);
      if (_matches(t.description, q) ||
          _matches(t.category, q) ||
          _matches(amountStr, q) ||
          (t.tags != null && t.tags!.any((tag) => _matches(tag, q)))) {
        results.add(SearchResult(
          type: SearchResultType.transaction,
          title: t.description.isNotEmpty ? t.description : t.category,
          subtitle: '${t.amount > 0 ? '+' : '-'}${formatCurrency(t.amount.abs())} \u00b7 ${t.category}',
          icon: t.amount > 0 ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
          route: '/transactions',
        ));
      }
      if (results.length > 50) break;
    }

    // Search accounts
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    for (final a in accounts) {
      if (_matches(a.name, q) || _matches(a.type, q)) {
        results.add(SearchResult(
          type: SearchResultType.account,
          title: a.name,
          subtitle: '${a.type} \u00b7 ${formatCurrency(a.balance, currencyCode: a.currency)}',
          icon: LucideIcons.landmark,
          route: '/accounts',
        ));
      }
    }

    // Search budgets
    final budgets = ref.read(budgetsProvider).valueOrNull ?? [];
    for (final b in budgets) {
      if (_matches(b.category, q)) {
        results.add(SearchResult(
          type: SearchResultType.budget,
          title: b.category,
          subtitle: 'Budget \u00b7 ${formatCurrency(b.amount)}',
          icon: LucideIcons.pieChart,
          route: '/budgets',
        ));
      }
    }

    // Search goals
    final goals = ref.read(goalsProvider).valueOrNull ?? [];
    for (final g in goals) {
      if (_matches(g.name, q) || _matches(g.category, q)) {
        results.add(SearchResult(
          type: SearchResultType.goal,
          title: g.name,
          subtitle: '${g.category} \u00b7 ${formatCurrency(g.currentAmount)} / ${formatCurrency(g.targetAmount)}',
          icon: LucideIcons.target,
          route: '/goals',
        ));
      }
    }

    // Search bills
    final bills = ref.read(billsProvider).valueOrNull ?? [];
    for (final b in bills) {
      if (_matches(b.name, q) || _matches(b.category, q)) {
        results.add(SearchResult(
          type: SearchResultType.bill,
          title: b.name,
          subtitle: '${b.category} \u00b7 ${formatCurrency(b.amount)}',
          icon: LucideIcons.receipt,
          route: '/tools/bills',
        ));
      }
    }

    // Search debts
    final debts = ref.read(debtsProvider).valueOrNull ?? [];
    for (final d in debts) {
      if (_matches(d.name, q) || _matches(d.type, q)) {
        results.add(SearchResult(
          type: SearchResultType.debt,
          title: d.name,
          subtitle: '${d.type} \u00b7 ${formatCurrency(d.currentBalance)}',
          icon: LucideIcons.creditCard,
          route: '/tools/debts',
        ));
      }
    }

    // Search insurance
    final insurance = ref.read(insurancePoliciesProvider).valueOrNull ?? [];
    for (final p in insurance) {
      if (_matches(p.name, q) || _matches(p.type, q)) {
        results.add(SearchResult(
          type: SearchResultType.insurance,
          title: p.name,
          subtitle: '${p.type} \u00b7 ${formatCurrency(p.premiumAmount)}',
          icon: LucideIcons.shield,
          route: '/tools/insurance',
        ));
      }
    }

    // Search guide articles
    for (final r in _guideResults) {
      if (_matches(r.title, q) || _matches(r.subtitle, q)) {
        results.add(r);
      }
    }

    // Search checklist items
    for (final r in _checklistResults) {
      if (_matches(r.title, q) || _matches(r.subtitle, q)) {
        results.add(r);
      }
    }

    // Search tools
    for (final r in _staticTools) {
      if (_matches(r.title, q) || _matches(r.subtitle, q)) {
        results.add(r);
      }
    }

    // Search settings/pages
    for (final r in [..._staticSettings, ..._staticPages]) {
      if (_matches(r.title, q) || _matches(r.subtitle, q)) {
        results.add(r);
      }
    }

    return results;
  }

  String _sectionLabel(SearchResultType type) {
    switch (type) {
      case SearchResultType.transaction: return 'Transactions';
      case SearchResultType.account: return 'Accounts';
      case SearchResultType.budget: return 'Budgets';
      case SearchResultType.goal: return 'Goals';
      case SearchResultType.bill: return 'Bills';
      case SearchResultType.debt: return 'Debts';
      case SearchResultType.insurance: return 'Insurance';
      case SearchResultType.guide: return 'Guide Articles';
      case SearchResultType.checklist: return 'Checklist Items';
      case SearchResultType.tool: return 'Tools';
      case SearchResultType.settings: return 'Pages';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final results = _search(_query);

    // Group by type, preserving order
    final grouped = <SearchResultType, List<SearchResult>>{};
    for (final r in results) {
      grouped.putIfAbsent(r.type, () => []).add(r);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Drag handle
          Center(child: Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 12),
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2)),
          )),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search everything...',
                hintStyle: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                prefixIcon: Icon(LucideIcons.search, size: 18, color: colorScheme.onSurfaceVariant),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                        icon: Icon(LucideIcons.x, size: 16, color: colorScheme.onSurfaceVariant),
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _query.trim().isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(LucideIcons.search, size: 40, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      Text('Search across your app',
                          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('Transactions, accounts, guides, tools, and more',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6))),
                    ]),
                  )
                : results.isEmpty
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(LucideIcons.search, size: 40, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text('No results for "$_query"',
                              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                        ]),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: grouped.length,
                        itemBuilder: (context, sectionIndex) {
                          final entry = grouped.entries.elementAt(sectionIndex);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 6),
                                child: Text(
                                  _sectionLabel(entry.key),
                                  style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              ...entry.value.map((r) => _SearchResultTile(
                                result: r,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context.go(r.route);
                                },
                              )),
                            ],
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}

// ─── Search Result Tile ─────────────────────────────────────────────────────

class _SearchResultTile extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const _SearchResultTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(result.icon, size: 16, color: colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(result.subtitle,
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
          Icon(LucideIcons.chevronRight, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
        ]),
      ),
    );
  }
}
