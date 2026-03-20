import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/categories.dart';
import '../providers/budget_providers.dart';

class AddBudgetDialog extends ConsumerStatefulWidget {
  const AddBudgetDialog({super.key});
  @override
  ConsumerState<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends ConsumerState<AddBudgetDialog> {
  String _category = kExpenseCategories.first;
  final _amountCtl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _amountCtl.dispose(); super.dispose(); }

  IconData _icon(String c) {
    switch (c) {
      case 'Food': return LucideIcons.utensils;
      case 'Housing': return LucideIcons.home;
      case 'Transportation': return LucideIcons.car;
      case 'Entertainment': return LucideIcons.film;
      case 'Healthcare': return LucideIcons.heart;
      case 'Education': return LucideIcons.graduationCap;
      case 'Family Support': return LucideIcons.moreHorizontal;
      default: return LucideIcons.moreHorizontal;
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    try {
      final month = ref.read(budgetMonthProvider);
      final period = ref.read(budgetPeriodProvider);
      await ref.read(budgetRepositoryProvider).createBudget(
          category: _category, amount: amount, month: month, period: period);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) { setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.65, maxChildSize: 0.85, minChildSize: 0.4, expand: false,
      builder: (context, ctl) => Container(
        decoration: BoxDecoration(color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: ListView(controller: ctl, padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), children: [
          Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: cs.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
          const Center(child: Text('Add Budget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 4),
          Center(child: Text('Set a spending limit for a category. Monthly is the default.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant), textAlign: TextAlign.center)),
          const SizedBox(height: 4),
          Center(child: Text('Use weekly/quarterly instead',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))),
          const SizedBox(height: 16),

          // Category
          const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: kExpenseCategories.map((c) {
            final selected = _category == c;
            return GestureDetector(
              onTap: () => setState(() => _category = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
                  border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_icon(c), size: 12, color: selected ? cs.primary : cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(c, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: selected ? cs.primary : cs.onSurfaceVariant)),
                ]),
              ),
            );
          }).toList()),
          const SizedBox(height: 16),

          // Monthly Limit
          const Text('Monthly Limit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('₱', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant)),
            const SizedBox(width: 4),
            Expanded(child: TextField(
              controller: _amountCtl, autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant),
              decoration: InputDecoration(hintText: '0.00',
                  hintStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                  border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero),
            )),
          ]),
          const SizedBox(height: 16),

          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Add Budget'),
          ),
        ]),
      ),
    );
  }
}
