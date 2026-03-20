import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_color.dart';
import 'core/router/app_router.dart';

/// Theme mode state provider.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class SandalanApp extends ConsumerWidget {
  const SandalanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);

    return MaterialApp.router(
      title: 'Sandalan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(themeColor),
      darkTheme: AppTheme.dark(themeColor),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
