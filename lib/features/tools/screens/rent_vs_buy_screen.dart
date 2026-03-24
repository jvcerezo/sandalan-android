import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';

class RentVsBuyScreen extends StatefulWidget {
  const RentVsBuyScreen({super.key});
  @override
  State<RentVsBuyScreen> createState() => _RentVsBuyScreenState();
}

class _RentVsBuyScreenState extends State<RentVsBuyScreen> {
  final _priceCtl = TextEditingController(text: '2000000');
  final _downPctCtl = TextEditingController(text: '10');
  final _rentCtl = TextEditingController(text: '12000');
  final _rentIncCtl = TextEditingController(text: '5');
  final _assocCtl = TextEditingController(text: '3000');

  double get _price => double.tryParse(_priceCtl.text.replaceAll(',', '')) ?? 0;
  double get _downPct => (double.tryParse(_downPctCtl.text) ?? 10) / 100;
  double get _rent => double.tryParse(_rentCtl.text.replaceAll(',', '')) ?? 0;
  double get _rentInc => (double.tryParse(_rentIncCtl.text) ?? 5) / 100;
  double get _assoc => double.tryParse(_assocCtl.text.replaceAll(',', '')) ?? 0;

  static const _rate = 0.0575; // Pag-IBIG
  static const _term = 20;
  static const _appreciation = 0.03;
  static const _propertyTax = 0.01;

  @override
  void dispose() {
    _priceCtl.dispose(); _downPctCtl.dispose(); _rentCtl.dispose();
    _rentIncCtl.dispose(); _assocCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loanAmt = _price * (1 - _downPct);
    final monthlyRate = _rate / 12;
    final months = _term * 12;
    final amort = loanAmt * monthlyRate * math.pow(1 + monthlyRate, months) /
        (math.pow(1 + monthlyRate, months) - 1);
    final totalPaid = amort * months;
    final totalInterest = totalPaid - loanAmt;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.toolEmerald.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(LucideIcons.home, size: 20, color: AppColors.toolEmerald)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Rent vs Buy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Should you keep renting or buy a home with a Pag-IBIG loan? Compare the numbers.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 16),

        // Your Scenario
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your Scenario', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _F(label: 'Property Price', ctl: _priceCtl, prefix: '₱', onC: () => setState(() {}))),
            const SizedBox(width: 12),
            Expanded(child: _F(label: 'Down Payment %', ctl: _downPctCtl, suffix: '%', onC: () => setState(() {}))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _F(label: 'Monthly Rent', ctl: _rentCtl, prefix: '₱', onC: () => setState(() {}))),
            const SizedBox(width: 12),
            Expanded(child: _F(label: 'Annual Rent Increase', ctl: _rentIncCtl, suffix: '%', onC: () => setState(() {}))),
          ]),
          const SizedBox(height: 12),
          SizedBox(width: 160, child: _F(label: 'Monthly Assoc. Dues', ctl: _assocCtl, prefix: '₱', onC: () => setState(() {}))),
        ])),
        const SizedBox(height: 16),

        // Pag-IBIG Housing Loan
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pag-IBIG Housing Loan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _InfoRow('Loan Amount', formatCurrency(loanAmt)),
          _InfoRow('Interest Rate', '${(_rate * 100).toStringAsFixed(2)}% (Pag-IBIG)'),
          _InfoRow('Loan Term', '$_term years'),
          const Divider(height: 16),
          _InfoRow('Monthly Amortization', formatCurrency(amort), bold: true, valueColor: AppColors.income),
          const SizedBox(height: 4),
          Text('Total paid over $_term years: ${formatCurrency(totalPaid)} (interest: ${formatCurrency(totalInterest)})',
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        ])),
        const SizedBox(height: 16),

        // Rent vs Buy Over Time table
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Rent vs Buy Over Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: const [
                  _Th('Years'), _Th('Total Rent'), _Th('Total Buy Cost'), _Th('Property Value'),
                ]),
                const Divider(height: 8),
                ...[5, 10, 15, 20, 30].map((yr) {
                  final totalRent = _calcTotalRent(yr);
                  final totalBuy = _calcTotalBuy(yr, amort);
                  final propValue = _price * math.pow(1 + _appreciation, yr);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      _Td('$yr yr'),
                      _Td(_compactCurrency(totalRent)),
                      _Td(_compactCurrency(totalBuy)),
                      _Td(_compactCurrency(propValue), color: AppColors.income),
                    ]),
                  );
                }),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text('Assumes ${(_appreciation * 100).toInt()}% annual property appreciation and ${(_propertyTax * 100).toInt()}% annual property tax. Pag-IBIG rate at ${(_rate * 100).toStringAsFixed(2)}% for $_term-year term.',
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        ])),
      ],
    );
  }

  double _calcTotalRent(int years) {
    double total = 0;
    double monthly = _rent;
    for (int y = 0; y < years; y++) {
      total += monthly * 12;
      monthly *= (1 + _rentInc);
    }
    return total;
  }

  String _compactCurrency(double value) {
    final compact = NumberFormat.compactCurrency(locale: 'en_PH', symbol: '₱', decimalDigits: 1);
    return compact.format(value);
  }

  double _calcTotalBuy(int years, double amort) {
    final downPayment = _price * _downPct;
    final amortYears = years <= _term ? years : _term;
    final amortTotal = amort * amortYears * 12;
    final assocTotal = _assoc * years * 12;
    final taxTotal = _price * _propertyTax * years;
    return downPayment + amortTotal + assocTotal + taxTotal;
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext c) => Container(width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(c).colorScheme.surface,
      border: Border.all(color: Theme.of(c).colorScheme.surfaceContainerHighest),
      borderRadius: BorderRadius.circular(12)), child: child);
}

class _F extends StatelessWidget {
  final String label; final TextEditingController ctl; final String? prefix, suffix; final VoidCallback onC;
  const _F({required this.label, required this.ctl, this.prefix, this.suffix, required this.onC});
  @override
  Widget build(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    const SizedBox(height: 4),
    TextField(controller: ctl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))], onChanged: (_) => onC(),
      decoration: InputDecoration(isDense: true, prefixText: prefix != null ? '$prefix ' : null,
          suffixText: suffix)),
  ]);
}

class _InfoRow extends StatelessWidget {
  final String label, value; final bool bold; final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.bold = false, this.valueColor});
  @override
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, color: Theme.of(c).colorScheme.onSurfaceVariant)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: valueColor)),
    ]));
}

class _Th extends StatelessWidget {
  final String t; const _Th(this.t);
  @override
  Widget build(BuildContext c) => Expanded(child: Text(t,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3,
          color: Theme.of(c).colorScheme.onSurfaceVariant)));
}

class _Td extends StatelessWidget {
  final String t; final Color? color; const _Td(this.t, {this.color});
  @override
  Widget build(BuildContext c) => Expanded(child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(t,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color))));
}
