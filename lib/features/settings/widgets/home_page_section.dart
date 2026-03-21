import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'settings_shared.dart';

class HomePageSection extends StatefulWidget {
  final Widget back;
  const HomePageSection({super.key, required this.back});

  @override
  State<HomePageSection> createState() => _HomePageSectionState();
}

class _HomePageSectionState extends State<HomePageSection> {
  bool _upcoming = true, _nextSteps = true, _financial = true, _stage = true;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      widget.back,
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.layoutGrid, size: 18, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 8),
          const Text('Home Page', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        Text('Choose which sections appear on your Home page',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        SettingsToggleRow(
            title: 'Upcoming Payments',
            sub: 'Show bills, contributions, debts, and insurance due soon',
            value: _upcoming,
            onChanged: (v) => setState(() => _upcoming = v)),
        SettingsToggleRow(
            title: 'Next Steps',
            sub: 'Show suggested next actions from your adulting journey',
            value: _nextSteps,
            onChanged: (v) => setState(() => _nextSteps = v)),
        SettingsToggleRow(
            title: 'Financial Summary',
            sub: 'Show balance, income, and expenses at a glance',
            value: _financial,
            onChanged: (v) => setState(() => _financial = v)),
        SettingsToggleRow(
            title: 'Current Life Stage',
            sub: 'Show your current adulting journey stage and progress',
            value: _stage,
            onChanged: (v) => setState(() => _stage = v)),
      ])),
    ]);
  }
}
