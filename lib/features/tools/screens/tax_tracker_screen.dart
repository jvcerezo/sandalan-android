import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/constants/ph_rates.dart';
import '../../../core/math/ph_math.dart';
import '../providers/tool_providers.dart';

class TaxTrackerScreen extends ConsumerStatefulWidget {
  const TaxTrackerScreen({super.key});

  @override
  ConsumerState<TaxTrackerScreen> createState() => _TaxTrackerScreenState();
}

class _TaxTrackerScreenState extends ConsumerState<TaxTrackerScreen> {
  final _salaryController = TextEditingController(text: '25000');
  final _otherIncomeController = TextEditingController(text: '0');
  final _bonusController = TextEditingController(text: '25000');
  String _taxpayerType = 'employed';
  int _taxYear = DateTime.now().year;

  double get _monthlySalary => double.tryParse(_salaryController.text.replaceAll(',', '')) ?? 0;
  double get _otherAnnual => double.tryParse(_otherIncomeController.text.replaceAll(',', '')) ?? 0;
  double get _bonus => double.tryParse(_bonusController.text.replaceAll(',', '')) ?? 0;

  @override
  void dispose() {
    _salaryController.dispose();
    _otherIncomeController.dispose();
    _bonusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final taxRecords = ref.watch(taxRecordsProvider);

    final grossAnnual = (_monthlySalary * 12) + _otherAnnual;
    final nonTaxable = _bonus.clamp(0.0, 90000.0);
    final tax = computeIncomeTax(grossAnnual, nonTaxableBenefits: nonTaxable);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        // Header
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.toolOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.receipt, size: 20, color: AppColors.toolOrange),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('BIR Tax Tracker',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('TRAIN Law income tax — graduated rates & 8% flat option',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 14),

        // Tax bracket pills
        Wrap(spacing: 6, runSpacing: 6, children: [
          _BracketPill('0% up to ₱250,000'),
          _BracketPill('15% on next ₱150k'),
          _BracketPill('20% on next ₱400k'),
          _BracketPill('25% on next ₱1.2M'),
          _BracketPill('30% on next ₱6M'),
          _BracketPill('35% above ₱8M'),
        ]),
        const SizedBox(height: 16),

        // Income Details form
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Income Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          _FormField(label: 'Monthly Basic Salary (₱)', controller: _salaryController,
              onChanged: () => setState(() {})),
          const SizedBox(height: 12),
          _FormField(label: 'Other Annual Income (₱)', controller: _otherIncomeController,
              onChanged: () => setState(() {})),
          const SizedBox(height: 12),
          _FormField(label: '13th Month + Bonuses (₱)', controller: _bonusController,
              onChanged: () => setState(() {}), hint: 'Exempt up to ₱90,000'),
          const SizedBox(height: 12),
          const Text('Taxpayer Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _taxpayerType,
            isDense: true,
            items: const [
              DropdownMenuItem(value: 'employed', child: Text('Employed')),
              DropdownMenuItem(value: 'self_employed', child: Text('Self-Employed')),
              DropdownMenuItem(value: 'mixed', child: Text('Mixed Income')),
            ],
            onChanged: (v) => setState(() => _taxpayerType = v ?? 'employed'),
          ),
        ])),
        const SizedBox(height: 12),

        // Results cards
        _ResultCard(label: 'Gross Annual Income', value: formatCurrency(grossAnnual),
            subtitle: 'Before deductions'),
        const SizedBox(height: 8),
        _ResultCard(label: 'Non-Taxable Benefits', value: formatCurrency(nonTaxable),
            subtitle: '13th month ≤ ₱90k'),
        const SizedBox(height: 8),
        _ResultCard(label: 'Taxable Income', value: formatCurrency(tax.taxableIncome),
            subtitle: 'After exemptions'),
        const SizedBox(height: 8),
        _ResultCard(label: 'Annual Tax Due', value: formatCurrency(tax.taxDue),
            subtitle: 'Effective rate: ${tax.effectiveRate.toStringAsFixed(2)}%',
            highlight: true, valueColor: AppColors.toolOrange),
        const SizedBox(height: 16),

        // Quarterly Filing Estimates
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Quarterly Filing Estimates',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('TRAIN Law 2023+', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 14),
          ...kBirDeadlines.map((d) => _QuarterRow(
            label: d.label,
            form: d.form,
            deadline: d.due,
            amount: d.label == 'Annual' ? tax.taxDue : tax.quarterlyEstimate,
          )),
          const SizedBox(height: 8),
          Row(children: [
            Icon(LucideIcons.info, size: 12, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(child: Text(
              'Quarterly estimates are approximate (annual ÷ 4). Actual amounts depend on actual income per quarter.',
              style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
            )),
          ]),
        ])),
        const SizedBox(height: 16),

        // TRAIN Law Tax Brackets
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TRAIN Law Tax Brackets',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...kTrainTaxBrackets.map((bracket) {
            final isYourBracket = tax.taxableIncome > bracket.min &&
                (bracket.max == double.infinity || tax.taxableIncome <= bracket.max);
            final maxLabel = bracket.max == double.infinity
                ? 'Over ${formatCurrency(bracket.min + 1)}'
                : '${formatCurrency(bracket.min)} – ${formatCurrency(bracket.max)}';

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isYourBracket ? colorScheme.primary.withOpacity(0.06) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Expanded(child: Row(children: [
                  Flexible(child: Text(maxLabel, style: const TextStyle(fontSize: 12))),
                  if (isYourBracket) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Your bracket',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: colorScheme.onPrimary)),
                    ),
                  ],
                ])),
                Text('${(bracket.rate * 100).toInt()}%',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: isYourBracket ? colorScheme.primary : null)),
              ]),
            );
          }),
        ])),
        const SizedBox(height: 16),

        // Tax Year + Save
        Row(children: [
          SizedBox(
            width: 80,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tax Year', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Select Tax Year'),
                      content: SizedBox(
                        width: 200, height: 200,
                        child: YearPicker(
                          firstDate: DateTime(2020),
                          lastDate: DateTime(DateTime.now().year + 1),
                          selectedDate: DateTime(_taxYear),
                          onChanged: (date) {
                            setState(() => _taxYear = date.year);
                            Navigator.pop(ctx);
                          },
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('$_taxYear', style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.chevronDown, size: 12, color: colorScheme.onSurfaceVariant),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: FilledButton.icon(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await ref.read(taxRepositoryProvider).createTaxRecord({
                    'year': _taxYear,
                    'gross_income': grossAnnual,
                    'deductions': nonTaxable,
                    'taxable_income': tax.taxableIncome,
                    'tax_due': tax.taxDue,
                    'amount_paid': 0,
                    'filing_type': 'annual',
                    'taxpayer_type': _taxpayerType,
                    'status': 'draft',
                  });
                  ref.invalidate(taxRecordsProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tax record saved as draft')),
                    );
                  }
                },
                icon: const Icon(LucideIcons.save, size: 16),
                label: const Text('Save as Draft'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // Tax records
        _Card(child: taxRecords.when(
          data: (records) {
            final yearRecords = records.where((r) => r.year == _taxYear).toList();
            if (yearRecords.isEmpty) {
              return Center(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(children: [
                  Text('No tax records for $_taxYear yet.',
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('Use the calculator above and click "Save as Draft" to start tracking.',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center),
                ]),
              ));
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tax Records $_taxYear', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...yearRecords.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.filingType == 'quarterly' ? 'Q${r.quarter}' : 'Annual',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(r.status, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  ]),
                  Text(formatCurrency(r.taxDue),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              )),
            ]);
          },
          loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
        )),
      ],
    );
  }
}

// ─── Widgets ───────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _BracketPill extends StatelessWidget {
  final String text;
  const _BracketPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? hint;
  const _FormField({required this.label, required this.controller, required this.onChanged, this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(isDense: true),
      ),
      if (hint != null) ...[
        const SizedBox(height: 2),
        Text(hint!, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    ]);
  }
}

class _ResultCard extends StatelessWidget {
  final String label, value, subtitle;
  final bool highlight;
  final Color? valueColor;
  const _ResultCard({required this.label, required this.value, required this.subtitle,
      this.highlight = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? AppColors.toolOrange.withOpacity(0.06) : colorScheme.surface,
        border: Border.all(color: colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor)),
        Text(subtitle, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

class _QuarterRow extends StatelessWidget {
  final String label, form, deadline;
  final double amount;
  const _QuarterRow({required this.label, required this.form, required this.deadline, required this.amount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.08))),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text('$form · Due $deadline',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
        ])),
        Text(formatCurrency(amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
