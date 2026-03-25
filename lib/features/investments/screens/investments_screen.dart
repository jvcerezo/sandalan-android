import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/investment.dart';
import '../../../data/repositories/local_investment_repository.dart';
import '../widgets/add_investment_dialog.dart';

final investmentsProvider = FutureProvider<List<Investment>>((ref) async {
  final repo = LocalInvestmentRepository(
      AppDatabase.instance, Supabase.instance.client);
  return repo.getInvestments();
});

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final investments = ref.watch(investmentsProvider);
    final hide = ref.watch(hideBalancesProvider);

    return Scaffold(
      body: investments.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (list) {
            final totalInvested = list.fold(0.0, (s, i) => s + i.amountInvested);
            final totalValue = list.fold(0.0, (s, i) => s + i.currentValue);
            final totalGain = totalValue - totalInvested;
            final gainPercent = totalInvested > 0
                ? (totalGain / totalInvested) * 100 : 0.0;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Investments', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(
                      list.isEmpty ? 'Track your portfolio growth'
                          : '${formatCurrency(totalValue)} · ${totalGain >= 0 ? '+' : ''}${gainPercent.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ])),
                  FilledButton.icon(
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Add'),
                    onPressed: () => _showAddDialog(context, ref),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  ),
                ]),
                const SizedBox(height: 16),

                // Portfolio summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('PORTFOLIO VALUE', style: TextStyle(
                        fontSize: 11, letterSpacing: 0.5, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(
                        child: Text(hide ? '••••' : formatCurrency(totalValue),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (totalGain >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${totalGain >= 0 ? '+' : ''}${gainPercent.toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: totalGain >= 0 ? Colors.green : Colors.red),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      _Stat(label: 'Invested', value: hide ? '••••' : formatCurrency(totalInvested)),
                      const SizedBox(width: 16),
                      _Stat(label: totalGain >= 0 ? 'Gain' : 'Loss',
                          value: hide ? '••••' : formatCurrency(totalGain.abs()),
                          color: totalGain >= 0 ? Colors.green : Colors.red),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),

                // Holdings
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('HOLDINGS (${list.length})', style: TextStyle(
                      fontSize: 11, letterSpacing: 0.5, color: cs.onSurfaceVariant)),
                  GestureDetector(
                    onTap: () => _showAddDialog(context, ref),
                    child: Text('+ Add', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
                  ),
                ]),
                const SizedBox(height: 8),

                if (list.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                    ),
                    child: Column(children: [
                      Icon(LucideIcons.trendingUp, size: 32, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      Text('No investments yet', style: TextStyle(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('Start tracking your MP2, UITF, stocks, and more',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                          textAlign: TextAlign.center),
                    ]),
                  )
                else
                  ...list.map((inv) => _InvestmentCard(
                    investment: inv, hide: hide,
                    onUpdate: () => ref.invalidate(investmentsProvider),
                  )),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black54,
      backgroundColor: Colors.transparent,
      builder: (_) => AddInvestmentDialog(
        onSaved: () => ref.invalidate(investmentsProvider),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
          color: color ?? cs.onSurface)),
    ]);
  }
}

class _InvestmentCard extends StatelessWidget {
  final Investment investment;
  final bool hide;
  final VoidCallback onUpdate;
  const _InvestmentCard({required this.investment, required this.hide, required this.onUpdate});

  void _showEditDialog(BuildContext context) {
    final inv = investment;
    final nameCtl = TextEditingController(text: inv.name);
    final amountCtl = TextEditingController(text: inv.amountInvested.toStringAsFixed(0));
    final valueCtl = TextEditingController(text: inv.currentValue.toStringAsFixed(0));
    final notesCtl = TextEditingController(text: inv.notes ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
        title: const Text('Edit Investment', style: TextStyle(fontSize: 16)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words),
          const SizedBox(height: 8),
          TextField(controller: amountCtl,
              decoration: const InputDecoration(labelText: 'Amount Invested (\u20B1)', prefixText: '\u20B1 '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))]),
          const SizedBox(height: 8),
          TextField(controller: valueCtl,
              decoration: const InputDecoration(labelText: 'Current Value (\u20B1)', prefixText: '\u20B1 '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))]),
          const SizedBox(height: 8),
          TextField(controller: notesCtl, decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: saving ? null : () async {
              final name = nameCtl.text.trim();
              final amount = double.tryParse(amountCtl.text.replaceAll(',', '')) ?? 0;
              final value = double.tryParse(valueCtl.text.replaceAll(',', '')) ?? 0;
              if (name.isEmpty || amount <= 0) return;
              setSt(() => saving = true);
              try {
                final repo = LocalInvestmentRepository(
                    AppDatabase.instance, Supabase.instance.client);
                final now = DateTime.now();
                await repo.createInvestment(Investment(
                  id: inv.id, userId: inv.userId,
                  name: name, type: inv.type,
                  amountInvested: amount, currentValue: value,
                  dateStarted: inv.dateStarted,
                  notes: notesCtl.text.trim().isEmpty ? null : notesCtl.text.trim(),
                  navpu: inv.navpu, units: inv.units,
                  interestRate: inv.interestRate, maturityDate: inv.maturityDate,
                  createdAt: inv.createdAt, updatedAt: now,
                ));
                onUpdate();
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                setSt(() => saving = false);
              }
            },
            child: saving
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      )),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Are you sure you want to delete "${investment.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = LocalInvestmentRepository(
                  AppDatabase.instance, Supabase.instance.client);
              await repo.deleteInvestment(investment.id);
              onUpdate();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inv = investment;
    final gain = inv.gainLoss;
    final isUp = gain >= 0;

    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.trendingUp, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(inv.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(inv.typeLabel, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
              ),
              const SizedBox(width: 6),
              Text('Invested: ${hide ? "\u2022\u2022\u2022\u2022" : formatCurrency(inv.amountInvested)}',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(hide ? '\u2022\u2022\u2022\u2022' : formatCurrency(inv.currentValue),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text('${isUp ? '+' : ''}${inv.gainLossPercent.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: isUp ? Colors.green : Colors.red)),
          ]),
        ]),
      ]),
    ),
    );
  }

  void _showActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(LucideIcons.pencil, color: cs.onSurface),
            title: const Text('Edit'),
            onTap: () { Navigator.pop(ctx); _showEditDialog(context); },
          ),
          ListTile(
            leading: Icon(LucideIcons.trash2, color: cs.error),
            title: Text('Delete', style: TextStyle(color: cs.error)),
            onTap: () { Navigator.pop(ctx); _confirmDelete(context); },
          ),
        ]),
      ),
    );
  }
}
