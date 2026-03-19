import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // TODO: Replace with actual user name from profile provider
    const firstName = 'there';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Greeting
        Text(
          '${getTimeGreeting()}, $firstName',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's your snapshot for today.",
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // TODO: Current stage card (Phase 7)
        // TODO: Financial summary row (Phase 3)
        // TODO: Upcoming payments (Phase 6)
        // TODO: Next steps carousel (Phase 3)

        // Quick navigation
        const SizedBox(height: 8),
        _QuickNavRow(),
      ],
    );
  }
}

class _QuickNavRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _QuickNavCard(
          icon: LucideIcons.bookOpen,
          iconColor: const Color(0xFF3B82F6),
          title: 'Adulting Guide',
          subtitle: 'Life stage guides & checklists',
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _QuickNavCard(
          icon: LucideIcons.wrench,
          iconColor: const Color(0xFFF59E0B),
          title: 'Tools',
          subtitle: 'Contributions, bills & more',
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _QuickNavCard(
          icon: LucideIcons.wallet,
          iconColor: const Color(0xFF10B981),
          title: 'Financial Dashboard',
          subtitle: 'Budgets, trends & insights',
          onTap: () {},
        ),
      ],
    );
  }
}

class _QuickNavCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickNavCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
