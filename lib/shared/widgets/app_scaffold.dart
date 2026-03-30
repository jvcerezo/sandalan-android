/// Main app scaffold with:
/// 1. Top header bar (logo + search)
/// 2. Bottom tab bar (Home, Guide, +, Money, More)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'brand_mark.dart';
import 'sync_indicator.dart';
import '../utils/snackbar_helper.dart';
import 'universal_search.dart';
import 'tour_overlay.dart';
import '../../features/transactions/widgets/add_transaction_dialog.dart';
import '../../features/transactions/screens/receipt_scanner_screen.dart';
import '../../core/services/premium_service.dart';

/// Allows child screens to register a custom back handler.
/// When set, the AppScaffold will call this before its default back behavior.
/// Return true if the handler consumed the back press, false to fall through.
class AppBackHandler {
  static bool Function()? _handler;

  static void register(bool Function() handler) => _handler = handler;
  static void unregister() => _handler = null;

  /// Returns true if a registered handler consumed the back press.
  static bool tryHandle() {
    if (_handler != null) return _handler!();
    return false;
  }
}

class AppScaffold extends StatefulWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  DateTime? _lastBackPress;

  void _showQuickActions(BuildContext ctx) {
    HapticFeedback.lightImpact();
    final cs = Theme.of(ctx).colorScheme;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final bottomPadding = MediaQuery.of(sheetCtx).padding.bottom;
        return Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 16),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Add Expense
                Expanded(
                  child: _QuickActionTile(
                    icon: LucideIcons.arrowUpRight,
                    label: 'Expense',
                    delay: 0,
                    color: cs.onSurface,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      showModalBottomSheet(
                        context: ctx,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AddTransactionDialog(isIncome: false),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Add Income
                Expanded(
                  child: _QuickActionTile(
                    icon: LucideIcons.arrowDownLeft,
                    label: 'Income',
                    delay: 1,
                    color: const Color(0xFF2D8B5E),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      showModalBottomSheet(
                        context: ctx,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AddTransactionDialog(isIncome: true),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Scan Receipt
                Expanded(
                  child: _QuickActionTile(
                    icon: LucideIcons.scanLine,
                    label: 'Scan',
                    delay: 2,
                    color: cs.primary,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      if (PremiumService.instance.hasAccess(PremiumFeature.receiptScanner)) {
                        Navigator.of(ctx).push(MaterialPageRoute(
                          builder: (_) => const ReceiptScannerScreen(),
                        ));
                      } else {
                        showPremiumGateWithPaywall(ctx, PremiumFeature.receiptScanner);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      },
    );
  }

  /// Paths grouped under each tab for highlight logic.
  static const _moneyPaths = [
    '/dashboard',
    '/transactions',
    '/accounts',
    '/budgets',
    '/goals',
  ];

  static const _morePaths = [
    '/more',
    '/tools',
    '/investments',
    '/salary-allocation',
    '/split-bills',
    '/achievements',
    '/reports',
    '/settings',
    '/chat',
    '/vault',
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
        // Let child screens handle back first (e.g. settings subsections)
        if (AppBackHandler.tryHandle()) return;

        if (location == '/home') {
          final now = DateTime.now();
          if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
            SystemNavigator.pop();
          } else {
            _lastBackPress = now;
            showAppSnackBar(context, 'Press back again to exit');
          }
        } else if (location == '/dashboard') {
          context.go('/home');
        } else if (_moneyPaths.any((p) => p != '/dashboard' && location.startsWith(p))) {
          // Money children (goals, transactions, accounts, budgets) go back to dashboard
          context.go('/dashboard');
        } else if (location == '/more') {
          context.go('/home');
        } else if (_morePaths.any((p) => p != '/more' && location.startsWith(p))) {
          // More children go back to More
          context.go('/more');
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
                  color: colorScheme.surface.withOpacity(0.95),
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outline.withOpacity(0.15),
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
                        Semantics(
                          label: 'Home',
                          button: true,
                          child: GestureDetector(
                            onTap: () => context.go('/home'),
                            child: const BrandMark(size: 28),
                          ),
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
                        color: colorScheme.outline.withOpacity(0.15),
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
                            child: Semantics(
                              label: 'Add transaction',
                              button: true,
                              child: GestureDetector(
                              onTap: () => _showQuickActions(context),
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
        : colorScheme.onSurfaceVariant.withOpacity(0.5);

    return Expanded(
      child: Semantics(
        label: '$label tab${isActive ? ', selected' : ''}',
        button: true,
        selected: isActive,
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
                    ? colorScheme.primary.withOpacity(0.12)
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
      ),
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    this.delay = 0,
    required this.onTap,
  });

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scale = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: 60 * widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Semantics(
          label: 'Add ${widget.label}',
          button: true,
          child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 24, color: widget.color),
                const SizedBox(height: 6),
                Text(widget.label,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: widget.color)),
              ],
            ),
          ),
        ),
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
