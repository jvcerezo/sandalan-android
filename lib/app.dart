import 'dart:ui';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_color.dart';
import 'core/router/app_router.dart';
import 'core/services/app_lock_service.dart';
import 'core/services/privacy_service.dart';
import 'features/auth/screens/lock_screen.dart';

// ─── Theme mode (light / dark / amoled) ──────────────────────────────────────

/// Custom enum to support AMOLED alongside Flutter's ThemeMode.
enum AppThemeMode { light, dark, amoled, system }

final appThemeModeProvider = StateNotifierProvider<AppThemeModeNotifier, AppThemeMode>((ref) {
  return AppThemeModeNotifier();
});

class AppThemeModeNotifier extends StateNotifier<AppThemeMode> {
  static const _key = 'theme_mode';

  AppThemeModeNotifier() : super(AppThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    switch (stored) {
      case 'light':
        state = AppThemeMode.light;
      case 'dark':
        state = AppThemeMode.dark;
      case 'amoled':
        state = AppThemeMode.amoled;
      default:
        state = AppThemeMode.system;
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

/// Legacy themeModeProvider mapped for backward compat — returns Flutter ThemeMode.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(appThemeModeProvider);
  switch (mode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
    case AppThemeMode.amoled:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
});

// ─── Locale ──────────────────────────────────────────────────────────────────

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale?> {
  static const _key = 'app_locale';

  LocaleNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  Future<void> clearLocale() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// ─── Hide balances ──────────────────────────────────────────────────────────

final hideBalancesProvider = StateNotifierProvider<HideBalancesNotifier, bool>((ref) {
  return HideBalancesNotifier();
});

class HideBalancesNotifier extends StateNotifier<bool> {
  HideBalancesNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final hidden = await PrivacyService.instance.isHidden();
    state = hidden;
  }

  Future<void> toggle() async {
    await PrivacyService.instance.toggle();
    state = !state;
  }
}

// ─── Font scale ─────────────────────────────────────────────────────────────

final fontScaleProvider = StateNotifierProvider<FontScaleNotifier, double>((ref) {
  return FontScaleNotifier();
});

class FontScaleNotifier extends StateNotifier<double> {
  static const _key = 'font_scale';

  FontScaleNotifier() : super(1.0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(_key) ?? 1.0;
  }

  Future<void> setScale(double scale) async {
    state = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, scale);
  }
}

// ─── Compact numbers ────────────────────────────────────────────────────────

final compactNumbersProvider = StateNotifierProvider<CompactNumbersNotifier, bool>((ref) {
  return CompactNumbersNotifier();
});

class CompactNumbersNotifier extends StateNotifier<bool> {
  static const _key = 'compact_numbers';

  CompactNumbersNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

// ─── Dynamic color toggle ───────────────────────────────────────────────────

final useDynamicColorProvider = StateNotifierProvider<UseDynamicColorNotifier, bool>((ref) {
  return UseDynamicColorNotifier();
});

class UseDynamicColorNotifier extends StateNotifier<bool> {
  static const _key = 'use_dynamic_color';

  UseDynamicColorNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

// ─── Default landing page ───────────────────────────────────────────────────

final defaultLandingPageProvider =
    StateNotifierProvider<DefaultLandingPageNotifier, String>((ref) {
  return DefaultLandingPageNotifier();
});

class DefaultLandingPageNotifier extends StateNotifier<String> {
  static const _key = 'default_landing_page';

  DefaultLandingPageNotifier() : super('/home') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) ?? '/home';
  }

  Future<void> setPage(String path) async {
    state = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, path);
  }
}

// ─── Greeting style ─────────────────────────────────────────────────────────

enum GreetingStyle { english, filipino, casual, minimal }

final greetingStyleProvider = StateNotifierProvider<GreetingStyleNotifier, GreetingStyle>((ref) {
  return GreetingStyleNotifier();
});

class GreetingStyleNotifier extends StateNotifier<GreetingStyle> {
  static const _key = 'greeting_style';

  GreetingStyleNotifier() : super(GreetingStyle.english) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    switch (stored) {
      case 'filipino':
        state = GreetingStyle.filipino;
      case 'casual':
        state = GreetingStyle.casual;
      case 'minimal':
        state = GreetingStyle.minimal;
      default:
        state = GreetingStyle.english;
    }
  }

  Future<void> setStyle(GreetingStyle style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, style.name);
  }
}

// ─── Quiet hours ────────────────────────────────────────────────────────────

final quietHoursEnabledProvider = StateNotifierProvider<QuietHoursEnabledNotifier, bool>((ref) {
  return QuietHoursEnabledNotifier();
});

class QuietHoursEnabledNotifier extends StateNotifier<bool> {
  static const _key = 'quiet_hours_enabled';

  QuietHoursEnabledNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

final quietHoursFromProvider = StateNotifierProvider<QuietHoursTimeNotifier, int>((ref) {
  return QuietHoursTimeNotifier('quiet_hours_from', 22);
});

final quietHoursToProvider = StateNotifierProvider<QuietHoursTimeNotifier, int>((ref) {
  return QuietHoursTimeNotifier('quiet_hours_to', 7);
});

class QuietHoursTimeNotifier extends StateNotifier<int> {
  final String _key;

  QuietHoursTimeNotifier(this._key, int defaultHour) : super(defaultHour) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_key);
    if (stored != null) state = stored;
  }

  Future<void> setHour(int hour) async {
    state = hour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, hour);
  }
}

// ─── App ─────────────────────────────────────────────────────────────────────

class SandalanApp extends ConsumerStatefulWidget {
  const SandalanApp({super.key});

  @override
  ConsumerState<SandalanApp> createState() => _SandalanAppState();
}

class _SandalanAppState extends ConsumerState<SandalanApp> with WidgetsBindingObserver {
  bool _showBlur = false;
  bool _showLock = false;
  bool _lockChecked = false;
  bool _wasPaused = false; // Track if app was fully paused (not just inactive)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkInitialLock() async {
    final enabled = await AppLockService.instance.isEnabled();
    if (mounted) {
      setState(() {
        _showLock = enabled;
        _lockChecked = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
        // Just show blur overlay (for app switcher peek) — don't lock
        if (mounted) setState(() => _showBlur = true);
      case AppLifecycleState.paused:
        // App fully backgrounded — mark for lock on return
        _wasPaused = true;
        if (mounted) setState(() => _showBlur = true);
      case AppLifecycleState.resumed:
        _onResumed();
      default:
        break;
    }
  }

  Future<void> _onResumed() async {
    final shouldLock = _wasPaused; // Only lock if app was fully paused
    _wasPaused = false;

    if (!shouldLock) {
      // Was just inactive (tab switch / app switcher peek) — remove blur, no lock
      if (mounted) setState(() => _showBlur = false);
      return;
    }

    // App was fully paused — check if lock is enabled
    final lockEnabled = await AppLockService.instance.isEnabled();
    if (mounted) {
      setState(() {
        _showBlur = false;
        if (lockEnabled) _showLock = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appThemeMode = ref.watch(appThemeModeProvider);
    final themeColor = ref.watch(themeColorProvider);
    final locale = ref.watch(localeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final useDynamic = ref.watch(useDynamicColorProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Resolve themes
        ThemeData lightTheme;
        ThemeData darkTheme;

        if (useDynamic && lightDynamic != null && darkDynamic != null) {
          lightTheme = AppTheme.fromDynamicScheme(lightDynamic);
          darkTheme = AppTheme.fromDynamicScheme(darkDynamic);
        } else {
          lightTheme = AppTheme.light(themeColor);
          darkTheme = appThemeMode == AppThemeMode.amoled
              ? AppTheme.amoledDark(themeColor)
              : AppTheme.dark(themeColor);
        }

        // Map AppThemeMode -> Flutter ThemeMode
        ThemeMode flutterThemeMode;
        switch (appThemeMode) {
          case AppThemeMode.light:
            flutterThemeMode = ThemeMode.light;
          case AppThemeMode.dark:
          case AppThemeMode.amoled:
            flutterThemeMode = ThemeMode.dark;
          case AppThemeMode.system:
            flutterThemeMode = ThemeMode.system;
        }

        return MaterialApp.router(
          title: 'Sandalan',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: flutterThemeMode,
          routerConfig: appRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(fontScale),
              ),
              child: DefaultTextStyle(
                style: DefaultTextStyle.of(context).style.copyWith(
                  decoration: TextDecoration.none,
                ),
                child: Stack(
                  children: [
                    child!,
                  // Blur overlay when app is backgrounded
                  if (_showBlur && !_showLock)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  // Lock screen overlay
                  if (_showLock && _lockChecked)
                    Positioned.fill(
                      child: LockScreen(
                        onUnlocked: () {
                          if (mounted) setState(() => _showLock = false);
                        },
                      ),
                    ),
                ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
