import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/automation_service.dart';
import 'core/services/sync_service.dart';
import 'data/local/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://oinnvvvqqpdffhkhdyyo.supabase.co',
    anonKey: 'sb_publishable_E9gxDCJBOYe00zKtHwmTxw_CbKjwjDT',
  );

  // Initialize local SQLite database.
  await AppDatabase.init();

  // Initialize notifications and run automation after Supabase is ready.
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();
  await AutomationService.runOnAppStart();

  // Start background sync: pull from Supabase, push pending local changes.
  final syncService = SyncService(Supabase.instance.client, AppDatabase.instance);
  syncService.fullSync(); // Initial sync on app start (fire-and-forget).
  syncService.startPeriodicSync(); // Sync every 5 min + on connectivity change.

  runApp(
    const ProviderScope(
      child: SandalanApp(),
    ),
  );
}
