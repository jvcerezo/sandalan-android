import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/feature_visibility_provider.dart';
import '../../../core/services/premium_service.dart';
import '../../goals/providers/goal_providers.dart';
import '../../tools/providers/tool_providers.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../../core/services/invite_service.dart';
import '../../settings/widgets/feedback_dialog.dart';
import '../../transactions/screens/receipt_scanner_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final vis = ref.watch(featureVisibilityProvider);

    bool show(String key) => vis[key] ?? FeatureKeys.defaultFor(key);

    // Live data for context badges
    final goalsSummary = ref.watch(goalsSummaryProvider);
    final billsSummary = ref.watch(billsSummaryProvider);
    final debtSummary = ref.watch(debtSummaryProvider);
    final insuranceSummary = ref.watch(insuranceSummaryProvider);

    // Build manage items (filtered by visibility)
    final manageItems = <Widget>[
      if (show(FeatureKeys.goals))
        _MoreItem(
          icon: LucideIcons.target,
          color: AppColors.toolBlue,
          title: 'Goals',
          subtitle: 'Savings targets & progress',
          badge: goalsSummary.whenOrNull(data: (gs) => gs.active > 0 ? '${gs.active} active' : null),
          onTap: () => context.go('/goals'),
        ),
      if (show(FeatureKeys.bills))
        _MoreItem(
          icon: LucideIcons.receipt,
          color: AppColors.toolOrange,
          title: 'Bills & Payments',
          subtitle: 'Recurring bills & due dates',
          badge: billsSummary.whenOrNull(data: (bs) => bs.dueSoonCount > 0 ? '${bs.dueSoonCount} due soon' : null),
          badgeColor: AppColors.warning,
          onTap: () => context.go('/tools/bills'),
        ),
      if (show(FeatureKeys.debts))
        _MoreItem(
          icon: LucideIcons.creditCard,
          color: AppColors.toolRed,
          title: 'Debts',
          subtitle: 'Track and pay off debts',
          badge: debtSummary.whenOrNull(data: (ds) => ds.totalDebt > 0 ? formatCurrency(ds.totalDebt) : null),
          onTap: () => context.go('/tools/debts'),
        ),
      if (show(FeatureKeys.insurance))
        _MoreItem(
          icon: LucideIcons.shield,
          color: AppColors.toolTeal,
          title: 'Insurance',
          subtitle: 'Policies & premium tracking',
          badge: insuranceSummary.whenOrNull(data: (is_) => is_.renewalSoonCount > 0 ? '${is_.renewalSoonCount} renewing' : null),
          badgeColor: AppColors.warning,
          onTap: () => context.go('/tools/insurance'),
        ),
      if (show(FeatureKeys.investments))
        _MoreItem(
          icon: LucideIcons.trendingUp,
          color: AppColors.toolGreen,
          title: 'Investments',
          subtitle: 'Portfolio tracker',
          onTap: () => context.go('/investments'),
        ),
      if (show(FeatureKeys.splitBills))
        _MoreItem(
          icon: LucideIcons.users,
          color: AppColors.toolPink,
          title: 'Split Bills',
          subtitle: 'Shared expenses with friends',
          onTap: () => context.go('/split-bills'),
        ),
      if (show(FeatureKeys.salaryAllocation))
        _MoreItem(
          icon: LucideIcons.banknote,
          color: AppColors.toolAmber,
          title: 'Salary Allocation',
          subtitle: 'Budget by paycheck percentage',
          onTap: () => context.go('/salary-allocation'),
        ),
    ];

    // Build tools items (filtered by visibility)
    final toolItems = <Widget>[
      if (show(FeatureKeys.contributions))
        _MoreItem(
          icon: LucideIcons.landmark,
          color: AppColors.sss,
          title: 'Gov\'t Contributions',
          subtitle: 'SSS, PhilHealth & Pag-IBIG',
          onTap: () => context.go('/tools/contributions'),
        ),
      if (show(FeatureKeys.taxTracker))
        _MoreItem(
          icon: LucideIcons.receipt,
          color: AppColors.toolOrange,
          title: 'Tax Tracker',
          subtitle: 'BIR income tax & filing',
          onTap: () => context.go('/tools/taxes'),
        ),
      if (show(FeatureKeys.thirteenthMonth))
        _MoreItem(
          icon: LucideIcons.gift,
          color: AppColors.toolGreen,
          title: '13th Month Calculator',
          subtitle: 'Compute your bonus',
          onTap: () => context.go('/tools/13th-month'),
        ),
      if (show(FeatureKeys.retirement))
        _MoreItem(
          icon: LucideIcons.sunset,
          color: AppColors.toolAmber,
          title: 'Retirement Planner',
          subtitle: 'SSS pension & savings gap',
          onTap: () => context.go('/tools/retirement'),
        ),
      if (show(FeatureKeys.rentVsBuy))
        _MoreItem(
          icon: LucideIcons.home,
          color: AppColors.toolEmerald,
          title: 'Rent vs Buy',
          subtitle: 'Housing cost comparison',
          onTap: () => context.go('/tools/rent-vs-buy'),
        ),
      if (show(FeatureKeys.panganay))
        _MoreItem(
          icon: LucideIcons.heart,
          color: AppColors.toolPink,
          title: 'Panganay Mode',
          subtitle: 'Family support budgeting',
          onTap: () => context.go('/tools/panganay'),
        ),
      if (show(FeatureKeys.calculators))
        _MoreItem(
          icon: LucideIcons.calculator,
          color: AppColors.toolPurple,
          title: 'Financial Calculators',
          subtitle: 'Interest, loans & FIRE',
          onTap: () => context.go('/tools/calculators'),
        ),
      if (show(FeatureKeys.currency))
        _MoreItem(
          icon: LucideIcons.globe,
          color: AppColors.toolBlue,
          title: 'Currency Converter',
          subtitle: 'Convert between currencies',
          onTap: () {
            if (PremiumService.instance.hasAccess(PremiumFeature.exchangeRates)) {
              context.go('/tools/currency');
            } else {
              showPremiumGateWithPaywall(context, PremiumFeature.exchangeRates);
            }
          },
        ),
    ];

    // Count hidden features for the hint
    final totalHideable = FeatureKeys.allKeys.length;
    final hiddenCount = FeatureKeys.allKeys.where((k) => !show(k)).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        const Text('More',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
        const SizedBox(height: 2),
        Text('All features & tools',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        const SizedBox(height: 20),

        // ─── Manage ────────────────────────────────────────────────
        if (manageItems.isNotEmpty) ...[
          const StaggeredFadeIn(index: 0, child: _SectionHeader(title: 'Manage')),
          ...manageItems.asMap().entries.map((e) =>
            StaggeredFadeIn(index: e.key + 1, baseDelay: const Duration(milliseconds: 30), child: e.value)),
          const SizedBox(height: 16),
        ],

        // ─── Tools ─────────────────────────────────────────────────
        if (toolItems.isNotEmpty) ...[
          StaggeredFadeIn(index: manageItems.length + 1, child: const _SectionHeader(title: 'Tools')),
          ...toolItems.asMap().entries.map((e) =>
            StaggeredFadeIn(index: e.key + manageItems.length + 2, baseDelay: const Duration(milliseconds: 30), child: e.value)),
          const SizedBox(height: 16),
        ],

        // ─── App (always visible) ──────────────────────────────────
        const _SectionHeader(title: 'App'),
        if (show(FeatureKeys.reports))
          _MoreItem(
            icon: LucideIcons.barChart3,
            color: AppColors.toolIndigo,
            title: 'Reports',
            subtitle: 'Monthly financial summaries',
            onTap: () {
              if (PremiumService.instance.hasAccess(PremiumFeature.advancedReports)) {
                context.go('/reports');
              } else {
                showPremiumGateWithPaywall(context, PremiumFeature.advancedReports);
              }
            },
          ),
        if (show(FeatureKeys.achievements))
          _MoreItem(
            icon: LucideIcons.award,
            color: AppColors.toolAmber,
            title: 'Achievements',
            subtitle: 'Badges & milestones',
            onTap: () => context.go('/achievements'),
          ),
        _MoreItem(
          icon: LucideIcons.messageCircle,
          color: AppColors.toolTeal,
          title: 'AI Chat',
          subtitle: 'Financial assistant',
          onTap: () {
            if (PremiumService.instance.hasAccess(PremiumFeature.aiChat)) {
              context.go('/chat');
            } else {
              showPremiumGateWithPaywall(context, PremiumFeature.aiChat);
            }
          },
        ),
        _MoreItem(
          icon: LucideIcons.scanLine,
          color: cs.onSurfaceVariant,
          title: 'Scan Receipt',
          subtitle: 'OCR transaction import',
          onTap: () {
            if (PremiumService.instance.hasAccess(PremiumFeature.receiptScanner)) {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ReceiptScannerScreen(),
              ));
            } else {
              showPremiumGateWithPaywall(context, PremiumFeature.receiptScanner);
            }
          },
        ),
        _MoreItem(
          icon: LucideIcons.folderLock,
          color: const Color(0xFF6366F1),
          title: 'Document Vault',
          subtitle: 'Store IDs, contracts & important files',
          onTap: () {
            if (PremiumService.instance.hasAccess(PremiumFeature.documentVault)) {
              context.go('/vault');
            } else {
              showPremiumGateWithPaywall(context, PremiumFeature.documentVault);
            }
          },
        ),
        _MoreItem(
          icon: LucideIcons.messageSquare,
          color: const Color(0xFF3B82F6),
          title: 'Send Feedback',
          subtitle: 'Suggestions, bugs, or praise',
          onTap: () => showFeedbackDialog(context),
        ),
        _MoreItem(
          icon: LucideIcons.userPlus,
          color: const Color(0xFF10B981),
          title: 'Invite Friends',
          subtitle: 'Share Sandalan with friends & family',
          onTap: () => InviteService.shareInvite(),
        ),
        _MoreItem(
          icon: LucideIcons.settings,
          color: cs.onSurfaceVariant,
          title: 'Settings',
          subtitle: 'Account, appearance & privacy',
          onTap: () => context.go('/settings'),
        ),

        // ─── Hidden features hint ──────────────────────────────────
        if (hiddenCount > 0) ...[
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => context.go('/settings'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.eyeOff, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      '$hiddenCount feature${hiddenCount == 1 ? '' : 's'} hidden',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.chevronRight, size: 12, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Widgets ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _MoreItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? cs.primary).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(badge!,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                color: badgeColor ?? cs.primary)),
                      ),
                    ],
                  ]),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16,
                color: cs.onSurfaceVariant.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
