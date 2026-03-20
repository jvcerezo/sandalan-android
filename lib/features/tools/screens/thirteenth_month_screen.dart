import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/math/ph_math.dart';

class ThirteenthMonthScreen extends StatefulWidget {
  const ThirteenthMonthScreen({super.key});

  @override
  State<ThirteenthMonthScreen> createState() => _ThirteenthMonthScreenState();
}

class _ThirteenthMonthScreenState extends State<ThirteenthMonthScreen> {
  final _salaryController = TextEditingController(text: '25000');
  final _monthsController = TextEditingController(text: '12');

  double get _salary => double.tryParse(_salaryController.text.replaceAll(',', '')) ?? 0;
  int get _months => int.tryParse(_monthsController.text) ?? 12;

  @override
  void dispose() {
    _salaryController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final result = calculate13thMonth(_salary, monthsWorked: _months);
    final formula = '(${formatCurrency(_salary)} × $_months) ÷ 12 = ${formatCurrency(result.gross)}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        // ← Tools
        GestureDetector(
          onTap: () => context.go('/tools'),
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.arrowLeft, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Tools', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),

        // Header
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.toolGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.gift, size: 20, color: AppColors.toolGreen),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('13th Month Pay',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Estimate your 13th month and understand the ₱90,000 tax exemption.',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 16),

        // Calculator
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Calculator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          const Text('Basic Monthly Salary (₱)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: _salaryController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(isDense: true),
          ),
          const SizedBox(height: 14),

          const Text('Months Worked This Year', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: _monthsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(isDense: true),
          ),
          const SizedBox(height: 2),
          Text('1 to 12 months', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),

          // Results
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Gross 13th Month Pay', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
            Text(formatCurrency(result.gross), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),

          // Tax-exempt portion (highlighted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tax-Exempt Portion', style: TextStyle(fontSize: 13, color: AppColors.income, fontWeight: FontWeight.w500)),
                Text('Up to ₱90,000 per year', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
              ])),
              Text(formatCurrency(result.taxExemptPortion),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.income)),
            ]),
          ),
          const SizedBox(height: 12),

          // Formula
          Row(children: [
            Icon(LucideIcons.info, size: 12, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(child: Text('Formula: $formula',
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))),
          ]),
        ])),
        const SizedBox(height: 16),

        // Things You Should Know
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Things You Should Know', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          ...[
            'Presidential Decree 851 mandates 13th month pay for all rank-and-file employees.',
            'Must be paid on or before December 24 each year.',
            'Computed as: (Basic Salary × Months Worked) ÷ 12.',
            'Up to ₱90,000 is exempt from income tax (combined with other bonuses).',
            'Managerial employees are not covered — but many companies still grant it.',
          ].map((text) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.checkCircle2, size: 16, color: AppColors.income),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
            ]),
          )),
        ])),
        const SizedBox(height: 16),

        // What Should You Do With It?
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('What Should You Do With It?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          _AllocationRow(pct: '50%', title: 'Emergency Fund or Savings Goal',
              subtitle: 'Pad your emergency fund or accelerate a savings goal.', color: AppColors.income),
          _AllocationRow(pct: '20%', title: 'Debt Payments',
              subtitle: 'Pay down credit card or high-interest loan balances.', color: AppColors.toolOrange),
          _AllocationRow(pct: '20%', title: 'Investments',
              subtitle: 'Top up your SSS Pension Fund, Pag-IBIG MP2, or mutual fund.', color: AppColors.toolOrange),
          _AllocationRow(pct: '10%', title: 'Treat Yourself',
              subtitle: 'You earned it. Enjoy responsibly.', color: AppColors.toolPurple),
        ])),
      ],
    );
  }
}

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

class _AllocationRow extends StatelessWidget {
  final String pct, title, subtitle;
  final Color color;
  const _AllocationRow({required this.pct, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(pct, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        ])),
      ]),
    );
  }
}
