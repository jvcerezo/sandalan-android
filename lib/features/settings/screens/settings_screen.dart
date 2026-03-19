import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Icon(LucideIcons.user, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('User Name',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('user@email.com',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Appearance
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Appearance',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurfaceVariant,
                    )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ThemeButton(
                      label: 'Light',
                      icon: LucideIcons.sun,
                      isSelected: themeMode == ThemeMode.light,
                      onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.light,
                    ),
                    const SizedBox(width: 8),
                    _ThemeButton(
                      label: 'Dark',
                      icon: LucideIcons.moon,
                      isSelected: themeMode == ThemeMode.dark,
                      onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.dark,
                    ),
                    const SizedBox(width: 8),
                    _ThemeButton(
                      label: 'System',
                      icon: LucideIcons.monitor,
                      isSelected: themeMode == ThemeMode.system,
                      onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.system,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // TODO: Language selector (Phase 8)
        // TODO: Automation toggles (Phase 8)
        // TODO: Home page visibility toggles (Phase 8)
        // TODO: Currency settings (Phase 8)
        // TODO: Privacy & Data (Phase 8)
        // TODO: Danger zone — delete account (Phase 8)
      ],
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
