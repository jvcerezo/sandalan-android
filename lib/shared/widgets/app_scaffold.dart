/// Main app scaffold with:
/// 1. Top header bar (hamburger + logo + search)
/// 2. Navigation drawer (3 groups: primary, money, tools)
/// 3. Context-aware floating action button

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'brand_mark.dart';
import 'nav_drawer.dart';
import 'context_fab.dart';
import 'sync_indicator.dart';
import 'universal_search.dart';
import 'tour_overlay.dart';

final _scaffoldKey = GlobalKey<ScaffoldState>();

class AppScaffold extends StatefulWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  /// Root tab paths — back button on these should not pop (they're top-level).
  static const _rootPaths = ['/home', '/guide', '/dashboard', '/transactions', '/accounts', '/tools', '/settings', '/achievements', '/reports'];

  DateTime? _lastBackPress;

  bool _isRootPath(String location) {
    return _rootPaths.any((p) => location == p);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.toString();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        // Settings handles its own back (sub-sections)
        if (location == '/settings') return;

        if (location == '/home') {
          // On /home → double back to exit
          final now = DateTime.now();
          if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
            SystemNavigator.pop();
          } else {
            _lastBackPress = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          // ANY other screen → go to home
          context.go('/home');
        }
      },
      child: TourHost(
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const NavDrawer(),
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
                      // Hamburger
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        icon: const Icon(LucideIcons.menu, size: 22),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),

                      // Logo (centered)
                      const Expanded(
                        child: Center(
                          child: BrandMark(size: 28),
                        ),
                      ),

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
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ContextFAB(currentPath: location),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
      ),
    );
  }
}
