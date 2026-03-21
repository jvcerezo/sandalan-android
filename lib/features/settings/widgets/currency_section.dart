import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/currencies.dart';
import 'settings_shared.dart';

class CurrencySection extends StatelessWidget {
  final Widget back;
  const CurrencySection({super.key, required this.back});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      back,
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Currency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Set your primary currency and manage exchange rates',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        const Text('Primary Currency', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
            value: 'PHP',
            isDense: true,
            items: kCurrencies
                .map((c) =>
                    DropdownMenuItem(value: c.code, child: Text('${c.symbol} ${c.name} (${c.code})')))
                .toList(),
            onChanged: (v) {}),
        const SizedBox(height: 12),
        FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0)),
            child: const Text('Save')),
        const SizedBox(height: 4),
        Text('All amounts on the dashboard will be converted to this currency',
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        Row(children: [
          const Expanded(
              child: Text('Exchange Rates (to PHP)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(children: [
                Icon(LucideIcons.refreshCw, size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Refresh', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Set custom rates or leave blank to use live market rates',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        _RateRow(code: 'USD', rate: '60.1034'),
        _RateRow(code: 'AUD', rate: '42.3513'),
        const SizedBox(height: 6),
        Text('Market rates updated 18h ago',
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
      ])),
    ]);
  }
}

class _RateRow extends StatelessWidget {
  final String code, rate;
  const _RateRow({required this.code, required this.rate});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
            width: 40,
            child:
                Text(code, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        const Text('  =  ', style: TextStyle(fontSize: 13)),
        SizedBox(
            width: 100,
            child: TextField(
                decoration: InputDecoration(isDense: true, hintText: rate),
                keyboardType: const TextInputType.numberWithOptions(decimal: true))),
        const SizedBox(width: 8),
        const Text('PHP', style: TextStyle(fontSize: 13)),
      ]));
}
