import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/models/account.dart';

/// Data class holding the state for one split entry.
class SplitEntry {
  String? accountId;
  final TextEditingController amountCtl;
  SplitEntry({this.accountId}) : amountCtl = TextEditingController();
}

/// Section of the Add Transaction dialog that shows the split-between-accounts UI.
class SplitTransactionSection extends StatelessWidget {
  final List<SplitEntry> entries;
  final List<Account> accounts;
  final ColorScheme cs;
  final VoidCallback onChanged;
  final VoidCallback onAddEntry;
  final void Function(int index) onRemoveEntry;

  const SplitTransactionSection({
    super.key,
    required this.entries,
    required this.accounts,
    required this.cs,
    required this.onChanged,
    required this.onAddEntry,
    required this.onRemoveEntry,
  });

  String _formatWithCommas(double value) {
    if (value == 0) return '0.00';
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return '$buffer.$decPart';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total amount', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        // Show total from split entries
        Builder(builder: (_) {
          double total = 0;
          for (final e in entries) {
            total += double.tryParse(e.amountCtl.text.replaceAll(',', '')) ?? 0;
          }
          return Text('\u20B1 ${_formatWithCommas(total)}',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant));
        }),
        const SizedBox(height: 12),
        Text('Split between accounts', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        ...List.generate(entries.length, (i) {
          final entry = entries[i];
          final acct = accounts.where((a) => a.id == entry.accountId).firstOrNull;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(12),
              color: cs.surfaceContainerLowest,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Account dropdown
              Row(children: [
                Expanded(
                  child: PopupMenuButton<String>(
                    onSelected: (id) {
                      entry.accountId = id;
                      onChanged();
                    },
                    itemBuilder: (_) => accounts.map((a) => PopupMenuItem(
                      value: a.id,
                      child: Row(children: [
                        Expanded(child: Text(a.name, style: const TextStyle(fontSize: 13))),
                        const SizedBox(width: 8),
                        Text(formatCurrency(a.balance, currencyCode: a.currency),
                            style: TextStyle(fontSize: 11, color: AppColors.income, fontWeight: FontWeight.w600)),
                      ]),
                    )).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        Expanded(child: Text(acct?.name ?? 'Choose an account',
                            style: TextStyle(fontSize: 12, color: acct != null ? cs.onSurface : cs.onSurfaceVariant))),
                        if (acct != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(acct.currency, style: TextStyle(fontSize: 10, color: cs.primary, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Icon(LucideIcons.chevronDown, size: 12, color: cs.onSurfaceVariant),
                      ]),
                    ),
                  ),
                ),
                if (entries.length > 2) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onRemoveEntry(i),
                    child: Icon(LucideIcons.x, size: 16, color: cs.onSurfaceVariant),
                  ),
                ],
              ]),
              if (acct != null) ...[
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(acct.type, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                  Text(formatCurrency(acct.balance, currencyCode: acct.currency),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.income)),
                ]),
              ],
              const SizedBox(height: 8),
              // Amount for this split
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Text('\u20B1', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: entry.amountCtl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                      ThousandsSeparatorFormatter(),
                    ],
                    onChanged: (_) => onChanged(),
                    decoration: const InputDecoration(
                      hintText: '0.00', isDense: true,
                      border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 14),
                  )),
                ]),
              ),
            ]),
          );
        }),
        // Add account button
        GestureDetector(
          onTap: onAddEntry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.plus, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Add account', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Formats numbers with thousand separators: 10000 -> 10,000
class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(',', '');
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

    final formatted = '$buffer$decPart';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
