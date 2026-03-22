import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../core/services/spending_insights_service.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/local/app_database.dart';

/// Shows the top spending insight on the home screen.
class HomeInsightCard extends StatefulWidget {
  const HomeInsightCard({super.key});

  @override
  State<HomeInsightCard> createState() => _HomeInsightCardState();
}

class _HomeInsightCardState extends State<HomeInsightCard> {
  SpendingInsight? _insight;
  bool _dismissed = false;
  bool _loaded = false;

  String get _userId {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  @override
  void initState() {
    super.initState();
    _loadInsight();
  }

  Future<void> _loadInsight() async {
    try {
      final insights = await SpendingInsightsService.getInsights(AppDatabase.instance, _userId);
      if (insights.isEmpty || !mounted) return;

      // Sort: warnings first, then rotate daily
      final sorted = [...insights];
      sorted.sort((a, b) {
        const order = {'warning': 0, 'positive': 1, 'info': 2};
        final aOrder = order[a.severity] ?? 2;
        final bOrder = order[b.severity] ?? 2;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        return 0;
      });

      // Rotate daily based on day of year
      final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
      final index = dayOfYear % sorted.length;

      setState(() {
        _insight = sorted[index];
        _loaded = true;
      });
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
    if (!_loaded || _insight == null || _dismissed) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final accent = _accentColor(_insight!.severity);

    return Dismissible(
      key: ValueKey(_insight!.text),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => setState(() => _dismissed = true),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            // Left accent bar
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(_insight!.icon, size: 16, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_insight!.text,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => setState(() => _dismissed = true),
              child: Icon(LucideIcons.x, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => context.go('/dashboard'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text('See all \u2192',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorScheme.primary)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
