/// Full-screen menu overlay with staggered animations.
/// Replaces the navigation drawer with a GoTyme-style overlay menu.

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/router/app_router.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuOverlay extends StatefulWidget {
  const MenuOverlay({super.key});

  @override
  State<MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<MenuOverlay> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _closeRotation;

  static const _favoritesKey = 'menu_favorites';
  static const _maxFavorites = 6;
  List<String> _favorites = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _closeRotation = Tween<double>(begin: 0.125, end: 0.0)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));
    _controller.forward();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favoritesKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List;
        setState(() {
          _favorites = decoded.cast<String>();
        });
      } catch (_) {}
    }
    if (_favorites.isEmpty) {
      _favorites = ['/home', '/dashboard', '/guide', '/settings'];
      _saveFavorites();
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoritesKey, jsonEncode(_favorites));
  }

  Future<void> _toggleFavorite(String route) async {
    setState(() {
      if (_favorites.contains(route)) {
        _favorites.remove(route);
      } else if (_favorites.length < _maxFavorites) {
        _favorites.add(route);
      }
    });
    await _saveFavorites();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _groupFade(int index) {
    final start = 0.1 + (index * 0.1);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _groupSlide(int index) {
    final start = 0.1 + (index * 0.1);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    ));
  }

  Future<void> _close() async {
    await _controller.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  void _navigate(String route) {
    final nav = Navigator.of(context);
    _controller.reverse().then((_) {
      if (mounted) nav.pop();
      // Use the global router since overlay is outside GoRouter tree
      appRouter.go(route);
    });
  }

  void _openSheet(Widget sheet) {
    // Capture the navigator before reversing, since context may change after pop.
    final nav = Navigator.of(context);
    _controller.reverse().then((_) {
      if (mounted) nav.pop();
      // Use the root navigator context for showing sheets after overlay is gone
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navContext = rootNavigatorKey.currentContext;
        if (navContext != null) {
          showModalBottomSheet(
            context: navContext,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => sheet,
          );
        }
      });
    });
  }

  /// Shows a dialog to add/remove a menu item from favorites.
  void _showFavoriteDialog(String route, String label) {
    final isFav = _favorites.contains(route);
    final isFull = !isFav && _favorites.length >= _maxFavorites;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isFav ? 'Remove from Favorites?' : 'Add to Favorites?'),
        content: isFull
            ? const Text('You can only have 6 favorites. Remove one first.')
            : Text(isFav
                ? 'Remove "$label" from your favorites?'
                : 'Pin "$label" to your favorites for quick access?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          if (!isFull || isFav)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _toggleFavorite(route);
              },
              child: Text(isFav ? 'Remove' : 'Add'),
            ),
        ],
      ),
    );
  }

  /// Find a menu item's data by route across all groups.
  _MenuItemData? _findMenuItem(String route, List<_MenuGroupData> groups) {
    for (final group in groups) {
      for (final item in group.items) {
        if (item.route == route) return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final menuGroups = [
      _MenuGroupData(title: 'Adulting', items: [
        _MenuItemData(icon: LucideIcons.bookOpen, label: 'Guide', route: '/guide'),
        _MenuItemData(icon: LucideIcons.landmark, label: 'Gov\'t', route: '/tools/contributions'),
        _MenuItemData(icon: LucideIcons.fileText, label: 'Taxes', route: '/tools/taxes'),
        _MenuItemData(icon: LucideIcons.gift, label: '13th Month', route: '/tools/13th-month'),
      ]),
      _MenuGroupData(title: 'Money', items: [
        _MenuItemData(icon: LucideIcons.home, label: 'Home', route: '/home'),
        _MenuItemData(icon: LucideIcons.barChart3, label: 'Dashboard', route: '/dashboard'),
        _MenuItemData(icon: LucideIcons.arrowLeftRight, label: 'Transactions', route: '/transactions'),
        _MenuItemData(icon: LucideIcons.wallet, label: 'Accounts', route: '/accounts'),
        _MenuItemData(icon: LucideIcons.pieChart, label: 'Budgets', route: '/budgets'),
        _MenuItemData(icon: LucideIcons.target, label: 'Goals', route: '/goals'),
        _MenuItemData(icon: LucideIcons.trendingUp, label: 'Investments', route: '/investments'),
        _MenuItemData(icon: LucideIcons.banknote, label: 'Salary', route: '/salary-allocation'),
      ]),
      _MenuGroupData(title: 'Manage', items: [
        _MenuItemData(icon: LucideIcons.receipt, label: 'Bills', route: '/tools/bills'),
        _MenuItemData(icon: LucideIcons.creditCard, label: 'Debts', route: '/tools/debts'),
        _MenuItemData(icon: LucideIcons.shield, label: 'Insurance', route: '/tools/insurance'),
        _MenuItemData(icon: LucideIcons.users, label: 'Split Bills', route: '/split-bills'),
      ]),
      _MenuGroupData(title: 'Tools & More', items: [
        _MenuItemData(icon: LucideIcons.globe, label: 'Currency', route: '/tools/currency'),
        _MenuItemData(icon: LucideIcons.sunset, label: 'Retirement', route: '/tools/retirement'),
        _MenuItemData(icon: LucideIcons.home, label: 'Rent vs Buy', route: '/tools/rent-vs-buy'),
        _MenuItemData(icon: LucideIcons.users, label: 'Panganay', route: '/tools/panganay'),
        _MenuItemData(icon: LucideIcons.calculator, label: 'Calculators', route: '/tools/calculators'),
        _MenuItemData(icon: LucideIcons.fileText, label: 'Reports', route: '/reports'),
        _MenuItemData(icon: LucideIcons.award, label: 'Achievements', route: '/achievements'),
        _MenuItemData(icon: LucideIcons.settings, label: 'Settings', route: '/settings'),
      ]),
    ];

    const currentLocation = ''; // Overlay is outside GoRouter tree

    return FadeTransition(
      opacity: _fadeIn,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Blurred dark backdrop
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: Colors.black.withValues(alpha: 0.85)),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  children: [
                    // Close button (top right)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8, top: 4),
                        child: RotationTransition(
                          turns: _closeRotation,
                          child: IconButton(
                            onPressed: _close,
                            icon: const Icon(LucideIcons.x, size: 24),
                            color: Colors.white,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              shape: const CircleBorder(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Favorites section
                    _FavoritesRow(
                      favorites: _favorites,
                      menuGroups: menuGroups,
                      findMenuItem: _findMenuItem,
                      onTap: _navigate,
                      onLongPress: (route, label) => _showFavoriteDialog(route, label),
                    ),

                    const SizedBox(height: 8),

                    // Feature grid cards
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: menuGroups.length,
                        itemBuilder: (context, index) {
                          final group = menuGroups[index];
                          return SlideTransition(
                            position: _groupSlide(index),
                            child: FadeTransition(
                              opacity: _groupFade(index),
                              child: _MenuGroup(
                                data: group,
                                currentRoute: currentLocation,
                                onItemTap: _navigate,
                                onItemLongPress: _showFavoriteDialog,
                                favorites: _favorites,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data classes ──────────────────────────────────────────────

class _MenuGroupData {
  final String title;
  final List<_MenuItemData> items;
  const _MenuGroupData({required this.title, required this.items});
}

class _MenuItemData {
  final IconData icon;
  final String label;
  final String route;
  const _MenuItemData({required this.icon, required this.label, required this.route});
}

// ─── Favorites Row ────────────────────────────────────────────

class _FavoritesRow extends StatelessWidget {
  final List<String> favorites;
  final List<_MenuGroupData> menuGroups;
  final _MenuItemData? Function(String route, List<_MenuGroupData> groups) findMenuItem;
  final ValueChanged<String> onTap;
  final void Function(String route, String label) onLongPress;

  const _FavoritesRow({
    required this.favorites,
    required this.menuGroups,
    required this.findMenuItem,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FAVORITES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          if (favorites.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Long-press any item to pin it here',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.3),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: favorites.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final route = favorites[index];
                  final item = findMenuItem(route, menuGroups);
                  if (item == null) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(route);
                    },
                    onLongPress: () {
                      HapticFeedback.lightImpact();
                      onLongPress(route, item.label);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, size: 16, color: cs.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Menu Group Widget ─────────────────────────────────────────

class _MenuGroup extends StatelessWidget {
  final _MenuGroupData data;
  final String currentRoute;
  final ValueChanged<String> onItemTap;
  final void Function(String route, String label) onItemLongPress;
  final List<String> favorites;

  const _MenuGroup({
    required this.data,
    required this.currentRoute,
    required this.onItemTap,
    required this.onItemLongPress,
    required this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                data.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Divider(
              height: 16,
              thickness: 1,
              color: cs.outline.withValues(alpha: 0.08),
              indent: 16,
              endIndent: 16,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 2,
                crossAxisSpacing: 0,
                childAspectRatio: 0.85,
                children: [
                  for (final item in data.items)
                    _MenuItem(
                      data: item,
                      isActive: currentRoute == item.route ||
                          (item.route != '/' &&
                              currentRoute.startsWith(item.route) &&
                              item.route.length > 1),
                      isFavorite: favorites.contains(item.route),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onItemTap(item.route);
                      },
                      onLongPress: () {
                        HapticFeedback.lightImpact();
                        onItemLongPress(item.route, item.label);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Menu Item Widget ──────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final _MenuItemData data;
  final bool isActive;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MenuItem({
    required this.data,
    required this.isActive,
    required this.isFavorite,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isActive
                        ? cs.primary.withValues(alpha: 0.15)
                        : cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    data.icon,
                    size: 20,
                    color: isActive ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
                if (isFavorite)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surfaceContainer, width: 1.5),
                      ),
                      child: const Icon(LucideIcons.star, size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              data.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
