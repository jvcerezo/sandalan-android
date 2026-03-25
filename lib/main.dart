import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/services/app_lock_service.dart';
import 'core/services/guest_mode_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/automation_service.dart';
import 'core/services/progress_sync_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/sync_status_notifier.dart';
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

  // Migrate plaintext PIN to secure hashed storage (one-time, safe to re-run).
  await AppLockService.instance.migrateIfNeeded();

  // Initialize notifications and run automation after Supabase is ready.
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();

  // Only run sync and automation for authenticated (non-guest) users.
  final isGuest = GuestModeService.isGuestSync();

  // Create sync status notifier early so SyncService can update it
  // and Riverpod consumers can read from the same instance.
  final syncStatusNotifier = SyncStatusNotifier();

  if (!isGuest) {
    await AutomationService.runOnAppStart();

    // Start background sync: pull on app start only, daily sync + on background.
    final syncService = SyncService(
      Supabase.instance.client,
      AppDatabase.instance,
      syncStatus: syncStatusNotifier,
    );
    SyncService.instance = syncService;
    syncService.fullSync(); // Initial sync on app start (fire-and-forget).
    syncService.startDailySync(); // Once-daily sync + on app background.

    // Sync checklist/guide progress from cloud (merge with local).
    ProgressSyncService.instance.pullAndMerge();
  }

  runApp(
    ProviderScope(
      overrides: [
        syncStatusProvider.overrideWith((_) => syncStatusNotifier),
      ],
      child: const SandalanApp(),
    ),
  );

  // Initialize deep link handling (app shortcuts + widget buttons).
  DeepLinkService.instance.init();
}
