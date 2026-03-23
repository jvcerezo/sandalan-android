import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/account_types.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../providers/account_providers.dart';

// Formats numbers with thousand separators: 10000 → 10,000 (supports negatives)
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(',', '');
    if (text.isEmpty) return newValue;

    // Preserve negative sign
    final isNegative = text.startsWith('-');
    if (isNegative) text = text.substring(1);
    if (text.isEmpty) return newValue;

    // Split by decimal
    final parts = text.split('.');
    final stripped = int.tryParse(parts[0])?.toString() ?? parts[0];
    String decPart = '';
    if (parts.length > 1) {
      final dec = parts[1].length > 2 ? parts[1].substring(0, 2) : parts[1];
      decPart = '.$dec';
    }

    // Add commas
    final buffer = StringBuffer();
    for (int i = 0; i < stripped.length; i++) {
      if (i > 0 && (stripped.length - i) % 3 == 0) buffer.write(',');
      buffer.write(stripped[i]);
    }

    final formatted = '${isNegative ? '-' : ''}$buffer$decPart';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AddAccountDialog extends ConsumerStatefulWidget {
  const AddAccountDialog({super.key});
  @override
  ConsumerState<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<AddAccountDialog> {
  final _nameCtl = TextEditingController();
  final _balanceCtl = TextEditingController();
  final _customTypeCtl = TextEditingController();
  String _type = 'cash';
  String _currency = 'PHP';
  bool _saving = false;
  String? _nameError;
  String? _customTypeError;

  static const _builtInTypes = ['cash', 'bank', 'e-wallet', 'credit-card'];

  void _validateName(String value) {
    final trimmed = value.trim().toLowerCase();
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    if (trimmed.isNotEmpty && accounts.any((a) => a.name.toLowerCase() == trimmed)) {
      setState(() => _nameError = 'An account with this name already exists');
    } else {
      setState(() => _nameError = null);
    }
  }

  void _validateCustomType(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isNotEmpty && _builtInTypes.any((t) => t.toLowerCase() == trimmed)) {
      setState(() => _customTypeError = 'This type already exists \u2014 select it above');
    } else {
      setState(() => _customTypeError = null);
    }
  }

  bool get _hasValidationError => _nameError != null || (_type == 'custom' && _customTypeError != null);

  @override
  void dispose() { _nameCtl.dispose(); _balanceCtl.dispose(); _customTypeCtl.dispose(); super.dispose(); }

  String get _effectiveType {
    if (_type == 'custom') {
      final custom = _customTypeCtl.text.trim();
      return custom.isNotEmpty ? custom : 'custom';
    }
    return _type;
  }

  Future<void> _save() async {
    final name = InputSanitizer.sanitize(_nameCtl.text);
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final balance = double.tryParse(_balanceCtl.text.replaceAll(',', '')) ?? 0;
      final type = _type == 'custom'
          ? InputSanitizer.sanitize(_customTypeCtl.text)
          : _effectiveType;
      await ref.read(accountRepositoryProvider).createAccount(
          name: name, type: type.isEmpty ? 'custom' : type, currency: _currency, balance: balance);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) { setState(() => _saving = false); }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'cash': return LucideIcons.wallet;
      case 'bank': return LucideIcons.landmark;
      case 'e-wallet': return LucideIcons.smartphone;
      case 'credit-card': return LucideIcons.creditCard;
      default: return LucideIcons.moreHorizontal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.65, maxChildSize: 0.85, minChildSize: 0.3, expand: false,
      builder: (context, ctl) => Container(
        decoration: BoxDecoration(color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: ListView(controller: ctl, padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), children: [
          // Drag handle
          Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: cs.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
          const Center(child: Text('Add Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 12),

          // Quick Add
          Text('Quick Add', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, children: kCommonAccounts.map((p) {
            final selected = _nameCtl.text == p.name && _type == p.type;
            return GestureDetector(
              onTap: () => setState(() { _nameCtl.text = p.name; _type = p.type; }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
                  border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_typeIcon(p.type), size: 12, color: selected ? cs.primary : cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(p.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: selected ? cs.primary : cs.onSurfaceVariant)),
                ]),
              ),
            );
          }).toList()),
          const SizedBox(height: 12),

          // Name
          const Text('Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              border: Border.all(color: _nameError != null ? cs.error : cs.outline.withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(10)),
            child: TextField(controller: _nameCtl,
              onChanged: _validateName,
              maxLength: 100,
              decoration: InputDecoration(isDense: true, hintText: 'e.g. BDO Savings',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  counterText: '',
                  border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
              style: const TextStyle(fontSize: 14)),
          ),
          if (_nameError != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(_nameError!, style: TextStyle(fontSize: 11, color: cs.error)),
            ),
          ],
          const SizedBox(height: 12),

          // Type chips
          const Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, children: [
            ...['cash', 'bank', 'e-wallet', 'credit-card', 'custom'].map((t) {
              final label = t == 'bank' ? 'Bank Account' : t == 'e-wallet' ? 'E-Wallet'
                  : t == 'credit-card' ? 'Credit Card' : t == 'custom' ? 'Custom'
                  : t[0].toUpperCase() + t.substring(1);
              final selected = _type == t;
              return GestureDetector(
                onTap: () => setState(() => _type = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
                    border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(14)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_typeIcon(t), size: 12, color: selected ? cs.primary : cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                        color: selected ? cs.primary : cs.onSurfaceVariant)),
                  ]),
                ),
              );
            }),
          ]),

          // "Custom" type input
          if (_type == 'custom') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customTypeCtl,
              onChanged: _validateCustomType,
              decoration: InputDecoration(
                hintText: 'Type a custom account type...',
                hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                errorText: _customTypeError,
                errorStyle: const TextStyle(fontSize: 11),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: cs.primary),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),

          // Currency + Starting Balance
          Row(children: [
            // Currency
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Currency', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(10)),
                child: DropdownButton<String>(
                  value: _currency, isDense: true, underline: const SizedBox.shrink(),
                  items: kCurrencies.map((c) => DropdownMenuItem(value: c.code,
                      child: Text('${c.symbol} ${c.code}', style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _currency = v ?? 'PHP'),
                ),
              ),
            ]),
            const SizedBox(width: 16),
            // Starting Balance
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Starting Balance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Text(currencySymbol(_currency), style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                  const SizedBox(width: 4),
                  Expanded(child: TextField(controller: _balanceCtl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    maxLength: 12,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.,\-]')),
                      _ThousandsSeparatorFormatter(),
                    ],
                    decoration: InputDecoration(isDense: true, hintText: '0.00 (optional)',
                        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                        counterText: '',
                        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                    style: const TextStyle(fontSize: 14))),
                ]),
              ),
            ])),
          ]),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _saving || _hasValidationError ? null : _save,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Add Account'),
          ),
        ]),
      ),
    );
  }
}
