import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../data/tips/daily_tips.dart';

/// Compact "Did You Know?" card showing today's tip.
class TipOfDayCard extends StatelessWidget {
  final DailyTip tip;
  final VoidCallback onDismiss;

  const TipOfDayCard({
    super.key,
    required this.tip,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const amber = Color(0xFFF59E0B);

    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amber left accent bar
          Container(width: 4, height: 72, color: amber),

          // Lightbulb icon
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 0, 14),
            child: Icon(LucideIcons.lightbulb, size: 28, color: amber),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DID YOU KNOW?',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip.text,
                    style: const TextStyle(fontSize: 12, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tip.learnMoreRoute != null) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => context.go(tip.learnMoreRoute!),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Learn more',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(LucideIcons.arrowRight, size: 11, color: colorScheme.primary),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Dismiss X
          Semantics(
            label: 'Dismiss tip',
            button: true,
            child: InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Icon(
                    LucideIcons.x,
                    size: 14,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
