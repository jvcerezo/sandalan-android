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
import 'universal_search.dart';
import 'tour_overlay.dart';

final _scaffoldKey = GlobalKey<ScaffoldState>();

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  /// Root tab paths — back button on these should not pop (they're top-level).
  static const _rootPaths = ['/home', '/guide', '/dashboard', '/tools', '/settings'];

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
        if (_isRootPath(location)) {
          // On root tab, go to /home or let system handle
          if (location != '/home') {
            context.go('/home');
          }
          // On /home, do nothing — don't close app
        } else {
          // On sub-page, navigate back
          if (context.canPop()) {
            context.pop();
          } else {
            // Fallback: go to parent route
            final segments = location.split('/');
            if (segments.length > 2) {
              context.go(segments.sublist(0, segments.length - 1).join('/'));
            } else {
              context.go('/home');
            }
          }
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
            Expanded(child: child),
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
