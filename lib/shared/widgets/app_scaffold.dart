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

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
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
                        Scaffold.of(context).openDrawer();
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

                    // Search (placeholder)
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // TODO: Command palette / search
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
      floatingActionButton: ContextFAB(currentPath: location),
    );
  }
}
