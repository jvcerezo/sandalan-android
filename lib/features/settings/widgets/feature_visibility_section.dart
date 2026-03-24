import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      final visible = visibility[key] ?? FeatureKeys.defaultFor(key);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Switch(
            value: visible,
            onChanged: (_) {
              notifier.toggle(key);
              final nowVisible = !(visibility[key] ?? FeatureKeys.defaultFor(key));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(nowVisible ? '$label is now visible' : '$label hidden from menu'),
                duration: const Duration(seconds: 2),
              ));
            },
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
        toggle(FeatureKeys.investments, 'Investments', LucideIcons.trendingUp),
        toggle(FeatureKeys.splitBills, 'Split Bills', LucideIcons.users),
        toggle(FeatureKeys.salaryAllocation, 'Salary Allocation', LucideIcons.banknote),
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
        toggle(FeatureKeys.currency, 'Currency Converter', LucideIcons.globe),
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
      const SizedBox(height: 12),

      // App
      Text('APP',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.8, color: cs.onSurfaceVariant)),
      const SizedBox(height: 4),
      SettingsCard(child: Column(children: [
        toggle(FeatureKeys.achievements, 'Achievements', LucideIcons.award),
        toggle(FeatureKeys.reports, 'Reports', LucideIcons.barChart3),
      ])),
      const SizedBox(height: 16),

      // Reset
      Center(child: TextButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          for (final key in FeatureKeys.allKeys) {
            await prefs.remove(key);
          }
          // Reload to pick up defaults
          await notifier.reload();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reset to beginner defaults.')),
            );
          }
        },
        child: Text('Reset to defaults',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      )),

      // Show all
      Center(child: TextButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          for (final key in FeatureKeys.allKeys) {
            await prefs.setBool(key, true);
          }
          await notifier.reload();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All features enabled.')),
            );
          }
        },
        child: Text('Show all features',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
      )),
    ]);
  }
}
