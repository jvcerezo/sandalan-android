import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'settings_shared.dart';

class BugReportSection extends StatelessWidget {
  final Widget back;
  const BugReportSection({super.key, required this.back});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      back,
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.bug, size: 18, color: cs.onSurface),
          const SizedBox(width: 8),
          const Text('Report a Bug',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        Text('Found something broken? Send details and it will appear in the admin dashboard.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        const Text('Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        const TextField(
            decoration:
                InputDecoration(isDense: true, hintText: 'Short summary of the issue')),
        const SizedBox(height: 10),
        const Text('Severity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
            value: 'medium',
            isDense: true,
            items: ['low', 'medium', 'high', 'critical']
                .map((s) => DropdownMenuItem(
                    value: s, child: Text(s[0].toUpperCase() + s.substring(1))))
                .toList(),
            onChanged: (v) {}),
        const SizedBox(height: 10),
        const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        const TextField(
            maxLines: 4,
            decoration:
                InputDecoration(hintText: 'What happened? Include steps to reproduce.')),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.send, size: 14),
            label: const Text('Submit Bug Report'),
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0))),
      ])),
    ]);
  }
}
