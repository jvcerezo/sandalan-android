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
  final _amountController = TextEditingController();
  bool _rollover = false;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    try {
      final month = ref.read(budgetMonthProvider);
      final period = ref.read(budgetPeriodProvider);
      await ref.read(budgetRepositoryProvider).createBudget(
        category: _category,
        amount: amount,
        month: month,
        period: period,
        rollover: _rollover,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Add Budget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(LucideIcons.x, size: 20)),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _category,
          decoration: const InputDecoration(labelText: 'Category'),
          items: kExpenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _category = v ?? kExpenseCategories.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
          decoration: const InputDecoration(labelText: 'Budget Amount', prefixText: '₱ '),
          autofocus: true,
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: _rollover,
          onChanged: (v) => setState(() => _rollover = v),
          title: const Text('Rollover unspent', style: TextStyle(fontSize: 14)),
          subtitle: const Text('Carry unused budget to next period', style: TextStyle(fontSize: 12)),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _handleSave,
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _saving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create Budget'),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}
