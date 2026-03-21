import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/services/guest_mode_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/automation_service.dart';
import 'core/services/sync_service.dart';
import 'data/local/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  // Initialize local SQLite database.
  await AppDatabase.init();

  // Load default landing page before router is created.
  await loadDefaultLandingPage();

  // Initialize guest mode state from SharedPreferences.
  await GuestModeService.init();

  // Initialize notifications and run automation after Supabase is ready.
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();

  // Only run sync and automation for authenticated (non-guest) users.
  final isGuest = GuestModeService.isGuestSync();
  if (!isGuest) {
    await AutomationService.runOnAppStart();

    // Start background sync: pull on app start only, daily sync + on background.
    final syncService = SyncService(Supabase.instance.client, AppDatabase.instance);
    syncService.fullSync(); // Initial sync on app start (fire-and-forget).
    syncService.startDailySync(); // Once-daily sync + on app background.
  }

  runApp(
    const ProviderScope(
      child: SandalanApp(),
    ),
  );
}
