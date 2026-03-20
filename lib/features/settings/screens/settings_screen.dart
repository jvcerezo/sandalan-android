import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final profile = ref.watch(profileProvider);
    final fullName = profile.valueOrNull?.fullName ?? 'User';
    final email = profile.valueOrNull?.email ?? '';
    final avatarUrl = profile.valueOrNull?.avatarUrl;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),

        // Profile section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Icon(LucideIcons.user, color: colorScheme.onSurfaceVariant) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(fullName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(email,
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Appearance
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('APPEARANCE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                      letterSpacing: 1.2, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Row(children: [
                _ThemeButton(label: 'Light', icon: LucideIcons.sun,
                    isSelected: themeMode == ThemeMode.light,
                    onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.light),
                const SizedBox(width: 8),
                _ThemeButton(label: 'Dark', icon: LucideIcons.moon,
                    isSelected: themeMode == ThemeMode.dark,
                    onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.dark),
                const SizedBox(width: 8),
                _ThemeButton(label: 'System', icon: LucideIcons.monitor,
                    isSelected: themeMode == ThemeMode.system,
                    onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.system),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Currency
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CURRENCY',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                      letterSpacing: 1.2, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              _SettingsRow(icon: LucideIcons.coins, title: 'Primary Currency',
                  trailing: Text(profile.valueOrNull?.primaryCurrency ?? 'PHP',
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant))),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Privacy
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PRIVACY & DATA',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                      letterSpacing: 1.2, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              _SettingsRow(icon: LucideIcons.download, title: 'Export Data',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export coming soon')),
                    );
                  }),
              const Divider(height: 16),
              _SettingsRow(icon: LucideIcons.fileText, title: 'Privacy Policy', onTap: () {}),
              const Divider(height: 16),
              _SettingsRow(icon: LucideIcons.fileText, title: 'Terms of Service', onTap: () {}),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Danger zone
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ACCOUNT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                      letterSpacing: 1.2, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              _SettingsRow(
                icon: LucideIcons.logOut,
                title: 'Sign Out',
                onTap: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
              const Divider(height: 16),
              _SettingsRow(
                icon: LucideIcons.trash2,
                title: 'Delete Account',
                color: colorScheme.error,
                onTap: () => _showDeleteConfirmation(context, ref),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 32),

        // Version
        Center(
          child: Text('Sandalan v1.0.0',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all your data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authRepositoryProvider).deleteAccount();
              if (context.mounted) context.go('/login');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _ThemeButton({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: [
            Icon(icon, size: 18,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Color? color;
  final VoidCallback? onTap;
  const _SettingsRow({required this.icon, required this.title, this.trailing, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: TextStyle(fontSize: 14, color: c))),
          if (trailing != null) trailing!
          else Icon(LucideIcons.chevronRight, size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
        ]),
      ),
    );
  }
}
