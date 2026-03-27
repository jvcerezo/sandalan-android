import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/salary_allocation_service.dart';
import '../../../core/utils/formatters.dart';
import '../../budgets/providers/budget_providers.dart';
import '../../goals/providers/goal_providers.dart';
import '../../../shared/utils/snackbar_helper.dart';

class SalaryAllocationScreen extends ConsumerStatefulWidget {
  const SalaryAllocationScreen({super.key});

  @override
  ConsumerState<SalaryAllocationScreen> createState() => _State();
}

class _State extends ConsumerState<SalaryAllocationScreen> {
  final _salaryCtl = TextEditingController();
  late final TextEditingController _payDate1Ctl;
  late final TextEditingController _payDate2Ctl;
  String _frequency = 'twice_monthly';
  int _payDate1 = 15;
  int _payDate2 = 30;
  List<AllocationRule> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _payDate1Ctl = TextEditingController(text: '$_payDate1');
    _payDate2Ctl = TextEditingController(text: '$_payDate2');
    _load();
  }

  @override
  void dispose() {
    _salaryCtl.dispose();
    _payDate1Ctl.dispose();
    _payDate2Ctl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final config = await SalaryAllocationService.loadConfig();
    if (config != null) {
      _salaryCtl.text = config.salary.toStringAsFixed(0);
      _frequency = config.frequency;
      if (config.payDates.length >= 2) {
        _payDate1 = config.payDates[0];
        _payDate2 = config.payDates[1];
        _payDate1Ctl.text = '$_payDate1';
        _payDate2Ctl.text = '$_payDate2';
      }
      _rules = List.from(config.rules);
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final salary = double.tryParse(_salaryCtl.text.replaceAll(',', '')) ?? 0;
    if (salary <= 0) {
      showAppSnackBar(context, 'Please enter your salary', isError: true);
      return;
    }
    final totalAllocated = _rules.fold(0.0, (s, r) => s + r.amount);
    if (totalAllocated > salary) {
      showAppSnackBar(context, 'Total allocation exceeds salary amount', isError: true);
      return;
    }
    await SalaryAllocationService.saveConfig(SalaryAllocationConfig(
      salary: salary, frequency: _frequency,
      payDates: [_payDate1, _payDate2], rules: _rules,
    ));
    showSuccessSnackBar(context, 'Allocation rules saved!');
  }

  void _showRuleDialog({int? editIndex}) {
    final existing = editIndex != null ? _rules[editIndex] : null;
    final salary = double.tryParse(_salaryCtl.text.replaceAll(',', '')) ?? 0;
    final currentAllocated = _rules.fold(0.0, (s, r) => s + r.amount);
    final editingAmount = existing?.amount ?? 0;
    // Remaining = salary - (allocated minus the rule being edited)
    final remainingBefore = salary - (currentAllocated - editingAmount);

    showDialog(context: context, builder: (ctx) {
      String type = existing?.type ?? 'budget';
      String label = existing?.label ?? '';
      String amount = existing != null ? existing.amount.toStringAsFixed(0) : '';
      final labelCtl = TextEditingController(text: label);
      final amountCtl = TextEditingController(text: amount);
      String? errorText;

      // Load budgets and goals for the picker
      final budgets = ref.read(budgetsProvider).valueOrNull ?? [];
      final goals = ref.read(goalsProvider).valueOrNull ?? [];

      return StatefulBuilder(builder: (ctx, setSt) {
        final enteredAmount = double.tryParse(amountCtl.text.replaceAll(',', '')) ?? 0;
        final remaining = remainingBefore - enteredAmount;

        // Build picker items based on type
        List<String> pickerItems = [];
        if (type == 'budget') {
          pickerItems = budgets.map((b) => b.category).toSet().toList();
        } else if (type == 'goal') {
          pickerItems = goals.map((g) => g.name).toList();
        }

        return AlertDialog(
          title: Text(existing != null ? 'Edit Rule' : 'Add Rule', style: const TextStyle(fontSize: 16)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Wrap(spacing: 6, children: [
              for (final t in [('budget', 'Budget'), ('goal', 'Goal'), ('savings', 'Savings')])
                GestureDetector(
                  onTap: () => setSt(() {
                    type = t.$1;
                    labelCtl.clear();
                    label = '';
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: type == t.$1 ? Theme.of(ctx).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                      border: Border.all(color: type == t.$1 ? Theme.of(ctx).colorScheme.primary : Theme.of(ctx).colorScheme.outline.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(t.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                        color: type == t.$1 ? Theme.of(ctx).colorScheme.primary : Theme.of(ctx).colorScheme.onSurfaceVariant)),
                  ),
                ),
            ]),
            const SizedBox(height: 8),

            // Picker for budgets/goals, text field for savings
            if (type == 'savings')
              TextField(
                controller: labelCtl,
                decoration: const InputDecoration(labelText: 'Label'),
                onChanged: (v) => label = v,
                textCapitalization: TextCapitalization.words,
              )
            else if (pickerItems.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: pickerItems.contains(label) ? label : null,
                decoration: InputDecoration(labelText: type == 'budget' ? 'Budget Category' : 'Goal'),
                items: pickerItems.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => setSt(() {
                  label = v ?? '';
                  labelCtl.text = label;
                }),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(children: [
                  Text(
                    type == 'budget' ? 'No budgets yet' : 'No goals yet',
                    style: TextStyle(fontSize: 13, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create ${type == 'budget' ? 'budgets' : 'goals'} first, then come back to allocate.',
                    style: TextStyle(fontSize: 11, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: labelCtl,
                decoration: InputDecoration(labelText: type == 'budget' ? 'Category' : 'Goal Name'),
                onChanged: (v) => label = v,
                textCapitalization: TextCapitalization.words,
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: amountCtl,
              decoration: const InputDecoration(labelText: 'Amount (\u20B1)', prefixText: '\u20B1 ', counterText: ''),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              maxLength: 12, maxLengthEnforcement: MaxLengthEnforcement.enforced,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              onChanged: (v) {
                amount = v;
                setSt(() {
                  final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
                  if (parsed > remainingBefore) {
                    errorText = 'Exceeds remaining ${formatCurrency(remainingBefore)}';
                  } else {
                    errorText = null;
                  }
                });
              },
            ),
            if (salary > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Remaining: ${formatCurrency(remaining > 0 ? remaining : 0)} of ${formatCurrency(salary)}',
                  style: TextStyle(fontSize: 12, color: remaining < 0 ? Colors.red : Theme.of(ctx).colorScheme.onSurfaceVariant),
                ),
              ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(errorText!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () {
              final parsedAmount = double.tryParse(amountCtl.text.replaceAll(',', '')) ?? 0;
              if (label.isEmpty || parsedAmount <= 0) return;
              if (parsedAmount > remainingBefore) {
                setSt(() => errorText = 'Exceeds remaining ${formatCurrency(remainingBefore)}');
                return;
              }
              final rule = AllocationRule(
                type: type, label: label,
                amount: parsedAmount,
                categoryOrGoal: label,
              );
              setState(() {
                if (editIndex != null) {
                  _rules[editIndex] = rule;
                } else {
                  _rules.add(rule);
                }
              });
              Navigator.pop(ctx);
            }, child: Text(existing != null ? 'Save' : 'Add')),
          ],
        );
      });
    });
  }

  void _addRule() => _showRuleDialog();

  void _editRule(int index) => _showRuleDialog(editIndex: index);

  void _deleteRule(int index) {
    final rule = _rules[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Rule?'),
        content: Text('Remove "${rule.label}" (${formatCurrency(rule.amount)}) from your allocation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _rules.removeAt(index));
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
    final salary = double.tryParse(_salaryCtl.text.replaceAll(',', '')) ?? 0;
    final totalAllocated = _rules.fold(0.0, (s, r) => s + r.amount);
    final free = salary - totalAllocated;
    final pct = salary > 0 ? (totalAllocated / salary * 100) : 0.0;
    final overAllocated = totalAllocated > salary && salary > 0;

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
          Row(children: [
            Icon(LucideIcons.wallet, size: 24, color: cs.primary),
            const SizedBox(width: 8),
            const Text('Payday Splitter', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          Text('Tell us your salary and where to put it — we\'ll remind you to split it every payday.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),

          // How it works
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, size: 14, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Example: ₱30,000 salary → ₱10,000 to rent budget, ₱5,000 to emergency fund goal, ₱15,000 free spending.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              )),
            ]),
          ),

          // Salary input
          TextField(
            controller: _salaryCtl,
            decoration: const InputDecoration(labelText: 'Monthly Salary (\u20B1)', prefixText: '\u20B1 ', counterText: ''),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            maxLength: 12,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Frequency
          Text('Pay Frequency', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final f in [('monthly', 'Monthly'), ('twice_monthly', 'Twice a Month'), ('biweekly', 'Biweekly'), ('weekly', 'Weekly')])
              GestureDetector(
                onTap: () => setState(() => _frequency = f.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _frequency == f.$1 ? cs.primary.withOpacity(0.1) : Colors.transparent,
                    border: Border.all(color: _frequency == f.$1 ? cs.primary : cs.outline.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(f.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: _frequency == f.$1 ? cs.primary : cs.onSurfaceVariant)),
                ),
              ),
          ]),
          if (_frequency == 'twice_monthly') ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(
                decoration: const InputDecoration(labelText: '1st payday'),
                keyboardType: TextInputType.number,
                controller: _payDate1Ctl,
                onChanged: (v) => _payDate1 = int.tryParse(v) ?? 15,
              )),
              const SizedBox(width: 8),
              Expanded(child: TextField(
                decoration: const InputDecoration(labelText: '2nd payday'),
                keyboardType: TextInputType.number,
                controller: _payDate2Ctl,
                onChanged: (v) => _payDate2 = int.tryParse(v) ?? 30,
              )),
            ]),
          ],
          const SizedBox(height: 20),

          // Remaining amount indicator
          if (salary > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: overAllocated ? cs.error.withOpacity(0.08) : cs.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: overAllocated ? cs.error.withOpacity(0.3) : cs.primary.withOpacity(0.2)),
              ),
              child: Row(children: [
                Icon(overAllocated ? LucideIcons.alertCircle : LucideIcons.info,
                    size: 14, color: overAllocated ? cs.error : cs.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  overAllocated
                      ? 'Over-allocated by ${formatCurrency(totalAllocated - salary)}'
                      : 'Remaining: ${formatCurrency(free > 0 ? free : 0)} of ${formatCurrency(salary)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: overAllocated ? cs.error : cs.primary),
                )),
              ]),
            ),
          ],

          // Rules
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('ALLOCATION RULES', style: TextStyle(
                fontSize: 11, letterSpacing: 0.5, color: cs.onSurfaceVariant)),
            GestureDetector(onTap: _addRule, child: Text('+ Add Rule',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary))),
          ]),
          const SizedBox(height: 8),

          if (_rules.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withOpacity(0.15)),
              ),
              child: Column(children: [
                Icon(LucideIcons.layers, size: 28, color: cs.onSurfaceVariant.withOpacity(0.4)),
                const SizedBox(height: 8),
                Text('No rules yet', style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('Add rules to auto-split your salary into budgets, goals, and savings',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withOpacity(0.7)),
                    textAlign: TextAlign.center),
              ]),
            ),

          ..._rules.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final rulePct = salary > 0 ? (r.amount / salary * 100) : 0.0;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outline.withOpacity(0.15)),
              ),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    r.type == 'goal' ? LucideIcons.target
                        : r.type == 'savings' ? LucideIcons.piggyBank
                        : LucideIcons.pieChart,
                    size: 16, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(r.type[0].toUpperCase() + r.type.substring(1),
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(formatCurrency(r.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('${rulePct.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ]),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _editRule(i),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(LucideIcons.pencil, size: 14, color: cs.onSurfaceVariant),
                  ),
                ),
                GestureDetector(
                  onTap: () => _deleteRule(i),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(LucideIcons.trash2, size: 14, color: cs.error.withOpacity(0.6)),
                  ),
                ),
              ]),
            );
          }),

          const SizedBox(height: 16),

          // Summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: overAllocated ? cs.error.withOpacity(0.05) : cs.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: overAllocated ? cs.error.withOpacity(0.2) : cs.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Allocated', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                Text('${formatCurrency(totalAllocated)} (${pct.toStringAsFixed(0)}%)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: overAllocated ? cs.error : cs.primary)),
              ])),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Free Money', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                Text(formatCurrency(free > 0 ? free : 0),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: free > 0 ? Colors.green : cs.error)),
              ])),
            ]),
          ),
          if (overAllocated) ...[
            const SizedBox(height: 8),
            Text('Total allocation exceeds your salary. Please adjust rules before saving.',
                style: TextStyle(fontSize: 12, color: cs.error)),
          ],
          const SizedBox(height: 16),

          FilledButton(
            onPressed: overAllocated ? null : _save,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Save Allocation Rules'),
          ),
        ]),
      ),
    );
  }
}
