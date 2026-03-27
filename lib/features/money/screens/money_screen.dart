import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_router.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../transactions/screens/transactions_screen.dart';
import '../../accounts/screens/accounts_screen.dart';
import '../../budgets/screens/budgets_screen.dart';

/// Tracks which Money tab to show. Set by router redirects before
/// navigating to /dashboard.
final moneyTabProvider = StateProvider<int>((ref) => 0);

class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _disposed = false;

  static const _tabs = ['Overview', 'Transactions', 'Accounts', 'Budgets'];

  @override
  void initState() {
    super.initState();
    // Use pending tab from router redirect, then reset it
    final initialTab = pendingMoneyTab.clamp(0, _tabs.length - 1);
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialTab,
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_disposed && !_tabController.indexIsChanging) {
      ref.read(moneyTabProvider.notifier).state = _tabController.index;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Listen for external tab changes (e.g. /transactions redirect sets tab to 1)
    ref.listen<int>(moneyTabProvider, (prev, next) {
      if (!_disposed && _tabController.index != next) {
        final clamped = next.clamp(0, _tabs.length - 1);
        _tabController.animateTo(clamped);
      }
    });

    return Column(
      children: [
        // ─── Tab Bar ─────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            onTap: (_) => HapticFeedback.selectionClick(),
            indicator: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerHeight: 0,
            labelColor: colorScheme.onSurface,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            labelPadding: EdgeInsets.zero,
            tabs: _tabs.map((t) => Tab(height: 32, text: t)).toList(),
          ),
        ),

        // ─── Tab Content ─────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              DashboardScreen(),
              TransactionsScreen(),
              AccountsScreen(),
              BudgetsScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
