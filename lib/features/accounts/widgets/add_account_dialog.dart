import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/account_types.dart';
import '../../../core/constants/currencies.dart';
import '../providers/account_providers.dart';

class AddAccountDialog extends ConsumerStatefulWidget {
  const AddAccountDialog({super.key});
  @override
  ConsumerState<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<AddAccountDialog> {
  final _nameCtl = TextEditingController();
  final _balanceCtl = TextEditingController();
  String _type = 'cash';
  String _currency = 'PHP';
  bool _saving = false;

  @override
  void dispose() { _nameCtl.dispose(); _balanceCtl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final balance = double.tryParse(_balanceCtl.text.replaceAll(',', '')) ?? 0;
      await ref.read(accountRepositoryProvider).createAccount(
          name: name, type: _type, currency: _currency, balance: balance);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) { setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.4, expand: false,
      builder: (context, ctl) => Container(
        decoration: BoxDecoration(color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: ListView(controller: ctl, padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), children: [
          Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: cs.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
          const Center(child: Text('Add Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),

          // Quick Add
          Text('Quick Add', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: kCommonAccounts.map((p) => GestureDetector(
            onTap: () => setState(() { _nameCtl.text = p.name; _type = p.type; }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(8)),
              child: Text(p.name, style: const TextStyle(fontSize: 12)),
            ),
          )).toList()),
          const SizedBox(height: 16),

          // Name
          const Text('Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TextField(controller: _nameCtl, decoration: const InputDecoration(isDense: true, hintText: 'e.g. BDO Savings')),
          const SizedBox(height: 14),

          // Type chips
          const Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            ...['cash', 'bank', 'e-wallet', 'credit-card', 'custom'].map((t) {
              final label = t == 'bank' ? 'Bank Account' : t == 'e-wallet' ? 'E-Wallet'
                  : t == 'credit-card' ? 'Credit Card' : t == 'custom' ? 'Custom'
                  : t[0].toUpperCase() + t.substring(1);
              final selected = _type == t;
              return GestureDetector(
                onTap: () => setState(() => _type = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
                    border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(14)),
                  child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: selected ? cs.primary : cs.onSurfaceVariant)),
                ),
              );
            }),
          ]),
          const SizedBox(height: 14),

          // Currency + Starting Balance
          Row(children: [
            // Currency
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Currency', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              DropdownButton<String>(
                value: _currency, isDense: true, underline: const SizedBox.shrink(),
                items: kCurrencies.map((c) => DropdownMenuItem(value: c.code,
                    child: Text('${c.symbol} ${c.code}', style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _currency = v ?? 'PHP'),
              ),
            ]),
            const SizedBox(width: 16),
            // Starting Balance
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Starting Balance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextField(controller: _balanceCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,\-]'))],
                decoration: const InputDecoration(isDense: true, hintText: '0.00')),
            ])),
          ]),
          const SizedBox(height: 20),

          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Add Account'),
          ),
        ]),
      ),
    );
  }
}
