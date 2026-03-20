import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/automation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://oinnvvvqqpdffhkhdyyo.supabase.co',
    anonKey: 'sb_publishable_E9gxDCJBOYe00zKtHwmTxw_CbKjwjDT',
  );

  // Initialize notifications and run automation after Supabase is ready.
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();
  await AutomationService.runOnAppStart();

  runApp(
    const ProviderScope(
      child: SandalanApp(),
    ),
  );
}
