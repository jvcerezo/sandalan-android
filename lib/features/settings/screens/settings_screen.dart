import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../widgets/profile_section.dart';
import '../widgets/appearance_section.dart';
import '../widgets/automation_section.dart';
import '../widgets/notifications_section.dart';
import '../widgets/home_page_section.dart';
import '../widgets/currency_section.dart';
import '../widgets/privacy_section.dart';
import '../widgets/bug_report_section.dart';
import '../widgets/account_section.dart';
import '../widgets/feature_visibility_section.dart';
import '../widgets/about_section.dart';

// ─── Main Settings Menu ────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _activeSection;

  void _updateBackHandler() {
    if (_activeSection != null) {
      AppBackHandler.register(() {
        _goBackToMenu();
        return true;
      });
    } else {
      AppBackHandler.unregister();
    }
  }

  @override
  void dispose() {
    AppBackHandler.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _activeSection != null ? _buildSection(context) : _buildMenu(context);
  }

  Widget _buildMenu(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isGuest = GuestModeService.isGuestSync();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        const Text('Settings',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
        const SizedBox(height: 2),
        Text('Manage your account and preferences',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        const SizedBox(height: 20),

        // Guest mode banner
        if (isGuest) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.08),
              border: Border.all(color: cs.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(LucideIcons.userPlus, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Create an Account',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: cs.primary)),
              ]),
              const SizedBox(height: 6),
              Text(
                  'Create an account to back up your data and sync across devices.',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/signup'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: const Text('Create Account'),
              ),
            ]),
          ),
        ],

        if (!isGuest)
          _MenuItem(
              icon: LucideIcons.user,
              title: 'Profile',
              sub: 'Name, avatar, email',
              onTap: () => _goToSection('profile')),
        _MenuItem(
            icon: LucideIcons.settings2,
            title: 'Appearance',
            sub: 'Theme preferences',
            onTap: () => _goToSection('appearance')),
        _MenuItem(
            icon: LucideIcons.zap,
            title: 'Automation',
            sub: 'Reminders & auto-generation',
            onTap: () => _goToSection('automation')),
        _MenuItem(
            icon: LucideIcons.bell,
            title: 'Notifications',
            sub: 'Push notification settings',
            onTap: () => _goToSection('notifications')),
        _MenuItem(
            icon: LucideIcons.layoutGrid,
            title: 'Home Page',
            sub: 'Customize your Home',
            onTap: () => _goToSection('homepage')),
        _MenuItem(
            icon: LucideIcons.eyeOff,
            title: 'Feature Visibility',
            sub: 'Hide features you don\'t need',
            onTap: () => _goToSection('visibility')),
        _MenuItem(
            icon: LucideIcons.refreshCw,
            title: 'Currency',
            sub: 'Rates & primary currency',
            onTap: () => _goToSection('currency')),
        _MenuItem(
            icon: LucideIcons.piggyBank,
            title: 'Salary Allocation',
            sub: 'Auto-split your salary',
            onTap: () => context.push('/salary-allocation')),
        if (!isGuest)
          _MenuItem(
              icon: LucideIcons.shield,
              title: 'Privacy & Data',
              sub: 'Export, delete, legal',
              onTap: () => _goToSection('privacy')),
        _MenuItem(
            icon: LucideIcons.bug,
            title: 'Report Bug',
            sub: 'Report issues',
            onTap: () => _goToSection('bug')),
        _MenuItem(
            icon: LucideIcons.logOut,
            title: 'Account',
            sub: isGuest ? 'Tour, create account' : 'Sign out, tour, sync',
            onTap: () => _goToSection('account')),
        _MenuItem(
            icon: LucideIcons.info,
            title: 'About Sandalan',
            sub: 'Version, credits, legal',
            onTap: () => _goToSection('about')),
      ],
    );
  }

  void _goToSection(String section) {
    setState(() => _activeSection = section);
    _updateBackHandler();
  }

  void _goBackToMenu() {
    setState(() => _activeSection = null);
    _updateBackHandler();
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: _goBackToMenu,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(LucideIcons.arrowLeft,
              size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('Settings',
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }

  Widget _buildSection(BuildContext context) {
    final back = _buildBackButton();

    switch (_activeSection) {
      case 'profile':
        return ProfileSection(back: back);
      case 'appearance':
        return AppearanceSection(back: back);
      case 'automation':
        return AutomationSection(back: back);
      case 'notifications':
        return NotificationsSection(back: back);
      case 'homepage':
        return HomePageSection(back: back);
      case 'visibility':
        return FeatureVisibilitySection(back: back);
      case 'currency':
        return CurrencySection(back: back);
      case 'privacy':
        return PrivacySection(back: back);
      case 'bug':
        return BugReportSection(back: back);
      case 'account':
        return AccountSection(back: back);
      case 'about':
        return AboutSection(back: back);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon, required this.title, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: '$title: $sub',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(children: [
            Icon(icon, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(sub, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ])),
          ]),
        ),
      ),
    );
  }
}
