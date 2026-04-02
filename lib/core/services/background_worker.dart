import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/app_database.dart';
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
    await _scheduleDailySummary();
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

  /// Schedule a daily 9 PM summary showing today's income/expenses.
  /// Recalculated and rescheduled every time the app opens.
  static Future<void> _scheduleDailySummary() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Query today's confirmed transactions from local DB
      final db = AppDatabase.instance;
      final summary = await db.getDailySummary(userId, todayStr);

      final income = summary['income'] as double;
      final expenses = summary['expenses'] as double;
      final count = summary['count'] as int;

      // Build notification message
      String body;
      if (count == 0) {
        body = 'No transactions today. Open Sandalan to log your expenses!';
      } else {
        final parts = <String>[];
        if (income > 0) parts.add('₱${_formatAmount(income)} income');
        if (expenses > 0) parts.add('₱${_formatAmount(expenses)} spent');
        final net = income - expenses;
        if (income > 0 && expenses > 0) {
          parts.add(net >= 0
              ? '₱${_formatAmount(net)} saved'
              : '₱${_formatAmount(net.abs())} over budget');
        }
        body = 'Today: ${parts.join(' · ')} ($count transaction${count == 1 ? '' : 's'})';
      }

      // Schedule for 9 PM today (or tomorrow if already past 9 PM)
      var target = DateTime(now.year, now.month, now.day, 21, 0);
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }

      // Cancel previous and reschedule with fresh data
      await NotificationService.instance.cancelNotification(90003);
      await NotificationService.instance.scheduleNotification(
        id: 90003,
        title: 'Daily Summary',
        body: body,
        scheduledDate: target,
      );
    } catch (_) {
      // Non-critical — don't break app startup
    }
  }

  static String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
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
