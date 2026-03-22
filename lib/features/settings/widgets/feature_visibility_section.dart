import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/feature_visibility_provider.dart';
import 'settings_shared.dart';

class FeatureVisibilitySection extends ConsumerWidget {
  final Widget back;
  const FeatureVisibilitySection({super.key, required this.back});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibility = ref.watch(featureVisibilityProvider);
    final notifier = ref.read(featureVisibilityProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    Widget toggle(String key, String label, IconData icon) {
      final visible = visibility[key] ?? true;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Switch(
            value: visible,
            onChanged: (_) => notifier.toggle(key),
          ),
        ]),
      );
    }

    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      back,
      SettingsCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.eyeOff, size: 18, color: cs.onSurface),
          const SizedBox(width: 8),
          const Text('Feature Visibility',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        Text('Show or hide features you don\'t need yet.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      ])),
      const SizedBox(height: 12),

      // Calculators & Tools
      Text('CALCULATORS & TOOLS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.8, color: cs.onSurfaceVariant)),
      const SizedBox(height: 4),
      SettingsCard(child: Column(children: [
        toggle(FeatureKeys.taxTracker, 'BIR Tax Tracker', LucideIcons.fileText),
        toggle(FeatureKeys.thirteenthMonth, '13th Month Pay', LucideIcons.gift),
        toggle(FeatureKeys.retirement, 'Retirement Projection', LucideIcons.sunset),
        toggle(FeatureKeys.rentVsBuy, 'Rent vs Buy Calculator', LucideIcons.home),
        toggle(FeatureKeys.panganay, 'Panganay Mode', LucideIcons.users),
        toggle(FeatureKeys.calculators, 'Financial Calculators', LucideIcons.calculator),
      ])),
      const SizedBox(height: 12),

      // Finance tracking
      Text('FINANCE TRACKING',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.8, color: cs.onSurfaceVariant)),
      const SizedBox(height: 4),
      SettingsCard(child: Column(children: [
        toggle(FeatureKeys.bills, 'Bills & Subscriptions', LucideIcons.receipt),
        toggle(FeatureKeys.debts, 'Debt Manager', LucideIcons.creditCard),
        toggle(FeatureKeys.insurance, 'Insurance Tracker', LucideIcons.shield),
        toggle(FeatureKeys.contributions, 'Gov\'t Contributions', LucideIcons.landmark),
      ])),
      const SizedBox(height: 12),

      // Dashboard sections
      Text('DASHBOARD SECTIONS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.8, color: cs.onSurfaceVariant)),
      const SizedBox(height: 4),
      SettingsCard(child: Column(children: [
        toggle(FeatureKeys.budgets, 'Budgets', LucideIcons.pieChart),
        toggle(FeatureKeys.goals, 'Goals', LucideIcons.target),
        toggle(FeatureKeys.healthScore, 'Financial Health Score', LucideIcons.heart),
        toggle(FeatureKeys.spendingChart, 'Spending Chart', LucideIcons.barChart3),
      ])),
      const SizedBox(height: 16),

      // Reset
      Center(child: TextButton(
        onPressed: () async {
          for (final key in FeatureKeys.allKeys) {
            if (!(visibility[key] ?? true)) {
              await notifier.toggle(key);
            }
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All features restored.')),
            );
          }
        },
        child: Text('Reset to defaults',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      )),
    ]);
  }
}
