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
import '../../tools/providers/tool_providers.dart';
import '../providers/upcoming_payments_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    ref.invalidate(transactionsSummaryProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(billsSummaryProvider);
    ref.invalidate(debtSummaryProvider);
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ─── Greeting ────────────────────────────────────────────
          StaggeredFadeIn(
            index: 0,
            child: Text(
              '${getTimeGreeting()}, $firstName',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3),
            ),
          ),
          const SizedBox(height: 2),
          StaggeredFadeIn(
            index: 0,
            child: Text(
              "Here's your snapshot for today.",
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Current Stage Card ──────────────────────────────────
          StaggeredFadeIn(
            index: 1,
            child: _CurrentStageCard(onTap: () => context.go('/guide')),
          ),
          const SizedBox(height: 14),

          // ─── Financial Summary ───────────────────────────────────
          StaggeredFadeIn(
            index: 2,
            child: summary.when(
              data: (s) => Row(
                children: [
                  _FinStat(
                    icon: LucideIcons.wallet,
                    label: 'Balance',
                    value: s.balance,
                    iconColor: colorScheme.onSurfaceVariant,
                    valueColor: colorScheme.onSurface,
                    onTap: () => context.go('/dashboard'),
                  ),
                  const SizedBox(width: 8),
                  _FinStat(
                    icon: LucideIcons.trendingUp,
                    label: 'Income',
                    value: s.income,
                    iconColor: AppColors.income,
                    valueColor: AppColors.income,
                    onTap: () => context.go('/dashboard'),
                  ),
                  const SizedBox(width: 8),
                  _FinStat(
                    icon: LucideIcons.trendingDown,
                    label: 'Expenses',
                    value: s.expenses,
                    iconColor: colorScheme.onSurfaceVariant,
                    valueColor: colorScheme.onSurface,
                    onTap: () => context.go('/dashboard'),
                  ),
                ],
              ),
              loading: () => const ShimmerStatRow(count: 3),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 18),

          // ─── Upcoming Payments ───────────────────────────────────
          StaggeredFadeIn(
            index: 3,
            child: _UpcomingPaymentsSection(ref: ref),
          ),

          // ─── Next Steps Carousel ─────────────────────────────────
          StaggeredFadeIn(
            index: 4,
            child: _NextStepsSection(),
          ),

          // ─── Quick Navigation ────────────────────────────────────
          const SizedBox(height: 6),
          StaggeredFadeIn(
            index: 5,
            child: _NavRow(
              icon: LucideIcons.bookOpen,
              iconBg: colorScheme.primary.withValues(alpha: 0.1),
              iconColor: colorScheme.primary,
              title: 'Adulting Guide',
              subtitle: '0% complete · 58 steps remaining',
              onTap: () => context.go('/guide'),
            ),
          ),
          const SizedBox(height: 8),
          StaggeredFadeIn(
            index: 6,
            child: _NavRow(
              icon: LucideIcons.wrench,
              iconBg: AppColors.warning.withValues(alpha: 0.1),
              iconColor: AppColors.warning,
              title: 'Tools',
              subtitle: 'Contributions, bills, debts, insurance & more',
              onTap: () => context.go('/tools'),
            ),
          ),
          const SizedBox(height: 8),
          StaggeredFadeIn(
            index: 7,
            child: _NavRow(
              icon: LucideIcons.wallet,
              iconBg: AppColors.toolEmerald.withValues(alpha: 0.1),
              iconColor: AppColors.toolEmerald,
              title: 'Financial Dashboard',
              subtitle: 'Budgets, trends, spending insights',
              onTap: () => context.go('/dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Current Stage Card ────────────────────────────────────────────────────────

class _CurrentStageCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CurrentStageCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const stageColor = StageColors.blue; // Unang Hakbang = blue

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Stage icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: stageColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.bookOpen, size: 20, color: stageColor),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CURRENT STAGE',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        letterSpacing: 0.8, color: colorScheme.onSurfaceVariant,
                      )),
                  const SizedBox(height: 3),
                  const Text('Unang Hakbang',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 0,
                              minHeight: 6,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              color: stageColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('0/58',
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }
}

// ─── Financial Stat Card ───────────────────────────────────────────────────────

class _FinStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color iconColor;
  final Color valueColor;
  final VoidCallback onTap;

  const _FinStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.valueColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 12, color: iconColor),
                  const SizedBox(width: 4),
                  Text(label,
                      style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedCurrency(
                value: value,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Upcoming Payments ─────────────────────────────────────────────────────────

const _typeConfig = <PaymentType, ({IconData icon, Color color})>{
  PaymentType.bill: (icon: LucideIcons.receipt, color: Color(0xFF3B82F6)),
  PaymentType.debt: (icon: LucideIcons.creditCard, color: Color(0xFF8B5CF6)),
  PaymentType.insurance: (icon: LucideIcons.shield, color: Color(0xFF10B981)),
  PaymentType.contribution: (icon: LucideIcons.landmark, color: Color(0xFFF59E0B)),
};

class _UpcomingPaymentsSection extends StatelessWidget {
  final WidgetRef ref;
  const _UpcomingPaymentsSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final upcoming = ref.watch(upcomingPaymentsProvider);

    return upcoming.when(
      data: (data) {
        if (data.items.isEmpty) return const SizedBox.shrink();

        final visible = data.items.take(5).toList();
        final remaining = data.items.length - visible.length;

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text('UPCOMING PAYMENTS',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          letterSpacing: 0.8, color: colorScheme.onSurfaceVariant,
                        )),
                    if (data.overdueCount > 0) ...[
                      const SizedBox(width: 8),
                      Row(children: [
                        const Icon(LucideIcons.alertCircle, size: 12, color: AppColors.expense),
                        const SizedBox(width: 3),
                        Text('${data.overdueCount} overdue',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                color: AppColors.expense)),
                      ]),
                    ],
                  ]),
                  Text(formatCurrency(data.totalDue),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Items
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: visible.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isLast = entry.key == visible.length - 1;
                  final config = _typeConfig[item.type]!;
                  final urgencyLabel = item.daysUntilDue < 0
                      ? 'Overdue'
                      : item.daysUntilDue == 0
                          ? 'Due today'
                          : '${item.daysUntilDue}d';
                  final urgencyColor = item.daysUntilDue < 0
                      ? AppColors.expense
                      : item.daysUntilDue <= 3
                          ? AppColors.warning
                          : colorScheme.onSurfaceVariant;

                  return _PaymentItem(
                    icon: config.icon,
                    iconColor: config.color,
                    iconBg: config.color.withValues(alpha: 0.1),
                    title: item.title,
                    subtitle: item.subtitle,
                    amount: item.amount,
                    urgency: urgencyLabel,
                    urgencyColor: urgencyColor,
                    showDivider: !isLast,
                  );
                }).toList(),
              ),
            ),

            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('+$remaining more upcoming',
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ),

            const SizedBox(height: 18),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final double amount;
  final String urgency;
  final Color? urgencyColor;
  final bool showDivider;

  const _PaymentItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.urgency,
    this.urgencyColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(subtitle,
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatCurrency(amount),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (urgency.isNotEmpty)
                    Text(urgency,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                            color: urgencyColor ?? colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronRight, size: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.25)),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 56, color: colorScheme.outline.withValues(alpha: 0.08)),
      ],
    );
  }
}

// ─── Next Steps Carousel ───────────────────────────────────────────────────────

class _NextStepsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Static next steps based on guide data
    final steps = [
      _NextStep(
        type: 'checklist',
        title: 'Get your TIN from BIR',
        description: 'Your Tax Identification Number is required for employment, banking, business registration,...',
        actionLabel: 'View Guide',
      ),
      _NextStep(
        type: 'checklist',
        title: 'Register with SSS',
        description: 'The Social Security System provides retirement pension, disability benefits,...',
        actionLabel: 'View Guide',
      ),
      _NextStep(
        type: 'checklist',
        title: 'Register with PhilHealth',
        description: 'Philippine Health Insurance Corporation provides healthcare coverage...',
        actionLabel: 'View Guide',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('NEXT STEPS',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 0.8, color: colorScheme.onSurfaceVariant,
              )),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: steps.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _NextStepCard(step: steps[i]),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _NextStep {
  final String type;
  final String title;
  final String description;
  final String actionLabel;
  const _NextStep({
    required this.type,
    required this.title,
    required this.description,
    required this.actionLabel,
  });
}

class _NextStepCard extends StatefulWidget {
  final _NextStep step;
  const _NextStepCard({required this.step});

  @override
  State<_NextStepCard> createState() => _NextStepCardState();
}

class _NextStepCardState extends State<_NextStepCard> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final isChecklist = widget.step.type == 'checklist';
    final accentColor = isChecklist ? AppColors.warning : colorScheme.primary;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isChecklist ? LucideIcons.alertCircle : LucideIcons.bookOpen,
                  size: 14, color: accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isChecklist ? 'NEXT STEP' : 'READ',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    letterSpacing: 0.8, color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _dismissed = true),
                child: Icon(LucideIcons.x, size: 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Title
          Text(widget.step.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          // Description
          Expanded(
            child: Text(widget.step.description,
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, height: 1.3),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          // Action
          Row(
            children: [
              Text(widget.step.actionLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary)),
              const SizedBox(width: 4),
              Icon(LucideIcons.arrowRight, size: 12, color: colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Navigation Row ────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(subtitle,
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.25)),
          ],
        ),
      ),
    );
  }
}
