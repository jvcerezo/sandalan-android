import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/automation_service.dart';
import '../../../core/services/notification_service.dart';
import 'settings_shared.dart';

class NotificationsSection extends StatefulWidget {
  final Widget back;
  const NotificationsSection({super.key, required this.back});

  @override
  State<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<NotificationsSection> {
  bool _push = true, _morning = true, _dailyLog = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _push = prefs.getBool(AutomationKeys.pushEnabled) ?? true;
      _morning = prefs.getBool(AutomationKeys.morningSummary) ?? true;
      _dailyLog = prefs.getBool(AutomationKeys.dailyLogReminder) ?? true;
      _loaded = true;
    });
  }

  Future<void> _onPushChanged(bool value) async {
    setState(() => _push = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AutomationKeys.pushEnabled, value);

    if (!value) {
      await NotificationService.instance.cancelAll();
    } else {
      await NotificationService.instance.requestPermission();
      await AutomationService.runOnAppStart();
    }
  }

  Future<void> _onMorningChanged(bool value) async {
    setState(() => _morning = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AutomationKeys.morningSummary, value);
  }

  Future<void> _onDailyLogChanged(bool value) async {
    setState(() => _dailyLog = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AutomationKeys.dailyLogReminder, value);

    if (!value) {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await NotificationService.instance.cancelNotification('daily-log-$todayStr'.hashCode);
    } else {
      await AutomationService.runOnAppStart();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      widget.back,
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.bell, size: 18, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 8),
          const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        Text('Push notification preferences (mobile app only)',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        SettingsToggleRow(
            title: 'Push notifications',
            sub: 'Receive notifications on your phone for upcoming payments and reminders',
            value: _push,
            onChanged: _onPushChanged),
        SettingsToggleRow(
            title: 'Morning summary',
            sub: 'Get a daily summary of what\'s due today at 9:00 AM',
            value: _morning,
            onChanged: _onMorningChanged),
        SettingsToggleRow(
            title: 'Daily log reminder',
            sub: 'Remind you at 7:00 PM to log your expenses if you haven\'t logged any today',
            value: _dailyLog,
            onChanged: _onDailyLogChanged),
      ])),
    ]);
  }
}
