/// Main app scaffold with:
/// 1. Top header bar (logo + search)
/// 2. Context-aware floating action button OR Menu FAB
/// 3. Full-screen menu overlay (replaces nav drawer)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'brand_mark.dart';
import 'context_fab.dart';
import 'sync_indicator.dart';
import 'universal_search.dart';
import 'tour_overlay.dart';
import 'menu_overlay.dart';

class AppScaffold extends StatefulWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  DateTime? _lastBackPress;

  /// Pages where the context FAB should be shown instead of the menu FAB.
  bool _showContextFab(String location) {
    return location.startsWith('/accounts') ||
        location.startsWith('/budgets') ||
        location.startsWith('/goals');
  }

  void _showMenuOverlay(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      pageBuilder: (_, __, ___) => const MenuOverlay(),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.toString();
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final hasModalAbove = ModalRoute.of(context)?.isCurrent != true;

    // Determine which FAB to show
    Widget? fab;
    FloatingActionButtonLocation fabLocation = FloatingActionButtonLocation.centerFloat;

    if (!keyboardVisible && !hasModalAbove) {
      // Menu FAB on ALL screens — this is the primary navigation
      fab = Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: () => _showMenuOverlay(context),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          icon: const Icon(LucideIcons.menu, size: 18),
          label: const Text('Menu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      );
    }

    return _NativeBackHandler(
      onBack: () {
        // Settings handles its own back (sub-sections)
        if (location == '/settings') return;

        if (location == '/home') {
          // On /home → double back to exit
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
          // ANY other screen → go to home
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

                      // Logo (left-aligned) — tap to go home
                      GestureDetector(
                        onTap: () => context.go('/home'),
                        child: const BrandMark(size: 28),
                      ),

                      const Spacer(),

                      // Sync status indicator
                      const SyncIndicator(),

                      // Search
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
        floatingActionButton: fab,
        floatingActionButtonLocation: fabLocation,
      ),
      ),
    );
  }
}

/// Listens for native Android back presses via MethodChannel.
/// This bypasses Flutter's PopScope which doesn't work on Android 13+
/// with predictive back gestures.
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
