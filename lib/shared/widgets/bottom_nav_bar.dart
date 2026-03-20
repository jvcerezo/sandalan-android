/// 5-tab bottom navigation bar matching the web app's mobile bottom nav.
/// Tabs: Home, Guide, Money, Tools, Settings
/// Active state uses primary/12 bg with primary text color.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  static final _tabs = [
    _NavTab(label: 'Home', icon: LucideIcons.home, path: '/home'),
    _NavTab(label: 'Guide', icon: LucideIcons.bookOpen, path: '/guide'),
    _NavTab(label: 'Money', icon: LucideIcons.wallet, path: '/dashboard'),
    _NavTab(label: 'Tools', icon: LucideIcons.wrench, path: '/tools'),
    _NavTab(label: 'Settings', icon: LucideIcons.settings, path: '/settings'),
  ];

  static const _moneyPaths = [
    '/dashboard',
    '/transactions',
    '/accounts',
    '/budgets',
    '/goals',
  ];

  int _currentIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/guide')) return 1;
    if (_moneyPaths.any((p) => location.startsWith(p))) return 2;
    if (location.startsWith('/tools')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _currentIndex(location);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: _tabs.asMap().entries.map((entry) {
              final i = entry.key;
              final tab = entry.value;
              final isActive = i == currentIndex;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!isActive) {
                      HapticFeedback.selectionClick();
                      context.go(tab.path);
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
                        child: Icon(
                          tab.icon,
                          size: 20,
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final String label;
  final IconData icon;
  final String path;
  const _NavTab({required this.label, required this.icon, required this.path});
}
