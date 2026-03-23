import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'brand_mark.dart';

/// Wraps a full-screen sub-page with the same header bar
/// (hamburger + Sandalan logo + search) as the main app shell.
/// This ensures the navigation header is ALWAYS visible.
class SubPageScaffold extends StatelessWidget {
  final Widget child;

  const SubPageScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Header matching AppScaffold
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: cs.outline.withValues(alpha: 0.08)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.menu, size: 20),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                  const Expanded(child: Center(child: BrandMark(size: 28))),
                  IconButton(
                    icon: const Icon(LucideIcons.search, size: 20),
                    onPressed: () {
                      // TODO: open universal search
                    },
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(child: child),
        ],
      ),
      drawer: null, // Drawer is handled by the parent navigator
    );
  }
}
