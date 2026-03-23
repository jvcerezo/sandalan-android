import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/salary_allocation_service.dart';
import '../../../core/utils/formatters.dart';

class SalaryAllocationScreen extends StatefulWidget {
  const SalaryAllocationScreen({super.key});

  @override
  State<SalaryAllocationScreen> createState() => _State();
}

class _State extends State<SalaryAllocationScreen> {
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your salary')));
      return;
    }
    await SalaryAllocationService.saveConfig(SalaryAllocationConfig(
      salary: salary, frequency: _frequency,
      payDates: [_payDate1, _payDate2], rules: _rules,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Allocation rules saved!')));
    }
  }

  void _addRule() {
    showDialog(context: context, builder: (ctx) {
      String type = 'budget';
      String label = '';
      String amount = '';
      return StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
        title: const Text('Add Rule', style: TextStyle(fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Wrap(spacing: 6, children: [
            for (final t in [('budget', 'Budget'), ('goal', 'Goal'), ('savings', 'Savings')])
              GestureDetector(
                onTap: () => setSt(() => type = t.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: type == t.$1 ? Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                    border: Border.all(color: type == t.$1 ? Theme.of(ctx).colorScheme.primary : Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(t.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: type == t.$1 ? Theme.of(ctx).colorScheme.primary : Theme.of(ctx).colorScheme.onSurfaceVariant)),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          TextField(decoration: InputDecoration(labelText: type == 'budget' ? 'Category' : 'Goal Name'),
              onChanged: (v) => label = v, textCapitalization: TextCapitalization.words),
          const SizedBox(height: 8),
          TextField(decoration: const InputDecoration(labelText: 'Amount (₱)', prefixText: '₱ ', counterText: ''),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              maxLength: 12, maxLengthEnforcement: MaxLengthEnforcement.enforced,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              onChanged: (v) => amount = v),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            if (label.isNotEmpty && amount.isNotEmpty) {
              setState(() => _rules.add(AllocationRule(
                type: type, label: label,
                amount: double.tryParse(amount.replaceAll(',', '')) ?? 0,
                categoryOrGoal: label,
              )));
              Navigator.pop(ctx);
            }
          }, child: const Text('Add')),
        ],
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final salary = double.tryParse(_salaryCtl.text.replaceAll(',', '')) ?? 0;
    final totalAllocated = _rules.fold(0.0, (s, r) => s + r.amount);
    final free = salary - totalAllocated;
    final pct = salary > 0 ? (totalAllocated / salary * 100) : 0.0;

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/dashboard'),
            child: Row(children: [
              Icon(LucideIcons.arrowLeft, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Dashboard', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Icon(LucideIcons.wallet, size: 24, color: cs.primary),
            const SizedBox(width: 8),
            const Text('Salary Allocation', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          Text('Auto-split your salary on payday',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),

          // Salary input
          TextField(
            controller: _salaryCtl,
            decoration: const InputDecoration(labelText: 'Monthly Salary (₱)', prefixText: '₱ ', counterText: ''),
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
                    color: _frequency == f.$1 ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
                    border: Border.all(color: _frequency == f.$1 ? cs.primary : cs.outline.withValues(alpha: 0.15)),
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
                border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
              ),
              child: Column(children: [
                Icon(LucideIcons.layers, size: 28, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                Text('No rules yet', style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('Add rules to auto-split your salary into budgets, goals, and savings',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center),
              ]),
            ),

          ..._rules.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final rulePct = salary > 0 ? (r.amount / salary * 100) : 0.0;
            return Dismissible(
              key: ValueKey('rule_$i'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => setState(() => _rules.removeAt(i)),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: cs.error.withValues(alpha: 0.1),
                child: Icon(LucideIcons.trash2, color: cs.error),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                ),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
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
                ]),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Allocated', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                Text('${formatCurrency(totalAllocated)} (${pct.toStringAsFixed(0)}%)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary)),
              ])),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Free Money', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                Text(formatCurrency(free > 0 ? free : 0),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: free > 0 ? Colors.green : cs.error)),
              ])),
            ]),
          ),
          const SizedBox(height: 16),

          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Save Allocation Rules'),
          ),
        ]),
      ),
    );
  }
}
