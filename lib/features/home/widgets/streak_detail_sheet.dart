import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Bottom sheet showing streak details with weekly history.
class StreakDetailSheet extends StatelessWidget {
  final int streak;
  final int bestStreak;
  final List<bool> weekHistory; // Mon-Sun

  const StreakDetailSheet({
    super.key,
    required this.streak,
    required this.bestStreak,
    required this.weekHistory,
  });

  static void show(BuildContext context, {
    required int streak,
    required int bestStreak,
    required List<bool> weekHistory,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StreakDetailSheet(
        streak: streak,
        bestStreak: bestStreak,
        weekHistory: weekHistory,
      ),
    );
  }

  Color _flameColor(int s) {
    if (s >= 100) return const Color(0xFFEF4444); // red
    if (s >= 30) return const Color(0xFFF97316);  // orange
    if (s >= 7) return const Color(0xFFF59E0B);   // amber
    return const Color(0xFF9CA3AF);                // gray
  }

  String _nextMilestoneText(int s) {
    const milestones = [7, 14, 30, 60, 90, 100, 200, 365];
    for (final m in milestones) {
      if (s < m) {
        final remaining = m - s;
        return '$remaining more day${remaining == 1 ? '' : 's'} until your $m-day streak!';
      }
    }
    return 'Incredible streak! Keep it going!';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final flameC = _flameColor(streak);
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Large flame icon
          Icon(LucideIcons.flame, size: 48, color: flameC),
          const SizedBox(height: 12),

          // Streak number
          Text(
            '$streak day${streak == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          // Best streak
          Text(
            'Your longest streak: $bestStreak day${bestStreak == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          // 7-day dot strip
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (i) {
              final active = i < weekHistory.length && weekHistory[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? colorScheme.primary : Colors.transparent,
                        border: Border.all(
                          color: active
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: active
                          ? Icon(LucideIcons.check, size: 14, color: colorScheme.onPrimary)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayLabels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: active
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Next milestone
          Text(
            _nextMilestoneText(streak),
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Filipino motivational line
          Text(
            'Tuloy-tuloy lang!',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
