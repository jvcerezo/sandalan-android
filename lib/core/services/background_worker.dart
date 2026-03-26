import 'notification_service.dart';

/// Schedules persistent background notifications using flutter_local_notifications.
/// These survive app close since they use Android's AlarmManager via
/// zonedSchedule with exactAllowWhileIdle.
///
/// Replaces WorkManager (incompatible with Flutter 3.41+).
class BackgroundWorker {
  BackgroundWorker._();

  /// Schedule recurring background notifications.
  /// Call once in main.dart after NotificationService.init().
  static Future<void> init() async {
    await _scheduleDailyLogReminder();
    await _scheduleWeeklyRecap();
  }

  /// Schedule a daily "log your expenses" reminder at 8 PM.
  /// Re-schedules for today if before 8 PM, otherwise tomorrow.
  static Future<void> _scheduleDailyLogReminder() async {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 20, 0);
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }

    await NotificationService.instance.scheduleNotification(
      id: 90001,
      title: 'Sandalan',
      body: 'Don\'t forget to log today\'s expenses!',
      scheduledDate: target,
    );
  }

  /// Schedule a weekly recap notification for Monday 9 AM.
  static Future<void> _scheduleWeeklyRecap() async {
    final now = DateTime.now();
    var nextMonday = DateTime(now.year, now.month, now.day, 9, 0);
    // Find next Monday
    while (nextMonday.weekday != DateTime.monday || nextMonday.isBefore(now)) {
      nextMonday = nextMonday.add(const Duration(days: 1));
    }

    await NotificationService.instance.scheduleNotification(
      id: 90002,
      title: 'Weekly Recap',
      body: 'Your weekly financial summary is ready. Open Sandalan to see it!',
      scheduledDate: nextMonday,
    );
  }
}
