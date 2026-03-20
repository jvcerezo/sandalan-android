import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/theme_color.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/automation_service.dart';
import '../../../app.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/tour_overlay.dart';

// ─── Main Settings Menu ────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _activeSection;

  @override
  Widget build(BuildContext context) {
    if (_activeSection != null) {
      return _buildSection(context);
    }
    return _buildMenu(context);
  }

  Widget _buildMenu(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isGuest = GuestModeService.isGuestSync();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
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
              color: cs.primary.withValues(alpha: 0.08),
              border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(LucideIcons.userPlus, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Create an Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.primary)),
              ]),
              const SizedBox(height: 6),
              Text('Create an account to back up your data and sync across devices.',
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
          _MenuItem(icon: LucideIcons.user, title: 'Profile', sub: 'Name, avatar, email',
              onTap: () => setState(() => _activeSection = 'profile')),
        _MenuItem(icon: LucideIcons.settings2, title: 'Appearance', sub: 'Theme preferences',
            onTap: () => setState(() => _activeSection = 'appearance')),
        _MenuItem(icon: LucideIcons.zap, title: 'Automation', sub: 'Reminders & auto-generation',
            onTap: () => setState(() => _activeSection = 'automation')),
        _MenuItem(icon: LucideIcons.bell, title: 'Notifications', sub: 'Push notification settings',
            onTap: () => setState(() => _activeSection = 'notifications')),
        _MenuItem(icon: LucideIcons.layoutGrid, title: 'Home Page', sub: 'Customize your Home',
            onTap: () => setState(() => _activeSection = 'homepage')),
        _MenuItem(icon: LucideIcons.refreshCw, title: 'Currency', sub: 'Rates & primary currency',
            onTap: () => setState(() => _activeSection = 'currency')),
        if (!isGuest)
          _MenuItem(icon: LucideIcons.shield, title: 'Privacy & Data', sub: 'Export, delete, legal',
              onTap: () => setState(() => _activeSection = 'privacy')),
        _MenuItem(icon: LucideIcons.bug, title: 'Report Bug', sub: 'Report issues',
            onTap: () => setState(() => _activeSection = 'bug')),
        _MenuItem(icon: LucideIcons.logOut, title: 'Account', sub: isGuest ? 'Tour, create account' : 'Sign out, tour, sync',
            onTap: () => setState(() => _activeSection = 'account')),
      ],
    );
  }

  Widget _buildSection(BuildContext context) {
    final back = GestureDetector(
      onTap: () => setState(() => _activeSection = null),
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(LucideIcons.arrowLeft, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('Settings', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );

    Widget content;
    switch (_activeSection) {
      case 'profile': content = _ProfileSection(ref: ref, back: back);
      case 'appearance': content = _AppearanceSection(ref: ref, back: back);
      case 'automation': content = _AutomationSection(back: back);
      case 'notifications': content = _NotificationsSection(back: back);
      case 'homepage': content = _HomePageSection(back: back);
      case 'currency': content = _CurrencySection(ref: ref, back: back);
      case 'privacy': content = _PrivacySection(ref: ref, back: back);
      case 'bug': content = _BugReportSection(ref: ref, back: back);
      case 'account': content = _AccountSection(ref: ref, back: back);
      default: content = const SizedBox.shrink();
    }
    return content;
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon; final String title, sub; final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.title, required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(sub, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ])),
        ]),
      ),
    );
  }
}

class _C extends StatelessWidget {
  final Widget child; const _C({required this.child});
  @override
  Widget build(BuildContext c) => Container(width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(c).colorScheme.surface,
      border: Border.all(color: Theme.of(c).colorScheme.outline.withValues(alpha: 0.12)),
      borderRadius: BorderRadius.circular(14)), child: child);
}

class _ToggleRow extends StatelessWidget {
  final String title, sub; final bool value; final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.title, required this.sub, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ])),
        Switch(value: value, onChanged: onChanged),
      ]));
  }
}

// ─── Profile ───────────────────────────────────────────────────────────────────

class _ProfileSection extends StatelessWidget {
  final WidgetRef ref; final Widget back;
  const _ProfileSection({required this.ref, required this.back});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profile = ref.watch(profileProvider).valueOrNull;
    final nameCtl = TextEditingController(text: profile?.fullName ?? '');

    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      back,
      _C(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Your personal information and account details',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        // Avatar
        Row(children: [
          CircleAvatar(radius: 32, backgroundColor: cs.surfaceContainerHighest,
            backgroundImage: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                ? NetworkImage(profile.avatarUrl!) : null,
            child: profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty
                ? Icon(LucideIcons.user, size: 28, color: cs.onSurfaceVariant) : null),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(profile?.fullName ?? 'User', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text(profile?.email ?? '', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            Row(children: [
              OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 11)), child: const Text('Change Photo')),
              const SizedBox(width: 8),
              GestureDetector(onTap: () {},
                child: Row(children: [
                  Icon(LucideIcons.x, size: 12, color: AppColors.expense),
                  const SizedBox(width: 2),
                  const Text('Remove', style: TextStyle(fontSize: 11, color: AppColors.expense, fontWeight: FontWeight.w500)),
                ])),
            ]),
            Text('JPG, PNG or WebP · Max 2 MB', style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
          ]),
        ]),
        const SizedBox(height: 16), const Divider(),
        const SizedBox(height: 12),
        // Email
        const Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(readOnly: true, decoration: InputDecoration(isDense: true, hintText: profile?.email ?? '')),
        Text('Your email address cannot be changed', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        // Full Name
        const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(controller: nameCtl, decoration: const InputDecoration(isDense: true)),
        const SizedBox(height: 12),
        FilledButton(onPressed: () async {
          await ref.read(profileRepositoryProvider).updateProfile(fullName: nameCtl.text);
          ref.invalidate(profileProvider);
        }, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 0)), child: const Text('Save')),
        const SizedBox(height: 8),
        Text('Member since ${profile?.createdAt.substring(0, 10) ?? ''}',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ])),
    ]);
  }
}

// ─── Appearance ────────────────────────────────────────────────────────────────

class _AppearanceSection extends StatelessWidget {
  final WidgetRef ref; final Widget back;
  const _AppearanceSection({required this.ref, required this.back});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final selectedColor = ref.watch(themeColorProvider);

    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      back,
      _C(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Customize how Sandalan looks on your device',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        const Text('Theme', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(children: [
          _ThemeBtn(icon: LucideIcons.sun, label: 'Light', selected: themeMode == ThemeMode.light,
              onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.light),
          const SizedBox(width: 8),
          _ThemeBtn(icon: LucideIcons.moon, label: 'Dark', selected: themeMode == ThemeMode.dark,
              onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.dark),
          const SizedBox(width: 8),
          _ThemeBtn(icon: LucideIcons.monitor, label: 'System', selected: themeMode == ThemeMode.system,
              onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.system),
        ]),
      ])),
      const SizedBox(height: 12),
      _C(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Accent Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Choose a primary color for buttons, links, and highlights',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (final color in ThemeColor.values)
            _ColorDot(
              color: color,
              selected: selectedColor == color,
              onTap: () => ref.read(themeColorProvider.notifier).setColor(color),
            ),
        ]),
      ])),
      const SizedBox(height: 12),
      _C(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Language / Wika', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Choose your preferred language', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: FilledButton(onPressed: () {}, child: const Text('English'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Filipino'))),
        ]),
      ])),
    ]);
  }
}

class _ColorDot extends StatelessWidget {
  final ThemeColor color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot({required this.color, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayColor = isDark ? color.darkColor : color.lightColor;
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: displayColor,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2.5)
                : Border.all(color: displayColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: selected
                ? [BoxShadow(color: displayColor.withValues(alpha: 0.35), blurRadius: 8, spreadRadius: 1)]
                : null,
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : null,
        ),
        const SizedBox(height: 4),
        Text(color.label, style: TextStyle(fontSize: 10,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

class _ThemeBtn extends StatelessWidget {
  final IconData icon; final String label; final bool selected; final VoidCallback onTap;
  const _ThemeBtn({required this.icon, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return Expanded(child: GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? cs.primary : Colors.transparent,
        border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 14, color: selected ? cs.onPrimary : cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurfaceVariant)),
      ]))));
  }
}

// ─── Automation ────────────────────────────────────────────────────────────────

class _AutomationSection extends StatefulWidget {
  final Widget back; const _AutomationSection({required this.back});
  @override
  State<_AutomationSection> createState() => _AutomationSectionState();
}

class _AutomationSectionState extends State<_AutomationSection> {
  bool _autoContrib = true, _billReminders = true, _debtReminders = true, _insuranceReminders = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoContrib = prefs.getBool(AutomationKeys.autoContributions) ?? true;
      _billReminders = prefs.getBool(AutomationKeys.autoBills) ?? true;
      _debtReminders = prefs.getBool(AutomationKeys.autoDebts) ?? true;
      _insuranceReminders = prefs.getBool(AutomationKeys.autoInsurance) ?? true;
      _loaded = true;
    });
  }

  Future<void> _setAndSave(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    // When a reminder toggle is turned off, cancel related notifications.
    // When turned on, re-run automation to schedule them.
    if (value) {
      await AutomationService.runOnAppStart();
    } else {
      // Cancel all and re-schedule only the still-enabled categories.
      await NotificationService.instance.cancelAll();
      await AutomationService.runOnAppStart();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      widget.back,
      _C(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.zap, size: 18, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 8),
          const Text('Automation & Reminders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        Text('Control which features run automatically and send you reminders',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        _ToggleRow(title: 'Auto-generate monthly contributions',
            sub: 'Create SSS, PhilHealth, and Pag-IBIG entries each month from your last salary',
            value: _autoContrib, onChanged: (v) {
              setState(() => _autoContrib = v);
              _setAndSave(AutomationKeys.autoContributions, v);
            }),
        _ToggleRow(title: 'Bill reminders',
            sub: 'Show upcoming bills on your Home page and send push notifications before due dates',
            value: _billReminders, onChanged: (v) {
              setState(() => _billReminders = v);
              _setAndSave(AutomationKeys.autoBills, v);
            }),
        _ToggleRow(title: 'Debt payment reminders',
            sub: 'Show upcoming debt payments on your Home page and send push notifications',
            value: _debtReminders, onChanged: (v) {
              setState(() => _debtReminders = v);
              _setAndSave(AutomationKeys.autoDebts, v);
            }),
        _ToggleRow(title: 'Insurance premium reminders',
            sub: 'Show upcoming insurance premiums and send push notifications before renewal dates',
            value: _insuranceReminders, onChanged: (v) {
              setState(() => _insuranceReminders = v);
              _setAndSave(AutomationKeys.autoInsurance, v);
            }),
      ])),
    ]);
  }
}

// ─── Notifications ─────────────────────────────────────────────────────────────

class _NotificationsSection extends StatefulWidget {
  final Widget back; const _NotificationsSection({required this.back});
  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  bool _push = true, _morning = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _push = prefs.getBool(AutomationKeys.pushEnabled) ?? true;
      _morning = prefs.getBool(AutomationKeys.morningSummary) ?? true;
      _loaded = true;
    });
  }

  Future<void> _onPushChanged(bool value) async {
    setState(() => _push = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AutomationKeys.pushEnabled, value);

    if (!value) {
      // Turning off push notifications cancels everything.
      await NotificationService.instance.cancelAll();
    } else {
      // Re-request permission and re-schedule.
      await NotificationService.instance.requestPermission();
      await AutomationService.runOnAppStart();
    }
  }

  Future<void> _onMorningChanged(bool value) async {
    setState(() => _morning = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AutomationKeys.morningSummary, value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      widget.back,
      _C(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.bell, size: 18, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 8),
          const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        Text('Push notification preferences (mobile app only)',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        _ToggleRow(title: 'Push notifications',
            sub: 'Receive notifications on your phone for upcoming payments and reminders',
            value: _push, onChanged: _onPushChanged),
        _ToggleRow(title: 'Morning summary',
            sub: 'Get a daily summary of what\'s due today at 9:00 AM',
            value: _morning, onChanged: _onMorningChanged),
      ])),
    ]);
  }
}

// ─── Home Page ─────────────────────────────────────────────────────────────────

class _HomePageSection extends StatefulWidget {
  final Widget back; const _HomePageSection({required this.back});
  @override
  State<_HomePageSection> createState() => _HomePageSectionState();
}

class _HomePageSectionState extends State<_HomePageSection> {
  bool _upcoming = true, _nextSteps = true, _financial = true, _stage = true;
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      widget.back,
      _C(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.layoutGrid, size: 18, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 8),
          const Text('Home Page', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        Text('Choose which sections appear on your Home page',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        _ToggleRow(title: 'Upcoming Payments', sub: 'Show bills, contributions, debts, and insurance due soon',
            value: _upcoming, onChanged: (v) => setState(() => _upcoming = v)),
        _ToggleRow(title: 'Next Steps', sub: 'Show suggested next actions from your adulting journey',
            value: _nextSteps, onChanged: (v) => setState(() => _nextSteps = v)),
        _ToggleRow(title: 'Financial Summary', sub: 'Show balance, income, and expenses at a glance',
            value: _financial, onChanged: (v) => setState(() => _financial = v)),
        _ToggleRow(title: 'Current Life Stage', sub: 'Show your current adulting journey stage and progress',
            value: _stage, onChanged: (v) => setState(() => _stage = v)),
      ])),
    ]);
  }
}

// ─── Currency ──────────────────────────────────────────────────────────────────

class _CurrencySection extends StatelessWidget {
  final WidgetRef ref; final Widget back;
  const _CurrencySection({required this.ref, required this.back});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      back,
      _C(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Currency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Set your primary currency and manage exchange rates',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        const Text('Primary Currency', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(value: 'PHP', isDense: true,
          items: kCurrencies.map((c) => DropdownMenuItem(value: c.code,
              child: Text('${c.symbol} ${c.name} (${c.code})'))).toList(),
          onChanged: (v) {}),
        const SizedBox(height: 12),
        FilledButton(onPressed: () {}, style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12), minimumSize: const Size(double.infinity, 0)),
            child: const Text('Save')),
        const SizedBox(height: 4),
        Text('All amounts on the dashboard will be converted to this currency',
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        Row(children: [
          const Expanded(child: Text('Exchange Rates (to PHP)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          GestureDetector(onTap: () {},
            child: Row(children: [
              Icon(LucideIcons.refreshCw, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Refresh', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ])),
        ]),
        const SizedBox(height: 4),
        Text('Set custom rates or leave blank to use live market rates',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        _RateRow(code: 'USD', rate: '60.1034'),
        _RateRow(code: 'AUD', rate: '42.3513'),
        const SizedBox(height: 6),
        Text('Market rates updated 18h ago', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
      ])),
    ]);
  }
}

class _RateRow extends StatelessWidget {
  final String code, rate;
  const _RateRow({required this.code, required this.rate});
  @override
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 40, child: Text(code, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      const Text('  =  ', style: TextStyle(fontSize: 13)),
      SizedBox(width: 100, child: TextField(
        decoration: InputDecoration(isDense: true, hintText: rate),
        keyboardType: const TextInputType.numberWithOptions(decimal: true))),
      const SizedBox(width: 8),
      const Text('PHP', style: TextStyle(fontSize: 13)),
    ]));
}

// ─── Privacy ───────────────────────────────────────────────────────────────────

class _PrivacySection extends StatefulWidget {
  final WidgetRef ref; final Widget back;
  const _PrivacySection({required this.ref, required this.back});
  @override
  State<_PrivacySection> createState() => _PrivacySectionState();
}

class _PrivacySectionState extends State<_PrivacySection> {
  final _deleteCtl = TextEditingController();
  @override
  void dispose() { _deleteCtl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      widget.back,
      _C(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Privacy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Your data rights and export options under the Data Privacy Act of 2012',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        const Text('Export Your Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Download a full copy of all your data in JSON format — transactions, accounts, budgets, goals, debts, and contributions.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.download, size: 14),
            label: const Text('Download My Data')),
        const SizedBox(height: 16),
        const Text('Legal Documents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        _LegalLink(icon: LucideIcons.externalLink, label: 'Privacy Policy'),
        _LegalLink(icon: LucideIcons.externalLink, label: 'Terms of Service'),
        const SizedBox(height: 8),
        Text('For privacy-related concerns, email privacy@sandalan.com. We will respond within 15 business days.',
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
      ])),
      const SizedBox(height: 16),
      // Danger Zone
      Container(width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.03),
          border: Border.all(color: AppColors.expense.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, size: 16, color: AppColors.expense),
            const SizedBox(width: 6),
            const Text('Danger Zone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.expense)),
          ]),
          Text('Permanent and irreversible actions', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.expense.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Delete Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.expense)),
              const SizedBox(height: 4),
              Text('Permanently deletes your account and all associated data — transactions, accounts, goals, budgets, debts, and contributions. This cannot be undone.',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              const Text('Type DELETE to confirm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextField(controller: _deleteCtl, decoration: const InputDecoration(isDense: true, hintText: 'DELETE'),
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _deleteCtl.text == 'DELETE' ? () async {
                  await widget.ref.read(authRepositoryProvider).deleteAccount();
                  if (context.mounted) context.go('/login');
                } : null,
                style: FilledButton.styleFrom(backgroundColor: AppColors.expense,
                    padding: const EdgeInsets.symmetric(vertical: 12), minimumSize: const Size(double.infinity, 0)),
                child: const Text('Delete My Account Permanently')),
            ])),
        ])),
    ]);
  }
}

class _LegalLink extends StatelessWidget {
  final IconData icon; final String label;
  const _LegalLink({required this.icon, required this.label});
  @override
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(icon, size: 12, color: Theme.of(c).colorScheme.primary),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 13, color: Theme.of(c).colorScheme.primary)),
    ]));
}

// ─── Bug Report ────────────────────────────────────────────────────────────────

class _BugReportSection extends StatelessWidget {
  final WidgetRef ref; final Widget back;
  const _BugReportSection({required this.ref, required this.back});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      back,
      _C(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.bug, size: 18, color: cs.onSurface),
          const SizedBox(width: 8),
          const Text('Report a Bug', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        Text('Found something broken? Send details and it will appear in the admin dashboard.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        const Text('Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        const TextField(decoration: InputDecoration(isDense: true, hintText: 'Short summary of the issue')),
        const SizedBox(height: 10),
        const Text('Severity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(value: 'medium', isDense: true,
          items: ['low', 'medium', 'high', 'critical'].map((s) =>
              DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))).toList(),
          onChanged: (v) {}),
        const SizedBox(height: 10),
        const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        const TextField(maxLines: 4, decoration: InputDecoration(hintText: 'What happened? Include steps to reproduce.')),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: () {},
          icon: const Icon(LucideIcons.send, size: 14), label: const Text('Submit Bug Report'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0))),
      ])),
    ]);
  }
}

// ─── Account ───────────────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  final WidgetRef ref; final Widget back;
  const _AccountSection({required this.ref, required this.back});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isGuest = GuestModeService.isGuestSync();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      back,

      // Guest banner
      if (isGuest) ...[
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.08),
            border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(LucideIcons.userPlus, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text('You\'re in Guest Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.primary)),
            ]),
            const SizedBox(height: 6),
            Text('Your data is stored only on this device. Create an account to back up your data and sync across devices.',
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

      // Offline Outbox (hide for guests)
      if (!isGuest) ...[
        _C(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(LucideIcons.wifi, size: 16, color: cs.onSurface),
            const SizedBox(width: 8),
            const Text('Offline Outbox', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          Text('Review queued offline mutations, retry failed items, or clear stale entries.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            _StatusChip('Pending: 0'), _StatusChip('Syncing: 0'),
            _StatusChip('Failed: 0'), _StatusChip('Conflict: 0'),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            FilledButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.refreshCw, size: 14),
                label: const Text('Sync now'), style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8))),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.trash2, size: 14),
                label: const Text('Clear queue'), style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8))),
          ]),
          const SizedBox(height: 6),
          Text('No queued offline changes.', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ])),
        const SizedBox(height: 12),

        // Conflict Center
        _C(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, size: 16, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('Conflict Center', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          Text('Review sync conflicts and retry or dismiss items after investigation.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          Row(children: [
            _StatusChip('Total conflicts: 0'),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.trash2, size: 12),
                label: const Text('Clear conflicts'), style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    textStyle: const TextStyle(fontSize: 11))),
          ]),
          const SizedBox(height: 6),
          Text('No conflicts detected.', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ])),
        const SizedBox(height: 12),
      ],

      // Account actions
      _C(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Manage your account settings', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () {
          TourController.of(context).start();
        }, icon: const Icon(LucideIcons.compass, size: 16),
            label: const Text('Take a Tour'), style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12), minimumSize: const Size(double.infinity, 0))),
        if (!isGuest) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(LucideIcons.logOut, size: 16, color: AppColors.expense),
            label: const Text('Sign Out', style: TextStyle(color: AppColors.expense)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.expense),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0))),
        ],
      ])),
    ]);
  }
}

class _StatusChip extends StatelessWidget {
  final String label; const _StatusChip(this.label);
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(c).colorScheme.outline.withValues(alpha: 0.15)),
      borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)));
}
