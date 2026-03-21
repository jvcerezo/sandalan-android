import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/automation_service.dart';
import '../../../core/services/notification_service.dart';
import 'settings_shared.dart';

class AutomationSection extends StatefulWidget {
  final Widget back;
  const AutomationSection({super.key, required this.back});

  @override
  State<AutomationSection> createState() => _AutomationSectionState();
}

class _AutomationSectionState extends State<AutomationSection> {
  bool _autoContrib = true, _billReminders = true, _debtReminders = true, _insuranceReminders = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoContrib = prefs.getBool(AutomationKeys.autoContributions) ?? true;
      _billReminders = prefs.getBool(AutomationKeys.autoBills) ?? true;
      _debtReminders = prefs.getBool(AutomationKeys.autoDebts) ?? true;
      _insuranceReminders = prefs.getBool(AutomationKeys.autoInsurance) ?? true;
      _loaded = true;
    });
  }

  Future<void> _setAndSave(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    if (value) {
      await AutomationService.runOnAppStart();
    } else {
      await NotificationService.instance.cancelAll();
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
          Icon(LucideIcons.zap, size: 18, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 8),
          const Text('Automation & Reminders',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        Text('Control which features run automatically and send you reminders',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        SettingsToggleRow(
            title: 'Auto-generate monthly contributions',
            sub: 'Create SSS, PhilHealth, and Pag-IBIG entries each month from your last salary',
            value: _autoContrib,
            onChanged: (v) {
              setState(() => _autoContrib = v);
              _setAndSave(AutomationKeys.autoContributions, v);
            }),
        SettingsToggleRow(
            title: 'Bill reminders',
            sub: 'Show upcoming bills on your Home page and send push notifications before due dates',
            value: _billReminders,
            onChanged: (v) {
              setState(() => _billReminders = v);
              _setAndSave(AutomationKeys.autoBills, v);
            }),
        SettingsToggleRow(
            title: 'Debt payment reminders',
            sub: 'Show upcoming debt payments on your Home page and send push notifications',
            value: _debtReminders,
            onChanged: (v) {
              setState(() => _debtReminders = v);
              _setAndSave(AutomationKeys.autoDebts, v);
            }),
        SettingsToggleRow(
            title: 'Insurance premium reminders',
            sub: 'Show upcoming insurance premiums and send push notifications before renewal dates',
            value: _insuranceReminders,
            onChanged: (v) {
              setState(() => _insuranceReminders = v);
              _setAndSave(AutomationKeys.autoInsurance, v);
            }),
      ])),
    ]);
  }
}
