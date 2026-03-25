import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/math/retirement_math.dart';

class RetirementScreen extends StatefulWidget {
  const RetirementScreen({super.key});
  @override
  State<RetirementScreen> createState() => _RetirementScreenState();
}

class _RetirementScreenState extends State<RetirementScreen> {
  final _ageCtl = TextEditingController(text: '25');
  final _retireAgeCtl = TextEditingController(text: '60');
  final _salaryCtl = TextEditingController(text: '25000');
  final _savingsCtl = TextEditingController(text: '0');
  final _desiredCtl = TextEditingController(text: '30000');
  final _contribYearsCtl = TextEditingController(text: '3');

  int get _age => int.tryParse(_ageCtl.text) ?? 25;
  int get _retireAge => int.tryParse(_retireAgeCtl.text) ?? 60;
  double get _salary => double.tryParse(_salaryCtl.text.replaceAll(',', '')) ?? 0;
  double get _savings => double.tryParse(_savingsCtl.text.replaceAll(',', '')) ?? 0;
  double get _desired => double.tryParse(_desiredCtl.text.replaceAll(',', '')) ?? 0;
  int get _contribYears => int.tryParse(_contribYearsCtl.text) ?? 0;

  @override
  void dispose() {
    _ageCtl.dispose(); _retireAgeCtl.dispose(); _salaryCtl.dispose();
    _savingsCtl.dispose(); _desiredCtl.dispose(); _contribYearsCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final proj = projectRetirement(
      currentAge: _age, retirementAge: _retireAge, monthlySalary: _salary,
      currentSavings: _savings, desiredMonthlyIncome: _desired, contributionYears: _contribYears,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        // Header
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.toolAmber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.piggyBank, size: 20, color: AppColors.toolAmber),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Retirement Projection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('See if your SSS pension + savings will be enough — and what to do if they\'re not.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 16),

        // Your Details form
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _Field(label: 'Current Age', ctl: _ageCtl, onChanged: () => setState(() {}))),
            const SizedBox(width: 12),
            Expanded(child: _Field(label: 'Retirement Age', ctl: _retireAgeCtl, onChanged: () => setState(() {}))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Field(label: 'Monthly Salary', ctl: _salaryCtl, prefix: '₱', onChanged: () => setState(() {}))),
            const SizedBox(width: 12),
            Expanded(child: _Field(label: 'Current Savings', ctl: _savingsCtl, prefix: '₱', onChanged: () => setState(() {}))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Field(label: 'Desired Monthly Income', ctl: _desiredCtl, prefix: '₱', onChanged: () => setState(() {}))),
            const SizedBox(width: 12),
            Expanded(child: _Field(label: 'Years of SSS Contributions', ctl: _contribYearsCtl, onChanged: () => setState(() {}))),
          ]),
        ])),
        const SizedBox(height: 16),

        // Results
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Retirement Projection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _ResultStat(
              label: 'Estimated SSS Pension',
              value: formatCurrency(proj.sssPension.monthlyPension),
              sub: '/month',
              valueColor: AppColors.toolAmber,
            )),
            const SizedBox(width: 16),
            Expanded(child: _ResultStat(
              label: 'Monthly Gap',
              value: formatCurrency(proj.monthlyGap),
              sub: '/month',
              valueColor: AppColors.toolRed,
            )),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _ResultStat(
              label: 'Total Savings Needed',
              value: formatCurrency(proj.totalSavingsNeeded),
              sub: '(4% rule)',
            )),
            const SizedBox(width: 16),
            Expanded(child: _ResultStat(
              label: 'Years to Retirement',
              value: '${proj.yearsToRetirement}',
              sub: 'years',
            )),
          ]),
          const SizedBox(height: 16),

          // Call to action
          if (proj.requiredMonthlySavings > 0)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.06),
                border: Border.all(color: AppColors.info.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                RichText(text: TextSpan(
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                  children: [
                    const TextSpan(text: 'You need to save '),
                    TextSpan(text: formatCurrency(proj.requiredMonthlySavings),
                        style: const TextStyle(color: AppColors.income)),
                    const TextSpan(text: '/month'),
                  ],
                )),
                const SizedBox(height: 6),
                Text(
                  'Assuming 7% annual returns (similar to Pag-IBIG MP2). '
                  'Your SSS pension covers ${formatCurrency(proj.sssPension.monthlyPension)} of your desired '
                  '${formatCurrency(_desired)}/month. You still need ${formatCurrency(proj.savingsShortfall)} in savings.',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, height: 1.4),
                ),
              ]),
            ),
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

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctl;
  final String? prefix;
  final VoidCallback onChanged;
  const _Field({required this.label, required this.ctl, this.prefix, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    const SizedBox(height: 4),
    TextField(
      controller: ctl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(isDense: true, prefixText: prefix != null ? '$prefix ' : null),
    ),
  ]);
}

class _ResultStat extends StatelessWidget {
  final String label, value, sub;
  final Color? valueColor;
  const _ResultStat({required this.label, required this.value, required this.sub, this.valueColor});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
      Text(sub, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
    ]);
  }
}
