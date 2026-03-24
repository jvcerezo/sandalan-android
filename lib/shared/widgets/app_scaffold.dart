/// Main app scaffold with:
/// 1. Top header bar (logo + search)
/// 2. Bottom action bar (Income, Expense, Menu, Scan, AI)
/// 3. Full-screen menu overlay

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'brand_mark.dart';
import 'sync_indicator.dart';
import 'universal_search.dart';
import 'tour_overlay.dart';
import 'menu_overlay.dart';
import '../../features/transactions/widgets/add_transaction_dialog.dart';
import '../../features/transactions/screens/receipt_scanner_screen.dart';

class AppScaffold extends StatefulWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  DateTime? _lastBackPress;

  void _showMenuOverlay(BuildContext ctx) {
    HapticFeedback.lightImpact();
    Navigator.of(ctx).push(PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      pageBuilder: (_, __, ___) => const MenuOverlay(),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ));
  }

  void _showAddTransaction(BuildContext ctx, bool isIncome) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionDialog(isIncome: isIncome),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.toString();
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return _NativeBackHandler(
      onBack: () {
        if (location == '/settings') return;

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

          // ─── Bottom Action Bar ─────────────────────────────────────
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
                      height: 56,
                      child: Row(
                        children: [
                          // Income
                          _BottomBarItem(
                            icon: LucideIcons.arrowDownLeft,
                            label: 'Income',
                            color: const Color(0xFF2D8B5E),
                            onTap: () => _showAddTransaction(context, true),
                          ),
                          // Expense
                          _BottomBarItem(
                            icon: LucideIcons.arrowUpRight,
                            label: 'Expense',
                            color: colorScheme.onSurface,
                            onTap: () => _showAddTransaction(context, false),
                          ),
                          // Menu (center, prominent)
                          Expanded(
                            child: InkWell(
                              onTap: () => _showMenuOverlay(context),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      LucideIcons.menu,
                                      size: 20,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Menu',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          // Scan
                          _BottomBarItem(
                            icon: LucideIcons.scanLine,
                            label: 'Scan',
                            color: colorScheme.onSurfaceVariant,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const ReceiptScannerScreen(),
                              ));
                            },
                          ),
                          // AI
                          _BottomBarItem(
                            icon: LucideIcons.messageCircle,
                            label: 'AI',
                            color: colorScheme.onSurfaceVariant,
                            onTap: () => context.go('/chat'),
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

class _BottomBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w500)),
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
