/// Navigation drawer matching the web app's mobile slide-out menu.
/// Groups: Primary (Home, Guide), Money (5 items), Manage (collapsible), Tools (1 item), More (collapsible)
/// Footer: user profile, theme toggle, sign out

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app.dart';
import '../../core/providers/feature_visibility_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/achievements/providers/milestone_providers.dart';
import 'brand_mark.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  final bool showBadge;
  final String? featureKey;
  const _NavItem({required this.label, required this.icon, required this.path, this.showBadge = false, this.featureKey});
}

class _NavGroup {
  final String? label;
  final List<_NavItem> items;
  final bool collapsible;
  const _NavGroup({this.label, required this.items, this.collapsible = false});
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
    _NavItem(label: 'Accounts', icon: LucideIcons.wallet, path: '/accounts'),
    _NavItem(label: 'Budgets', icon: LucideIcons.pieChart, path: '/budgets', featureKey: FeatureKeys.budgets),
    _NavItem(label: 'Goals', icon: LucideIcons.target, path: '/goals', featureKey: FeatureKeys.goals),
  ]),
  // Manage (collapsible)
  const _NavGroup(label: 'MANAGE', collapsible: true, items: [
    _NavItem(label: 'Bills', icon: LucideIcons.receipt, path: '/tools/bills', featureKey: FeatureKeys.bills),
    _NavItem(label: 'Debts', icon: LucideIcons.creditCard, path: '/tools/debts', featureKey: FeatureKeys.debts),
    _NavItem(label: 'Insurance', icon: LucideIcons.shield, path: '/tools/insurance', featureKey: FeatureKeys.insurance),
    _NavItem(label: 'Contributions', icon: LucideIcons.landmark, path: '/tools/contributions', featureKey: FeatureKeys.contributions),
    _NavItem(label: 'Investments', icon: LucideIcons.trendingUp, path: '/investments'),
  ]),
  // Tools
  const _NavGroup(label: 'TOOLS', items: [
    _NavItem(label: 'Calculators', icon: LucideIcons.calculator, path: '/tools'),
  ]),
  // More (collapsible)
  const _NavGroup(label: 'MORE', collapsible: true, items: [
    _NavItem(label: 'Salary Allocation', icon: LucideIcons.wallet, path: '/salary-allocation'),
    _NavItem(label: 'Split Bills', icon: LucideIcons.users, path: '/split-bills'),
    _NavItem(label: 'Reports', icon: LucideIcons.fileText, path: '/reports'),
    _NavItem(label: 'Achievements', icon: LucideIcons.award, path: '/achievements'),
  ]),
];

class NavDrawer extends ConsumerStatefulWidget {
  const NavDrawer({super.key});

  @override
  ConsumerState<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends ConsumerState<NavDrawer> {
  final Map<String, bool> _expandedGroups = {};

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.toString();
    final profile = ref.watch(profileProvider);
    final isGuest = ref.watch(isGuestProvider);
    final fullName = isGuest ? 'Guest' : (profile.valueOrNull?.fullName ?? 'User');
    final email = isGuest ? 'Create account to sync' : (profile.valueOrNull?.email ?? '');
    final themeMode = ref.watch(themeModeProvider);
    final visibility = ref.watch(featureVisibilityProvider);

    return Drawer(
      width: 288,
      backgroundColor: colorScheme.surface,
      child: Column(
        children: [
          // --- Header ---
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

          // --- Nav Items ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final group in _navGroups) ...[
                  if (group.label != null) ...[
                    const SizedBox(height: 16),
                    if (group.collapsible)
                      _CollapsibleGroupHeader(
                        label: group.label!,
                        isExpanded: _expandedGroups[group.label] ?? false,
                        onTap: () => setState(() {
                          _expandedGroups[group.label!] = !(_expandedGroups[group.label!] ?? false);
                        }),
                        colorScheme: colorScheme,
                      )
                    else
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
                  // Show items: always for non-collapsible, only when expanded for collapsible
                  if (!group.collapsible || (_expandedGroups[group.label] ?? false))
                    for (final item in group.items)
                      if (item.featureKey == null || (visibility[item.featureKey] ?? true))
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

          // --- Footer ---
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

                    // Guest: only Create Account (no sign out)
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

class _CollapsibleGroupHeader extends StatelessWidget {
  final String label;
  final bool isExpanded;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _CollapsibleGroupHeader({
    required this.label,
    required this.isExpanded,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 6, right: 12),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
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
