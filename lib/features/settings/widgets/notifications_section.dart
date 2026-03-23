import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app.dart';
import '../../../core/services/automation_service.dart';
import '../../../core/services/notification_service.dart';
import 'settings_shared.dart';

class NotificationsSection extends ConsumerStatefulWidget {
  final Widget back;
  const NotificationsSection({super.key, required this.back});

  @override
  ConsumerState<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<NotificationsSection> {
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

  String _formatHour(int hour) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final amPm = hour < 12 ? 'AM' : 'PM';
    return '$h:00 $amPm';
  }

  Future<void> _pickTime(BuildContext context, int currentHour, ValueChanged<int> onPicked) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
    );
    if (time != null) onPicked(time.hour);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final cs = Theme.of(context).colorScheme;
    final quietEnabled = ref.watch(quietHoursEnabledProvider);
    final quietFrom = ref.watch(quietHoursFromProvider);
    final quietTo = ref.watch(quietHoursToProvider);

    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      widget.back,
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.bell, size: 18, color: cs.onSurface),
          const SizedBox(width: 8),
          const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        Text('Push notification preferences (mobile app only)',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
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
      const SizedBox(height: 12),
      // Test Notification
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.bellRing, size: 18, color: cs.onSurface),
          const SizedBox(width: 8),
          const Text('Test', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        Text('Send a test notification to verify your setup',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await NotificationService.instance.sendTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent!')),
                );
              }
            },
            icon: const Icon(LucideIcons.send, size: 16),
            label: const Text('Send Test Notification'),
          ),
        ),
      ])),
      const SizedBox(height: 12),
      // Quiet Hours
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.moonStar, size: 18, color: cs.onSurface),
          const SizedBox(width: 8),
          const Text('Quiet Hours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        Text('Suppress notifications during specified hours',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        SettingsToggleRow(
            title: 'Enable quiet hours',
            sub: 'No notifications during the quiet period',
            value: quietEnabled,
            onChanged: (v) => ref.read(quietHoursEnabledProvider.notifier).setEnabled(v)),
        if (quietEnabled) ...[
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: InkWell(
              onTap: () => _pickTime(context, quietFrom, (h) => ref.read(quietHoursFromProvider.notifier).setHour(h)),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('From', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(_formatHour(quietFrom), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: InkWell(
              onTap: () => _pickTime(context, quietTo, (h) => ref.read(quietHoursToProvider.notifier).setHour(h)),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('To', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(_formatHour(quietTo), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
            )),
          ]),
        ],
      ])),
    ]);
  }
}
