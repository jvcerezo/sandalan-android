import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';

class CalculatorsScreen extends StatefulWidget {
  const CalculatorsScreen({super.key});
  @override
  State<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> {
  int _tab = 0;
  static const _tabs = ['Loan Amortization', 'Compound Interest', 'FIRE Calculator'];

  // Loan
  final _loanAmtCtl = TextEditingController(text: '500000');
  final _loanRateCtl = TextEditingController(text: '6');
  final _loanTermCtl = TextEditingController(text: '5');

  // Compound
  final _compInitCtl = TextEditingController(text: '10000');
  final _compMonthlyCtl = TextEditingController(text: '3000');
  final _compRateCtl = TextEditingController(text: '8');
  final _compYearsCtl = TextEditingController(text: '10');

  // FIRE
  final _fireExpCtl = TextEditingController(text: '50000');
  final _fireSavCtl = TextEditingController(text: '0');
  final _fireContribCtl = TextEditingController(text: '15000');
  final _fireReturnCtl = TextEditingController(text: '8');
  final _fireSWRCtl = TextEditingController(text: '4');

  @override
  void dispose() {
    _loanAmtCtl.dispose(); _loanRateCtl.dispose(); _loanTermCtl.dispose();
    _compInitCtl.dispose(); _compMonthlyCtl.dispose(); _compRateCtl.dispose(); _compYearsCtl.dispose();
    _fireExpCtl.dispose(); _fireSavCtl.dispose(); _fireContribCtl.dispose(); _fireReturnCtl.dispose(); _fireSWRCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
            decoration: BoxDecoration(color: AppColors.toolPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(LucideIcons.calculator, size: 20, color: AppColors.toolPurple)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Financial Calculators', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Loans · Compound interest · FIRE number',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 14),

        // Tabs
        Wrap(spacing: 6, runSpacing: 6, children: List.generate(3, (i) => GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _tab = i); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _tab == i ? cs.primary : Colors.transparent,
              border: Border.all(color: _tab == i ? cs.primary : cs.outline.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(_tabs[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: _tab == i ? cs.onPrimary : cs.onSurfaceVariant)),
          ),
        ))),
        const SizedBox(height: 16),

        if (_tab == 0) _buildLoan(cs),
        if (_tab == 1) _buildCompound(cs),
        if (_tab == 2) _buildFire(cs),

        const SizedBox(height: 16),
        // PH Investment Benchmarks
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('PH Investment Benchmarks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...[
            'PSE equity index funds: ~8–12% historical annual returns',
            'Pag-IBIG MP2: 6–7% annual dividend (tax-free)',
            'Retail Treasury Bonds (RTBs): 6–7% fixed coupon',
            'Bank time deposits: 4–6% per annum',
            'UITF money market: 3–5%',
          ].map((t) => Padding(padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('•  ', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              Expanded(child: Text(t, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))),
            ]))),
        ])),
      ],
    );
  }

  // ─── Loan Amortization ─────────────────────────────────────────────
  Widget _buildLoan(ColorScheme cs) {
    final amt = double.tryParse(_loanAmtCtl.text.replaceAll(',', '')) ?? 0;
    final rate = (double.tryParse(_loanRateCtl.text) ?? 0) / 100 / 12;
    final months = (int.tryParse(_loanTermCtl.text) ?? 1) * 12;
    final payment = rate > 0 ? amt * rate * math.pow(1 + rate, months) / (math.pow(1 + rate, months) - 1) : amt / months;
    final totalPaid = payment * months;
    final totalInterest = totalPaid - amt;
    final principalPct = amt > 0 ? (amt / totalPaid * 100).round() : 0;

    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Loan Amortization', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      Text('Monthly payment and total interest on any loan',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      const SizedBox(height: 14),
      _Fld('Loan Amount (₱)', _loanAmtCtl, () => setState(() {})),
      const SizedBox(height: 10),
      _Fld('Annual Interest Rate (%)', _loanRateCtl, () => setState(() {})),
      const SizedBox(height: 10),
      _Fld('Loan Term (years)', _loanTermCtl, () => setState(() {})),
      const SizedBox(height: 16),
      Row(children: [
        _ResultVal('Monthly Payment', formatCurrency(payment), AppColors.income),
        const SizedBox(width: 8),
        _ResultVal('Total Interest', formatCurrency(totalInterest), AppColors.expense),
        const SizedBox(width: 8),
        _ResultVal('Total Paid', formatCurrency(totalPaid), null),
      ]),
      const SizedBox(height: 10),
      // Bar
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Principal ($principalPct%)', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        Text('Interest (${100 - principalPct}%)', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: SizedBox(height: 8, child: Row(children: [
        Expanded(flex: principalPct.clamp(1, 99), child: Container(color: AppColors.income)),
        Expanded(flex: (100 - principalPct).clamp(1, 99), child: Container(color: AppColors.expense)),
      ]))),
    ]));
  }

  // ─── Compound Interest ─────────────────────────────────────────────
  Widget _buildCompound(ColorScheme cs) {
    final init = double.tryParse(_compInitCtl.text.replaceAll(',', '')) ?? 0;
    final monthly = double.tryParse(_compMonthlyCtl.text.replaceAll(',', '')) ?? 0;
    final rate = (double.tryParse(_compRateCtl.text) ?? 0) / 100 / 12;
    final years = int.tryParse(_compYearsCtl.text) ?? 1;
    final months = years * 12;

    final futureValue = init * math.pow(1 + rate, months) +
        monthly * (math.pow(1 + rate, months) - 1) / (rate > 0 ? rate : 1);
    final totalInvested = init + monthly * months;
    final interestEarned = futureValue - totalInvested;
    final multiplier = totalInvested > 0 ? (futureValue / totalInvested) : 0.0;
    final investedPct = futureValue > 0 ? (totalInvested / futureValue * 100).round() : 0;

    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Compound Interest', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      Text('Grow your money with regular contributions',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      const SizedBox(height: 14),
      _Fld('Initial Amount (₱)', _compInitCtl, () => setState(() {})),
      const SizedBox(height: 10),
      _Fld('Monthly Contribution (₱)', _compMonthlyCtl, () => setState(() {})),
      const SizedBox(height: 10),
      _Fld('Annual Return (%)', _compRateCtl, () => setState(() {})),
      const SizedBox(height: 10),
      _Fld('Years', _compYearsCtl, () => setState(() {})),
      const SizedBox(height: 16),
      Row(children: [
        _ResultVal('Future Value', formatCurrency(futureValue), AppColors.income, sub: '${multiplier.toStringAsFixed(1)}× your money'),
        const SizedBox(width: 6),
        _ResultVal('Total Invested', formatCurrency(totalInvested), null),
        const SizedBox(width: 6),
        _ResultVal('Interest Earned', formatCurrency(interestEarned), AppColors.income),
      ]),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Invested ($investedPct%)', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        Text('Interest (${100 - investedPct}%)', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: SizedBox(height: 8, child: Row(children: [
        Expanded(flex: investedPct.clamp(1, 99), child: Container(color: AppColors.income)),
        Expanded(flex: (100 - investedPct).clamp(1, 99), child: Container(color: AppColors.income.withValues(alpha: 0.3))),
      ]))),
    ]));
  }

  // ─── FIRE Calculator ───────────────────────────────────────────────
  Widget _buildFire(ColorScheme cs) {
    final expenses = double.tryParse(_fireExpCtl.text.replaceAll(',', '')) ?? 0;
    final savings = double.tryParse(_fireSavCtl.text.replaceAll(',', '')) ?? 0;
    final contrib = double.tryParse(_fireContribCtl.text.replaceAll(',', '')) ?? 0;
    final returnRate = (double.tryParse(_fireReturnCtl.text) ?? 0) / 100;
    final swr = (double.tryParse(_fireSWRCtl.text) ?? 4) / 100;

    final fireNumber = swr > 0 ? (expenses * 12 / swr) : 0.0;

    // Years to FIRE
    int yearsToFire = 0;
    int monthsToFire = 0;
    if (fireNumber > savings && contrib > 0 && returnRate > 0) {
      double balance = savings;
      final monthlyReturn = returnRate / 12;
      int totalMonths = 0;
      while (balance < fireNumber && totalMonths < 600) {
        balance = balance * (1 + monthlyReturn) + contrib;
        totalMonths++;
      }
      yearsToFire = totalMonths ~/ 12;
      monthsToFire = totalMonths % 12;
    }

    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('FIRE Calculator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      Text('How long until you can retire early?',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      const SizedBox(height: 14),
      _Fld('Monthly Expenses (₱)', _fireExpCtl, () => setState(() {})),
      const SizedBox(height: 10),
      _Fld('Current Savings / Investments (₱)', _fireSavCtl, () => setState(() {})),
      const SizedBox(height: 10),
      _Fld('Monthly Investment Contribution (₱)', _fireContribCtl, () => setState(() {})),
      const SizedBox(height: 10),
      _Fld('Expected Annual Return (%)', _fireReturnCtl, () => setState(() {})),
      const SizedBox(height: 10),
      _Fld('Safe Withdrawal Rate (%)', _fireSWRCtl, () => setState(() {}), hint: '4% is the common rule'),
      const SizedBox(height: 16),
      Row(children: [
        _ResultVal('FIRE Number', formatCurrency(fireNumber), AppColors.income, sub: 'Annual / ${(swr * 100).toStringAsFixed(0)}% SWR'),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Years to FIRE', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text('$yearsToFire years $monthsToFire months',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ])),
      ]),
    ]));
  }
}

// ─── Shared ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child; const _Card({required this.child});
  @override
  Widget build(BuildContext c) => Container(width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(c).colorScheme.surface,
      border: Border.all(color: Theme.of(c).colorScheme.outline.withValues(alpha: 0.12)),
      borderRadius: BorderRadius.circular(14)), child: child);
}

class _Fld extends StatelessWidget {
  final String label; final TextEditingController ctl; final VoidCallback onC; final String? hint;
  const _Fld(this.label, this.ctl, this.onC, {this.hint});
  @override
  Widget build(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    const SizedBox(height: 4),
    TextField(controller: ctl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))], onChanged: (_) => onC(),
      decoration: InputDecoration(isDense: true)),
    if (hint != null) Text(hint!, style: TextStyle(fontSize: 10, color: Theme.of(c).colorScheme.onSurfaceVariant)),
  ]);
}

class _ResultVal extends StatelessWidget {
  final String label, value; final Color? color; final String? sub;
  const _ResultVal(this.label, this.value, this.color, {this.sub});
  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color != null ? color!.withValues(alpha: 0.06) : cs.surface,
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        if (sub != null) Text(sub!, style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
      ])));
  }
}
