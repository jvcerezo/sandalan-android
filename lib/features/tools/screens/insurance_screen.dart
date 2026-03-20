import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/automation_service.dart';
import '../../../data/models/insurance_policy.dart';
import '../providers/tool_providers.dart';
import '../widgets/add_insurance_dialog.dart';
import '../widgets/pay_insurance_dialog.dart';

class InsuranceScreen extends ConsumerStatefulWidget {
  const InsuranceScreen({super.key});

  @override
  ConsumerState<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends ConsumerState<InsuranceScreen> {
  bool _remindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPref();
  }

  Future<void> _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _remindersEnabled = prefs.getBool('insurance_reminders_enabled') ?? true;
      });
    }
  }

  Future<void> _toggleReminders() async {
    final newValue = !_remindersEnabled;
    setState(() => _remindersEnabled = newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('insurance_reminders_enabled', newValue);

    if (newValue) {
      await NotificationService.instance.requestPermission();
      await AutomationService.runOnAppStart();
    } else {
      await NotificationService.instance.cancelAll();
      await AutomationService.runOnAppStart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final policies = ref.watch(insurancePoliciesProvider);
    final summary = ref.watch(insuranceSummaryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        // ← Tools
        GestureDetector(
          onTap: () => context.go('/tools'),
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.arrowLeft, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Tools', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ]),
          ),
        ),

        // Header
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.toolTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.shield, size: 20, color: AppColors.toolTeal),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Insurance Tracker', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Monitor all your policies and renewal dates',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 16),

        // Summary cards
        summary.when(
          data: (s) => Row(children: [
            _SumCard(label: 'Annual Premium', value: formatCurrency(s.annualPremium)),
            const SizedBox(width: 8),
            _SumCard(label: 'Total Coverage', value: formatCurrency(s.totalCoverage),
                highlight: true, highlightColor: AppColors.toolTeal),
            const SizedBox(width: 8),
            _SumCard(label: 'Renewing Soon', value: '${s.renewalSoonCount}'),
          ]),
          loading: () => const SizedBox(height: 60),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),

        // Premium Reminders
        _Card(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.zap, size: 18, color: AppColors.income),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Premium Reminders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Get notified before your insurance premiums are due.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            ...[
              'Policies with a renewal date appear in Upcoming Payments on your Home page',
              'Push notifications sent before your next premium is due',
              'Pay premium to record a transaction from your linked account',
              'Set a renewal date on each policy to enable reminders',
            ].map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('•  ', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                Expanded(child: Text(t, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))),
              ]),
            )),
          ])),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _toggleReminders,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _remindersEnabled
                    ? AppColors.warning.withValues(alpha: 0.15)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_remindersEnabled) const Icon(LucideIcons.bell, size: 12, color: AppColors.warning),
                if (_remindersEnabled) const SizedBox(width: 4),
                Text(_remindersEnabled ? 'On' : 'Off',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: _remindersEnabled ? AppColors.warning : cs.onSurfaceVariant)),
              ]),
            ),
          ),
        ])),
        const SizedBox(height: 16),

        // Add Policy
        OutlinedButton.icon(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const AddInsuranceDialog(),
            ).then((result) {
              if (result == true) {
                ref.invalidate(insurancePoliciesProvider);
                ref.invalidate(insuranceSummaryProvider);
              }
            });
          },
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Add Policy'),
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),

        // Active Policies
        policies.when(
          data: (list) {
            final active = list.where((p) => p.isActive).toList();
            return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Active Policies (${active.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (active.isEmpty)
                Center(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No policies yet', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                ))
              else
                ...active.map((p) => _PolicyRow(policy: p, ref: ref)),
            ]));
          },
          loading: () => const SizedBox(height: 80),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),

        // Insurance Rule of Thumb
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Insurance Rule of Thumb', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...[
            'Life: At least 10x your annual income in coverage.',
            'Health/HMO: Ensure your annual MBL (Maximum Benefit Limit) covers at least ₱500k.',
            'Car: CTPL is mandatory. Comprehensive is recommended for newer vehicles.',
            'Property: If you own real estate, secure fire and natural disaster coverage.',
          ].map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('•  ', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              Expanded(child: Text(t, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.3))),
            ]),
          )),
        ])),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );
}

class _SumCard extends StatelessWidget {
  final String label, value;
  final bool highlight;
  final Color? highlightColor;
  const _SumCard({required this.label, required this.value, this.highlight = false, this.highlightColor});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? (highlightColor ?? cs.primary).withValues(alpha: 0.06) : cs.surface,
        border: Border.all(color: cs.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ]),
    ));
  }
}

class _PolicyRow extends StatelessWidget {
  final InsurancePolicy policy;
  final WidgetRef ref;
  const _PolicyRow({required this.policy, required this.ref});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final freq = _freqShort(policy.premiumFrequency);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.toolTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.shield, size: 16, color: AppColors.toolTeal),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(policy.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(policy.type, style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
            ),
          ]),
          Text([
            if (policy.provider != null) '${policy.provider}',
            '${formatCurrency(policy.premiumAmount)}/$freq',
            if (policy.coverageAmount != null) 'Covered: ${formatCurrency(policy.coverageAmount!)}',
          ].join(' · '), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ])),
        Text('${formatCurrency(policy.premiumAmount)}/$freq',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        // Pay premium
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => PayInsuranceDialog(policy: policy),
            ).then((result) {
              if (result == true) {
                ref.invalidate(insurancePoliciesProvider);
                ref.invalidate(insuranceSummaryProvider);
              }
            });
          },
          icon: Icon(LucideIcons.circleDollarSign, size: 16, color: cs.onSurfaceVariant),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
        // Renew
        IconButton(
          onPressed: () {},
          icon: Icon(LucideIcons.refreshCw, size: 14, color: cs.onSurfaceVariant),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
        // Delete
        IconButton(
          onPressed: () async {
            await ref.read(insuranceRepositoryProvider).deletePolicy(policy.id);
            ref.invalidate(insurancePoliciesProvider);
            ref.invalidate(insuranceSummaryProvider);
          },
          icon: Icon(LucideIcons.trash2, size: 14, color: AppColors.expense.withValues(alpha: 0.5)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ]),
    );
  }

  String _freqShort(String f) {
    switch (f) {
      case 'monthly': return 'mo';
      case 'quarterly': return 'qtr';
      case 'semi_annual': return '6mo';
      case 'annual': return 'yr';
      default: return 'mo';
    }
  }
}
