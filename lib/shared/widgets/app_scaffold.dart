/// Main app scaffold with:
/// 1. Top header bar (logo + search)
/// 2. Bottom tab bar (Home, Guide, +, Money, More)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'brand_mark.dart';
import 'sync_indicator.dart';
import 'universal_search.dart';
import 'tour_overlay.dart';
import '../../features/transactions/widgets/add_transaction_dialog.dart';

class AppScaffold extends StatefulWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  DateTime? _lastBackPress;

  void _showAddTransaction(BuildContext ctx) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionDialog(isIncome: false),
    );
  }

  /// Paths grouped under each tab for highlight logic.
  static const _moneyPaths = [
    '/dashboard',
    '/transactions',
    '/accounts',
    '/budgets',
    '/goals',
    '/investments',
    '/salary-allocation',
  ];

  static const _morePaths = [
    '/more',
    '/tools',
    '/split-bills',
    '/achievements',
    '/reports',
    '/settings',
    '/chat',
  ];

  int _tabIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/guide')) return 1;
    if (_moneyPaths.any((p) => location.startsWith(p))) return 3;
    if (_morePaths.any((p) => location.startsWith(p))) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.toString();
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final currentTab = _tabIndex(location);

    return _NativeBackHandler(
      onBack: () {
        if (location == '/settings' || location == '/more') return;

        if (location == '/home') {
          final now = DateTime.now();
          if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
            SystemNavigator.pop();
          } else {
            _lastBackPress = now;
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Press back again to exit'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } else {
          context.go('/home');
        }
      },
      child: TourHost(
        child: Scaffold(
          body: Column(
            children: [
              // ─── Top Header Bar ──────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.95),
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => context.go('/home'),
                          child: const BrandMark(size: 28),
                        ),
                        const Spacer(),
                        const SyncIndicator(),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            showUniversalSearch(context);
                          },
                          icon: const Icon(LucideIcons.search, size: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Page Content ────────────────────────────────────────
              Expanded(child: widget.child),
            ],
          ),

          // ─── Bottom Tab Bar ──────────────────────────────────────
          bottomNavigationBar: keyboardVisible
              ? null
              : Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 64,
                      child: Row(
                        children: [
                          // Home
                          _TabItem(
                            icon: LucideIcons.home,
                            label: 'Home',
                            isActive: currentTab == 0,
                            onTap: () => context.go('/home'),
                          ),
                          // Guide
                          _TabItem(
                            icon: LucideIcons.bookOpen,
                            label: 'Guide',
                            isActive: currentTab == 1,
                            onTap: () => context.go('/guide'),
                          ),
                          // Add (+) center button
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showAddTransaction(context),
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      LucideIcons.plus,
                                      size: 22,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Money
                          _TabItem(
                            icon: LucideIcons.wallet,
                            label: 'Money',
                            isActive: currentTab == 3,
                            onTap: () => context.go('/dashboard'),
                          ),
                          // More
                          _TabItem(
                            icon: LucideIcons.menu,
                            label: 'More',
                            isActive: currentTab == 4,
                            onTap: () => context.go('/more'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isActive
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isActive) {
            HapticFeedback.selectionClick();
            onTap();
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Listens for native Android back presses via MethodChannel.
class _NativeBackHandler extends StatefulWidget {
  final VoidCallback onBack;
  final Widget child;
  const _NativeBackHandler({required this.onBack, required this.child});

  @override
  State<_NativeBackHandler> createState() => _NativeBackHandlerState();
}

class _NativeBackHandlerState extends State<_NativeBackHandler> {
  static const _channel = MethodChannel('com.jvcerezo.sandalan/back');

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onBackPressed') {
        widget.onBack();
      }
    });
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
