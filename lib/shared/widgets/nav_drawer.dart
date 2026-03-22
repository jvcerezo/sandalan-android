/// Navigation drawer matching the web app's mobile slide-out menu.
/// 3 groups: Primary (Home, Guide), Money (5 items), Tools (9 items)
/// Footer: user profile, theme toggle, sign out

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/achievements/providers/milestone_providers.dart';
import 'brand_mark.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  final bool showBadge;
  const _NavItem({required this.label, required this.icon, required this.path, this.showBadge = false});
}

class _NavGroup {
  final String? label;
  final List<_NavItem> items;
  const _NavGroup({this.label, required this.items});
}

final _navGroups = [
  // Primary
  const _NavGroup(items: [
    _NavItem(label: 'Home', icon: LucideIcons.home, path: '/home'),
    _NavItem(label: 'Guide', icon: LucideIcons.bookOpen, path: '/guide'),
  ]),
  // Money
  const _NavGroup(label: 'MONEY', items: [
    _NavItem(label: 'Dashboard', icon: LucideIcons.barChart3, path: '/dashboard'),
    _NavItem(label: 'Transactions', icon: LucideIcons.arrowLeftRight, path: '/transactions'),
    _NavItem(label: 'My Finances', icon: LucideIcons.wallet, path: '/accounts'),
    _NavItem(label: 'Budgets', icon: LucideIcons.pieChart, path: '/budgets'),
    _NavItem(label: 'Goals', icon: LucideIcons.target, path: '/goals'),
  ]),
  // Manage
  const _NavGroup(label: 'MANAGE', items: [
    _NavItem(label: 'Bills', icon: LucideIcons.receipt, path: '/tools/bills'),
    _NavItem(label: 'Debts', icon: LucideIcons.creditCard, path: '/tools/debts'),
    _NavItem(label: 'Insurance', icon: LucideIcons.shield, path: '/tools/insurance'),
    _NavItem(label: 'Contributions', icon: LucideIcons.landmark, path: '/tools/contributions'),
    _NavItem(label: 'Investments', icon: LucideIcons.trendingUp, path: '/investments'),
  ]),
  // Tools
  const _NavGroup(label: 'TOOLS', items: [
    _NavItem(label: 'Calculators', icon: LucideIcons.calculator, path: '/tools'),
  ]),
  // More
  const _NavGroup(label: 'MORE', items: [
    _NavItem(label: 'Salary Allocation', icon: LucideIcons.wallet, path: '/salary-allocation'),
    _NavItem(label: 'Split Bills', icon: LucideIcons.users, path: '/split-bills'),
    _NavItem(label: 'Reports', icon: LucideIcons.fileText, path: '/reports'),
    _NavItem(label: 'Achievements', icon: LucideIcons.award, path: '/achievements'),
  ]),
];

class NavDrawer extends ConsumerWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.toString();
    final profile = ref.watch(profileProvider);
    final isGuest = ref.watch(isGuestProvider);
    final fullName = isGuest ? 'Guest' : (profile.valueOrNull?.fullName ?? 'User');
    final email = isGuest ? 'Create account to sync' : (profile.valueOrNull?.email ?? '');
    final themeMode = ref.watch(themeModeProvider);

    return Drawer(
      width: 288,
      backgroundColor: colorScheme.surface,
      child: Column(
        children: [
          // ─── Header ──────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: const Row(
                children: [BrandMark(size: 28)],
              ),
            ),
          ),

          // ─── Nav Items ───────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final group in _navGroups) ...[
                  if (group.label != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 6),
                      child: Text(
                        group.label!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                  for (final item in group.items)
                    _DrawerNavItem(
                      item: item,
                      isActive: location == item.path ||
                          (item.path != '/' && location.startsWith(item.path) && item.path.length > 1),
                      showBadge: item.path == '/achievements' && (ref.watch(hasNewMilestonesProvider).valueOrNull ?? false),
                    ),
                ],
              ],
            ),
          ),

          // ─── Footer ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  children: [
                    // User profile
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/settings');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            _buildAvatar(profile.valueOrNull?.avatarUrl, fullName, colorScheme),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(fullName,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(email,
                                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    const SizedBox(height: 8),

                    // Theme section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Text('THEME',
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              )),
                          const Spacer(),
                          Semantics(
                            label: 'Toggle theme, currently ${themeMode == ThemeMode.dark ? 'dark' : 'light'}',
                            button: true,
                            child: InkWell(
                              onTap: () {
                                final current = ref.read(appThemeModeProvider);
                                ref.read(appThemeModeProvider.notifier).setMode(
                                    current == AppThemeMode.light ? AppThemeMode.dark : AppThemeMode.light);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  themeMode == ThemeMode.dark ? LucideIcons.moon : LucideIcons.sun,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Settings
                    _DrawerFooterItem(
                      icon: LucideIcons.settings,
                      label: 'Settings',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/settings');
                      },
                    ),

                    // Guest: only Create Account (no sign out — commit or stay!)
                    if (isGuest)
                      _DrawerFooterItem(
                        icon: LucideIcons.userPlus,
                        label: 'Create Account',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/signup');
                        },
                      )
                    else
                      _DrawerFooterItem(
                        icon: LucideIcons.logOut,
                        label: 'Sign Out',
                        onTap: () {
                          Navigator.of(context).pop();
                          // Don't destroy session — just navigate to login
                          // Quick login card will let them back in instantly
                          context.go('/login');
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String fullName, ColorScheme colorScheme) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
        backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
      child: Text(
        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.primary),
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool showBadge;

  const _DrawerNavItem({required this.item, required this.isActive, this.showBadge = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        label: '${item.label}${isActive ? ', current page' : ''}',
        button: true,
        selected: isActive,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pop();
            context.go(item.path);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? colorScheme.primary.withValues(alpha: 0.1) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      item.icon,
                      size: 18,
                      color: isActive ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                    if (showBadge)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isActive ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerFooterItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerFooterItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
