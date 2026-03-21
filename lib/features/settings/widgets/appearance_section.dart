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
    final appThemeMode = ref.watch(appThemeModeProvider);
    final selectedColor = ref.watch(themeColorProvider);
    final useDynamic = ref.watch(useDynamicColorProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final compactNumbers = ref.watch(compactNumbersProvider);
    final greetingStyle = ref.watch(greetingStyleProvider);

    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      back,
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Choose your preferred appearance',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        Row(children: [
          _ThemeBtn(
              icon: LucideIcons.sun,
              label: 'Light',
              selected: appThemeMode == AppThemeMode.light,
              onTap: () => ref.read(appThemeModeProvider.notifier).setMode(AppThemeMode.light)),
          const SizedBox(width: 8),
          _ThemeBtn(
              icon: LucideIcons.moon,
              label: 'Dark',
              selected: appThemeMode == AppThemeMode.dark,
              onTap: () => ref.read(appThemeModeProvider.notifier).setMode(AppThemeMode.dark)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _ThemeBtn(
              icon: LucideIcons.monitor,
              label: 'AMOLED',
              selected: appThemeMode == AppThemeMode.amoled,
              onTap: () => ref.read(appThemeModeProvider.notifier).setMode(AppThemeMode.amoled)),
          const SizedBox(width: 8),
          _ThemeBtn(
              icon: LucideIcons.monitor,
              label: 'System',
              selected: appThemeMode == AppThemeMode.system,
              onTap: () => ref.read(appThemeModeProvider.notifier).setMode(AppThemeMode.system)),
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
          // Dynamic color option
          _DynamicColorDot(
            selected: useDynamic,
            onTap: () => ref.read(useDynamicColorProvider.notifier).setEnabled(!useDynamic),
          ),
          for (final color in ThemeColor.values)
            _ColorDot(
              color: color,
              selected: !useDynamic && selectedColor == color,
              onTap: () {
                if (useDynamic) {
                  ref.read(useDynamicColorProvider.notifier).setEnabled(false);
                }
                ref.read(themeColorProvider.notifier).setColor(color);
              },
            ),
        ]),
      ])),
      const SizedBox(height: 12),
      // Text Size
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Text Size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Adjust the text size across the app',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        Row(children: [
          _ScaleBtn(label: 'Small', scale: 0.85, selected: fontScale == 0.85, ref: ref),
          const SizedBox(width: 8),
          _ScaleBtn(label: 'Default', scale: 1.0, selected: fontScale == 1.0, ref: ref),
          const SizedBox(width: 8),
          _ScaleBtn(label: 'Large', scale: 1.15, selected: fontScale == 1.15, ref: ref),
          const SizedBox(width: 8),
          _ScaleBtn(label: 'XL', scale: 1.3, selected: fontScale == 1.3, ref: ref),
        ]),
      ])),
      const SizedBox(height: 12),
      // Compact numbers
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Display', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        SettingsToggleRow(
            title: 'Compact numbers',
            sub: 'Show amounts like \u20b1108.7K instead of \u20b1108,700.00 on dashboard',
            value: compactNumbers,
            onChanged: (_) => ref.read(compactNumbersProvider.notifier).toggle()),
      ])),
      const SizedBox(height: 12),
      // Greeting Style
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Greeting Style', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('How you want to be greeted on the Home screen',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        _GreetingOption(
          label: 'Good morning, Jet',
          subtitle: 'English time-based',
          style: GreetingStyle.english,
          selected: greetingStyle,
          ref: ref,
        ),
        _GreetingOption(
          label: 'Magandang umaga, Jet',
          subtitle: 'Filipino time-based',
          style: GreetingStyle.filipino,
          selected: greetingStyle,
          ref: ref,
        ),
        _GreetingOption(
          label: 'Hey, Jet!',
          subtitle: 'Casual',
          style: GreetingStyle.casual,
          selected: greetingStyle,
          ref: ref,
        ),
        _GreetingOption(
          label: 'Jet',
          subtitle: 'Minimal',
          style: GreetingStyle.minimal,
          selected: greetingStyle,
          ref: ref,
        ),
      ])),
      const SizedBox(height: 12),
      _LanguageSection(ref: ref),
    ]);
  }
}

class _DynamicColorDot extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _DynamicColorDot({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Dynamic color${selected ? ', selected' : ''}',
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
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2.5)
                  : Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1.5),
              boxShadow: selected
                  ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.35), blurRadius: 8, spreadRadius: 1)]
                  : null,
            ),
            child: selected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
          ),
          const SizedBox(height: 4),
          Text('Dynamic',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
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

class _ScaleBtn extends StatelessWidget {
  final String label;
  final double scale;
  final bool selected;
  final WidgetRef ref;
  const _ScaleBtn({required this.label, required this.scale, required this.selected, required this.ref});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: () => ref.read(fontScaleProvider.notifier).setScale(scale),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? cs.onPrimary : cs.onSurfaceVariant)),
          ),
        ),
      ),
    );
  }
}

class _GreetingOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final GreetingStyle style;
  final GreetingStyle selected;
  final WidgetRef ref;
  const _GreetingOption({
    required this.label,
    required this.subtitle,
    required this.style,
    required this.selected,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = style == selected;
    return InkWell(
      onTap: () => ref.read(greetingStyleProvider.notifier).setStyle(style),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: isSelected ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ])),
        ]),
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
