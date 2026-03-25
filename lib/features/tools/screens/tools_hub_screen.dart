import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/color_tokens.dart';

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Calculators & Tools',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          'Financial calculators for every stage of adulting.',
          style: TextStyle(fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),

        // Compliance
        _ToolSection(title: 'Compliance', tools: [
          _ToolItem(
            icon: LucideIcons.receipt,
            color: AppColors.toolOrange,
            title: 'BIR Tax Tracker',
            subtitle: 'Income tax & filing',
            onTap: () => context.go('/tools/taxes'),
          ),
          _ToolItem(
            icon: LucideIcons.gift,
            color: AppColors.toolGreen,
            title: '13th Month Pay',
            subtitle: 'Tax exemption calculator',
            onTap: () => context.go('/tools/13th-month'),
          ),
        ]),
        const SizedBox(height: 16),

        // Planning
        _ToolSection(title: 'Planning', tools: [
          _ToolItem(
            icon: LucideIcons.piggyBank,
            color: AppColors.toolAmber,
            title: 'Retirement Projection',
            subtitle: 'SSS pension & savings gap',
            onTap: () => context.go('/tools/retirement'),
          ),
          _ToolItem(
            icon: LucideIcons.home,
            color: AppColors.toolEmerald,
            title: 'Rent vs Buy',
            subtitle: 'Housing cost comparison',
            onTap: () => context.go('/tools/rent-vs-buy'),
          ),
          _ToolItem(
            icon: LucideIcons.heart,
            color: AppColors.toolPink,
            title: 'Panganay Mode',
            subtitle: 'Family support budgeting',
            onTap: () => context.go('/tools/panganay'),
          ),
          _ToolItem(
            icon: LucideIcons.calculator,
            color: AppColors.toolPurple,
            title: 'Financial Calculators',
            subtitle: 'Interest, loans & FIRE',
            onTap: () => context.go('/tools/calculators'),
          ),
        ]),
        const SizedBox(height: 16),

        // Utilities
        _ToolSection(title: 'Utilities', tools: [
          _ToolItem(
            icon: LucideIcons.globe,
            color: AppColors.toolBlue,
            title: 'Currency Converter',
            subtitle: 'Convert between currencies',
            onTap: () => context.go('/tools/currency'),
          ),
        ]),
      ],
    );
  }
}

class _ToolSection extends StatelessWidget {
  final String title;
  final List<_ToolItem> tools;

  const _ToolSection({required this.title, required this.tools});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
          ),
          ...tools,
        ],
      ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
