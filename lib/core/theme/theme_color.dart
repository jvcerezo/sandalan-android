/// Theme color options for customizing the app's primary color.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available theme color options.
enum ThemeColor {
  green('Sandalan Green', Color(0xFF2D8B5E), Color(0xFF3DB676)),
  blue('Ocean Blue', Color(0xFF2563EB), Color(0xFF60A5FA)),
  purple('Royal Purple', Color(0xFF7C3AED), Color(0xFFA78BFA)),
  orange('Sunset Orange', Color(0xFFEA580C), Color(0xFFFB923C)),
  pink('Rose Pink', Color(0xFFE11D48), Color(0xFFFB7185)),
  slate('Slate', Color(0xFF475569), Color(0xFF94A3B8));

  const ThemeColor(this.label, this.lightColor, this.darkColor);

  /// Display name for the color option.
  final String label;

  /// Primary color for light mode.
  final Color lightColor;

  /// Primary color for dark mode (slightly lighter variant).
  final Color darkColor;
}

const _prefKey = 'theme_color';

/// Riverpod notifier that persists the selected theme color.
class ThemeColorNotifier extends Notifier<ThemeColor> {
  @override
  ThemeColor build() {
    _loadFromPrefs();
    return ThemeColor.green;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    if (stored != null) {
      final parsed = ThemeColor.values.where((c) => c.name == stored);
      if (parsed.isNotEmpty) {
        state = parsed.first;
      }
    }
  }

  Future<void> setColor(ThemeColor color) async {
    state = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, color.name);
  }
}

/// Provider for the selected theme color.
final themeColorProvider =
    NotifierProvider<ThemeColorNotifier, ThemeColor>(ThemeColorNotifier.new);
