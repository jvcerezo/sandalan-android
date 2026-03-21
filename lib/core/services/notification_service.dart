import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Singleton service that wraps flutter_local_notifications for scheduling
/// payment reminders, contribution due dates, etc.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Android notification channel used for all reminders.
  static const _channel = AndroidNotificationChannel(
    'sandalan_reminders',
    'Reminders',
    description: 'Payment and contribution reminders from Sandalan',
    importance: Importance.high,
  );

  // ── Initialization ──────────────────────────────────────────────────────────

  /// Call once at app startup (after [WidgetsFlutterBinding.ensureInitialized]).
  Future<void> init() async {
    if (_initialized) return;

    // Timezone data is required by zonedSchedule.
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    // Create the channel on Android 8+.
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        _channel.id,
        _channel.name,
        description: _channel.description,
        importance: _channel.importance,
      ),
    );

    _initialized = true;
  }

  // ── Permissions ─────────────────────────────────────────────────────────────

  /// Request POST_NOTIFICATIONS permission (Android 13+).
  /// Returns true if granted (or if running on Android < 13 where it is
  /// automatically granted).
  Future<bool> requestPermission() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  // ── Schedule / Cancel ───────────────────────────────────────────────────────

  /// Schedule a notification at exactly [scheduledDate] (defaults to 9:00 AM
  /// on that day if time component is midnight).
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_initialized) {
      if (kDebugMode) debugPrint('NotificationService: not initialized, skipping schedule');
      return;
    }

    // Default to 9:00 AM on the target date.
    var target = scheduledDate;
    if (target.hour == 0 && target.minute == 0 && target.second == 0) {
      target = DateTime(target.year, target.month, target.day, 9, 0);
    }

    final tzTarget = tz.TZDateTime.from(target, tz.local);

    // Don't schedule notifications in the past.
    if (tzTarget.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTarget,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Check if we are currently in quiet hours.
  Future<bool> _isInQuietHours() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('quiet_hours_enabled') ?? false;
    if (!enabled) return false;

    final from = prefs.getInt('quiet_hours_from') ?? 22;
    final to = prefs.getInt('quiet_hours_to') ?? 7;
    final now = DateTime.now().hour;

    if (from <= to) {
      // e.g. 8 AM to 5 PM
      return now >= from && now < to;
    } else {
      // e.g. 10 PM to 7 AM (wraps midnight)
      return now >= from || now < to;
    }
  }

  /// Show an immediate notification (for budget alerts, goal completion, etc.).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    if (await _isInQuietHours()) return;

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Cancel a single notification by [id].
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
