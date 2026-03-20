import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../transactions/providers/transaction_providers.dart';

class PanganayModeScreen extends ConsumerWidget {
  const PanganayModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final txns = ref.watch(transactionsProvider);

    return txns.when(
      data: (list) {
        final now = DateTime.now();
        final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

        double familyTotal = 0;
        double personalTotal = 0;
        for (final t in list) {
          if (t.amount >= 0 || !t.date.startsWith(thisMonth)) continue;
          if (t.category.toLowerCase() == 'family support' ||
              (t.tags?.any((tag) => tag.contains('family')) ?? false)) {
            familyTotal += t.amount.abs();
          } else {
            personalTotal += t.amount.abs();
          }
        }
        final total = familyTotal + personalTotal;
        final familyPct = total > 0 ? (familyTotal / total * 100) : 0.0;
        final personalPct = total > 0 ? (personalTotal / total * 100) : 0.0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          children: [
            GestureDetector(
              onTap: () => context.go('/tools'),
              child: Padding(padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(LucideIcons.arrowLeft, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('Tools', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                ])),
            ),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.toolPink.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.heart, size: 20, color: AppColors.toolPink)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Panganay Mode', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Track family support separately from personal spending. Set boundaries without guilt.',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ])),
            ]),
            const SizedBox(height: 16),

            // Summary cards
            Row(children: [
              _SumCard(label: 'Family Support', value: formatCurrency(familyTotal),
                  sub: 'this month', valueColor: AppColors.toolPink),
              const SizedBox(width: 8),
              _SumCard(label: 'Personal Spending', value: formatCurrency(personalTotal),
                  sub: 'this month'),
            ]),
            const SizedBox(height: 16),

            // Spending Split
            _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Spending Split', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              // Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(height: 12, child: Row(children: [
                  if (familyPct > 0)
                    Expanded(flex: familyPct.round().clamp(1, 100),
                      child: Container(color: AppColors.toolPink)),
                  if (personalPct > 0)
                    Expanded(flex: personalPct.round().clamp(1, 100),
                      child: Container(color: AppColors.info)),
                ])),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.toolPink, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Family (${familyPct.toStringAsFixed(0)}%)', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ]),
                Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.info, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Personal (${personalPct.toStringAsFixed(0)}%)', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ]),
              ]),
            ])),
            const SizedBox(height: 16),

            // Empty state or family expenses
            if (familyTotal == 0)
              _Card(child: Center(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(children: [
                  const Text('No family support expenses yet this month',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Tag your expenses with "Family Support" category or add the "family-support" tag when logging transactions. '
                      'You can also add recipient tags like "family:parents" or "family:sibling".',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.4),
                      textAlign: TextAlign.center),
                ]),
              ))),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child; const _Card({required this.child});
  @override
  Widget build(BuildContext c) => Container(width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(c).colorScheme.surface,
      border: Border.all(color: Theme.of(c).colorScheme.surfaceContainerHighest),
      borderRadius: BorderRadius.circular(12)), child: child);
}

class _SumCard extends StatelessWidget {
  final String label, value, sub; final Color? valueColor;
  const _SumCard({required this.label, required this.value, required this.sub, this.valueColor});
  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return Expanded(child: Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface,
        border: Border.all(color: cs.surfaceContainerHighest), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
        Text(sub, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
      ])));
  }
}
