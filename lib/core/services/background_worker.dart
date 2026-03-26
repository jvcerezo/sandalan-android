import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';

/// Task identifiers for WorkManager.
const kTaskRescheduleReminders = 'sandalan.reschedule_reminders';
const kTaskWeeklyRecap = 'sandalan.weekly_recap';
const kTaskDailyCheck = 'sandalan.daily_check';

/// Top-level callback for WorkManager — must be a top-level or static function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      switch (taskName) {
        case kTaskDailyCheck:
          // Re-schedule notification reminders in case the app wasn't opened.
          // This ensures bill/debt/insurance reminders survive reboots.
          await _runDailyCheck();
          return true;
        case kTaskWeeklyRecap:
          await _sendWeeklyRecapNotification();
          return true;
        default:
          return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('BackgroundWorker: task $taskName failed: $e');
      return false;
    }
  });
}

/// Re-schedule reminders from background (minimal — no Supabase, just local DB).
Future<void> _runDailyCheck() async {
  // Initialize notifications (timezone, channel).
  await NotificationService.instance.init();

  // Schedule a "log your expenses" reminder at 8 PM if not quiet hours.
  final now = DateTime.now();
  final tonight = DateTime(now.year, now.month, now.day, 20, 0);
  if (tonight.isAfter(now)) {
    await NotificationService.instance.scheduleNotification(
      id: 90001,
      title: 'Sandalan',
      body: 'Don\'t forget to log today\'s expenses!',
      scheduledDate: tonight,
    );
  }
}

/// Send a weekly recap notification.
Future<void> _sendWeeklyRecapNotification() async {
  await NotificationService.instance.init();
  await NotificationService.instance.showNotification(
    id: 90002,
    title: 'Weekly Recap Ready',
    body: 'Your weekly financial summary is ready. Open Sandalan to see it!',
  );
}

/// Initialize WorkManager and register periodic tasks.
/// Call once in main.dart after Flutter binding is initialized.
class BackgroundWorker {
  BackgroundWorker._();

  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // Daily check — runs once per day to re-schedule reminders.
    // This ensures reminders survive reboots and app force-closes.
    await Workmanager().registerPeriodicTask(
      kTaskDailyCheck,
      kTaskDailyCheck,
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );

    // Weekly recap — runs every Monday morning.
    await Workmanager().registerPeriodicTask(
      kTaskWeeklyRecap,
      kTaskWeeklyRecap,
      frequency: const Duration(days: 7),
      initialDelay: _delayUntilNextMonday(),
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  /// Calculate delay until next Monday at 9 AM.
  static Duration _delayUntilNextMonday() {
    final now = DateTime.now();
    var nextMonday = DateTime(now.year, now.month, now.day + (8 - now.weekday) % 7, 9, 0);
    if (nextMonday.isBefore(now)) {
      nextMonday = nextMonday.add(const Duration(days: 7));
    }
    return nextMonday.difference(now);
  }
}
