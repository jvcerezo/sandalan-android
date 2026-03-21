import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';

/// Schedules monthly report card notifications.
/// This is separate from automation_service.dart per design spec.
class ReportNotificationService {
  static const _notificationId = 9900; // Unique ID range for report notifications

  /// Schedule a notification for the 1st of each month at 9 AM Manila time.
  /// Should be called at app startup or after login.
  static Future<void> scheduleMonthlyReportNotification() async {
    final now = DateTime.now();

    // Schedule for the next 3 months to keep notifications fresh
    for (int i = 1; i <= 3; i++) {
      final targetMonth = DateTime(now.year, now.month + i, 1, 9, 0);
      final prevMonth = DateTime(targetMonth.year, targetMonth.month - 1);
      final monthName = DateFormat('MMMM').format(prevMonth);

      await NotificationService.instance.scheduleNotification(
        id: _notificationId + i,
        title: 'Your $monthName Report Card is ready!',
        body:
            'See how you did last month \u2014 savings rate, spending trends, and your grade.',
        scheduledDate: targetMonth,
      );
    }
  }
}
