/// 5-tab bottom navigation bar matching the web app's mobile nav.
/// Tabs: Home, Guide, Money, Tools, Settings

import 'package:flutter/material.dart';
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

  // Money group paths
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
    final location =
        GoRouterState.of(context).uri.toString();
    final currentIndex = _currentIndex(location);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        final tab = _tabs[index];
        if (index != currentIndex) {
          context.go(tab.path);
        }
      },
      items: _tabs
          .map((tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ))
          .toList(),
    );
  }
}

class _NavTab {
  final String label;
  final IconData icon;
  final String path;
  const _NavTab({required this.label, required this.icon, required this.path});
}
