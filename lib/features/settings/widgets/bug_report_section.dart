import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/guest_mode_service.dart';
import 'settings_shared.dart';

class BugReportSection extends StatefulWidget {
  final Widget back;
  const BugReportSection({super.key, required this.back});

  @override
  State<BugReportSection> createState() => _BugReportSectionState();
}

class _BugReportSectionState extends State<BugReportSection> {
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  String _severity = 'medium';
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtl.dispose();
    _descCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtl.text.trim();
    final desc = _descCtl.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final isGuest = GuestModeService.isGuestSync();
      final userId = isGuest
          ? GuestModeService.getGuestIdSync()
          : Supabase.instance.client.auth.currentUser?.id;

      await Supabase.instance.client.from('bug_reports').insert({
        'user_id': userId,
        'title': title,
        'description': desc,
        'severity': _severity,
        'status': 'open',
      });

      if (mounted) {
        _titleCtl.clear();
        _descCtl.clear();
        setState(() {
          _severity = 'medium';
          _submitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bug report submitted! Thank you for your feedback.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      widget.back,
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
        TextField(
            controller: _titleCtl,
            decoration:
                const InputDecoration(isDense: true, hintText: 'Short summary of the issue')),
        const SizedBox(height: 10),
        const Text('Severity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
            value: _severity,
            isDense: true,
            items: ['low', 'medium', 'high', 'critical']
                .map((s) => DropdownMenuItem(
                    value: s, child: Text(s[0].toUpperCase() + s.substring(1))))
                .toList(),
            onChanged: (v) => setState(() => _severity = v ?? 'medium')),
        const SizedBox(height: 10),
        const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
            controller: _descCtl,
            maxLines: 4,
            decoration:
                const InputDecoration(hintText: 'What happened? Include steps to reproduce.')),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(LucideIcons.send, size: 14),
            label: Text(_submitting ? 'Submitting...' : 'Submit Bug Report'),
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0))),
      ])),
    ]);
  }
}
