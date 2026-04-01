import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../core/config/env.dart';
import '../../../shared/utils/snackbar_helper.dart';

/// Shows a feedback collection dialog.
void showFeedbackDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _FeedbackSheet(),
  );
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _controller = TextEditingController();
  String _type = 'suggestion'; // suggestion, bug, praise
  int _rating = 0; // 1-5 stars, 0 = not rated
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty && _rating == 0) return;
    setState(() => _sending = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id ?? GuestModeService.getGuestIdSync() ?? 'guest';

      // Store feedback directly in Supabase bug_reports table
      await Supabase.instance.client.from('bug_reports').insert({
        'user_id': userId,
        'title': '[$_type] ${_rating > 0 ? '${'⭐' * _rating} ' : ''}App Feedback',
        'description': _controller.text.trim(),
        'status': 'open',
      });

      // Fire-and-forget Discord notification
      _sendDiscordNotification(
        type: _type,
        rating: _rating,
        message: _controller.text.trim(),
        userName: user?.userMetadata?['full_name'] as String? ?? 'Unknown',
      );

      if (mounted) {
        showSuccessSnackBar(context, 'Salamat sa feedback!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Failed to submit: $e', isError: true);
    }
    setState(() => _sending = false);
  }

  /// Send a Discord webhook notification. Fire-and-forget — never blocks UI.
  static Future<void> _sendDiscordNotification({
    required String type,
    required int rating,
    required String message,
    required String userName,
  }) async {
    final webhookUrl = Env.discordWebhookUrl;
    if (webhookUrl.isEmpty) return;

    try {
      final emoji = type == 'bug' ? '🐛' : type == 'suggestion' ? '💡' : type == 'praise' ? '💜' : '📋';
      final color = type == 'bug' ? 0xDC2626 : type == 'suggestion' ? 0x3B82F6 : type == 'praise' ? 0x10B981 : 0x6B7280;
      final stars = rating > 0 ? ' ${'⭐' * rating}' : '';

      await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'embeds': [{
            'title': '$emoji New ${type[0].toUpperCase()}${type.substring(1)}$stars',
            'description': message.length > 1000 ? '${message.substring(0, 1000)}...' : message,
            'color': color,
            'fields': [
              {'name': 'From', 'value': userName, 'inline': true},
              {'name': 'Type', 'value': type, 'inline': true},
            ],
            'footer': {'text': 'Sandalan Feedback'},
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          }],
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Silent fail — Discord notification is non-critical
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(child: Container(
          width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cs.onSurfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        )),

        // Title
        Row(children: [
          Icon(LucideIcons.messageSquare, size: 20, color: cs.primary),
          const SizedBox(width: 8),
          const Text('Send Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Help us improve Sandalan', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ),
        const SizedBox(height: 16),

        // Type selector
        Row(children: [
          _TypeChip(label: 'Suggestion', icon: LucideIcons.lightbulb, selected: _type == 'suggestion',
              onTap: () => setState(() => _type = 'suggestion')),
          const SizedBox(width: 8),
          _TypeChip(label: 'Bug', icon: LucideIcons.bug, selected: _type == 'bug',
              onTap: () => setState(() => _type = 'bug')),
          const SizedBox(width: 8),
          _TypeChip(label: 'Praise', icon: LucideIcons.heart, selected: _type == 'praise',
              onTap: () => setState(() => _type = 'praise')),
        ]),
        const SizedBox(height: 16),

        // Rating
        Row(children: [
          Text('How do you like Sandalan?', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const Spacer(),
          for (var i = 1; i <= 5; i++)
            GestureDetector(
              onTap: () => setState(() => _rating = _rating == i ? 0 : i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  i <= _rating ? LucideIcons.star : LucideIcons.star,
                  size: 22,
                  color: i <= _rating ? const Color(0xFFF59E0B) : cs.onSurfaceVariant.withOpacity(0.2),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 12),

        // Message
        TextField(
          controller: _controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: _type == 'bug'
                ? 'Describe the bug. What happened? What did you expect?'
                : _type == 'praise'
                    ? 'What do you love about Sandalan?'
                    : 'What feature or improvement would you like to see?',
            hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withOpacity(0.4)),
          ),
        ),
        const SizedBox(height: 16),

        // Submit
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _sending || (_controller.text.trim().isEmpty && _rating == 0) ? null : _submit,
            child: _sending
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit Feedback'),
          ),
        ),
      ]),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? cs.primary.withOpacity(0.1) : Colors.transparent,
            border: Border.all(color: selected ? cs.primary : cs.outline.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: selected ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: selected ? cs.primary : cs.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
