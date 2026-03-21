import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_color.dart';
import '../../../app.dart';
import '../../../core/l10n/app_localizations.dart';
import 'settings_shared.dart';

class AppearanceSection extends ConsumerWidget {
  final Widget back;
  const AppearanceSection({super.key, required this.back});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final selectedColor = ref.watch(themeColorProvider);

    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      back,
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Customize how Sandalan looks on your device',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        const Text('Theme', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(children: [
          _ThemeBtn(
              icon: LucideIcons.sun,
              label: 'Light',
              selected: themeMode == ThemeMode.light,
              onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.light),
          const SizedBox(width: 8),
          _ThemeBtn(
              icon: LucideIcons.moon,
              label: 'Dark',
              selected: themeMode == ThemeMode.dark,
              onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.dark),
          const SizedBox(width: 8),
          _ThemeBtn(
              icon: LucideIcons.monitor,
              label: 'System',
              selected: themeMode == ThemeMode.system,
              onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.system),
        ]),
      ])),
      const SizedBox(height: 12),
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
      _LanguageSection(ref: ref),
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
    return Semantics(
      label: '${color.label} color${selected ? ', selected' : ''}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
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
            child: selected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
          ),
          const SizedBox(height: 4),
          Text(color.label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _ThemeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeBtn(
      {required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        label: '$label theme${selected ? ', selected' : ''}',
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? cs.primary : Colors.transparent,
              border: Border.all(
                  color: selected ? cs.primary : cs.outline.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 14, color: selected ? cs.onPrimary : cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? cs.onPrimary : cs.onSurfaceVariant)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _LanguageSection extends StatelessWidget {
  final WidgetRef ref;
  const _LanguageSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentLocale = ref.watch(localeProvider);
    final isFilipino = currentLocale?.languageCode == 'fil';
    final isEnglish = currentLocale?.languageCode == 'en' || currentLocale == null;

    return SettingsCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Language / Wika', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      Text('Choose your preferred language',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: isEnglish
                ? FilledButton(
                    onPressed: () =>
                        ref.read(localeProvider.notifier).setLocale(const Locale('en')),
                    child: const Text('English'))
                : OutlinedButton(
                    onPressed: () =>
                        ref.read(localeProvider.notifier).setLocale(const Locale('en')),
                    child: const Text('English'))),
        const SizedBox(width: 8),
        Expanded(
            child: isFilipino
                ? FilledButton(
                    onPressed: () =>
                        ref.read(localeProvider.notifier).setLocale(const Locale('fil')),
                    child: const Text('Filipino'))
                : OutlinedButton(
                    onPressed: () =>
                        ref.read(localeProvider.notifier).setLocale(const Locale('fil')),
                    child: const Text('Filipino'))),
      ]),
    ]));
  }
}
