import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../core/services/spending_insights_service.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/local/app_database.dart';

/// AI Insights section shown at the bottom of the dashboard.
class AiInsightsSection extends StatefulWidget {
  const AiInsightsSection({super.key});

  @override
  State<AiInsightsSection> createState() => _AiInsightsSectionState();
}

class _AiInsightsSectionState extends State<AiInsightsSection> {
  List<SpendingInsight> _insights = [];
  bool _loaded = false;

  String get _userId {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final insights = await SpendingInsightsService.getInsights(AppDatabase.instance, _userId);
      if (mounted) setState(() { _insights = insights.take(5).toList(); _loaded = true; });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Color _accentColor(String severity) {
    switch (severity) {
      case 'positive': return AppColors.success;
      case 'warning': return AppColors.warning;
      default: return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_loaded || _insights.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('INSIGHTS', style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      )),
      const SizedBox(height: 8),
      for (final insight in _insights) ...[
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: _accentColor(insight.severity),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(insight.icon, size: 16, color: _accentColor(insight.severity)),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(insight.text,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
          ]),
        ),
      ],
    ]);
  }
}
