import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transaction_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    ref.invalidate(transactionsSummaryProvider);
    ref.invalidate(profileProvider);
    await ref.read(transactionsSummaryProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = ref.watch(profileProvider);
    final firstName = profile.valueOrNull?.firstName ?? 'there';
    final summary = ref.watch(transactionsSummaryProvider);

    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Greeting
          StaggeredFadeIn(
            index: 0,
            child: Text(
              '${getTimeGreeting()}, $firstName',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          StaggeredFadeIn(
            index: 0,
            child: Text(
              "Here's your snapshot for today.",
              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 20),

          // Financial summary
          StaggeredFadeIn(
            index: 1,
            child: summary.when(
              data: (s) => Row(
                children: [
                  _FinStat(label: 'Balance', value: s.balance, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  _FinStat(label: 'Income', value: s.income, color: AppColors.income),
                  const SizedBox(width: 8),
                  _FinStat(label: 'Expenses', value: s.expenses, color: AppColors.expense),
                ],
              ),
              loading: () => const ShimmerStatRow(count: 3),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 20),

          // Quick navigation
          StaggeredFadeIn(
            index: 2,
            child: _QuickNavCard(
              icon: LucideIcons.bookOpen,
              iconColor: const Color(0xFF3B82F6),
              title: 'Adulting Guide',
              subtitle: 'Life stage guides & checklists',
              onTap: () => context.go('/guide'),
            ),
          ),
          const SizedBox(height: 8),
          StaggeredFadeIn(
            index: 3,
            child: _QuickNavCard(
              icon: LucideIcons.wrench,
              iconColor: const Color(0xFFF59E0B),
              title: 'Tools',
              subtitle: 'Contributions, bills & more',
              onTap: () => context.go('/tools'),
            ),
          ),
          const SizedBox(height: 8),
          StaggeredFadeIn(
            index: 4,
            child: _QuickNavCard(
              icon: LucideIcons.wallet,
              iconColor: const Color(0xFF10B981),
              title: 'Financial Dashboard',
              subtitle: 'Budgets, trends & insights',
              onTap: () => context.go('/dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _FinStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            AnimatedCurrency(
              value: value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
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
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
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
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
