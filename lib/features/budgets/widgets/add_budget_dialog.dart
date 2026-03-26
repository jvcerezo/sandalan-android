import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../providers/budget_providers.dart';
import '../../../shared/utils/snackbar_helper.dart';

// Formats numbers with thousand separators: 10000 → 10,000
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(',', '');
    if (text.isEmpty) return newValue;

    // Split by decimal
    final parts = text.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    // Add commas
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }

    final formatted = '$buffer$decPart';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AddBudgetDialog extends ConsumerStatefulWidget {
  const AddBudgetDialog({super.key});
  @override
  ConsumerState<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends ConsumerState<AddBudgetDialog> {
  String _category = kExpenseCategories.first;
  String _period = 'monthly';
  final _amountCtl = TextEditingController();
  final _customCategoryCtl = TextEditingController();
  bool _saving = false;
  String? _customCategoryError;

  @override
  void dispose() { _amountCtl.dispose(); _customCategoryCtl.dispose(); super.dispose(); }

  /// Check if the custom category duplicates an existing one (case-insensitive).
  void _validateCustomCategory(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isNotEmpty &&
        kExpenseCategories.any((c) => c.toLowerCase() == trimmed && c != 'Other')) {
      setState(() => _customCategoryError = 'This category already exists \u2014 select it above');
    } else {
      setState(() => _customCategoryError = null);
    }
  }

  bool get _hasCustomCategoryError => _category == 'Other' && _customCategoryError != null;

  /// The effective category to save — uses custom input when "Other" is selected.
  String get _effectiveCategory {
    if (_category == 'Other') {
      final custom = InputSanitizer.sanitize(_customCategoryCtl.text);
      return custom.isNotEmpty ? custom : 'Other';
    }
    return _category;
  }

  IconData _icon(String c) {
    switch (c) {
      case 'Food': return LucideIcons.utensils;
      case 'Housing': return LucideIcons.home;
      case 'Transportation': return LucideIcons.car;
      case 'Entertainment': return LucideIcons.film;
      case 'Healthcare': return LucideIcons.heart;
      case 'Education': return LucideIcons.graduationCap;
      case 'Family Support': return LucideIcons.users;
      case 'Other': return LucideIcons.moreHorizontal;
      default: return LucideIcons.moreHorizontal;
    }
  }

  void _showError(String message) {
    showAppSnackBar(context, message, isError: true);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showError('Enter a valid budget amount');
      return;
    }
    if (amount > 999999999) {
      _showError('Amount must be less than \u20B1999,999,999');
      return;
    }

    // Check for duplicate category in the current period
    final existingBudgets = ref.read(budgetsProvider).valueOrNull ?? [];
    final effectiveCat = _effectiveCategory.toLowerCase();
    final hasDuplicate = existingBudgets.any(
      (b) => b.category.toLowerCase() == effectiveCat,
    );
    if (hasDuplicate) {
      _showError('A budget for $_effectiveCategory already exists this month');
      return;
    }

    setState(() => _saving = true);
    try {
      final month = ref.read(budgetMonthProvider);
      await ref.read(budgetRepositoryProvider).createBudget(
          category: _effectiveCategory, amount: amount, month: month, period: _period);
      if (mounted) {
        showSuccessSnackBar(context, 'Budget added!');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _saving = false);
      _showError('Failed to save budget: $e');
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
        child: Column(children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: cs.outline.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
          ),
          const Center(child: Text('Add Budget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 2),
          Center(child: Text('Set a spending limit for a category.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant), textAlign: TextAlign.center)),
          const SizedBox(height: 8),

          // Scrollable content
          Expanded(child: ListView(controller: ctl, padding: const EdgeInsets.fromLTRB(20, 0, 20, 0), children: [
            // Category
            const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: kExpenseCategories.map((c) {
              final selected = _category == c;
              return GestureDetector(
                onTap: () => setState(() => _category = c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary.withOpacity(0.1) : Colors.transparent,
                    border: Border.all(color: selected ? cs.primary : cs.outline.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(14)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_icon(c), size: 12, color: selected ? cs.primary : cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(c, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                        color: selected ? cs.primary : cs.onSurfaceVariant)),
                  ]),
                ),
              );
            }).toList()),

            // "Other" custom category input
            if (_category == 'Other') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customCategoryCtl,
                onChanged: _validateCustomCategory,
                decoration: InputDecoration(
                  hintText: 'Type a custom category name...',
                  hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withOpacity(0.4)),
                  errorText: _customCategoryError,
                  errorStyle: const TextStyle(fontSize: 11),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: cs.outline.withOpacity(0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: cs.outline.withOpacity(0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: cs.primary),
                  ),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ],
            const SizedBox(height: 10),

            // Budget Period
            const Text('Budget Period', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(children: ['weekly', 'monthly', 'quarterly'].map((p) {
              final selected = _period == p;
              final label = p[0].toUpperCase() + p.substring(1);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _period = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected ? cs.primary : Colors.transparent,
                      border: Border.all(color: selected ? cs.primary : cs.outline.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                        color: selected ? cs.onPrimary : cs.onSurfaceVariant)),
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 10),

            // Budget Limit
            Text('${_period[0].toUpperCase()}${_period.substring(1)} Limit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                border: Border.all(color: cs.outline.withOpacity(0.12)),
                borderRadius: BorderRadius.circular(10)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text('\u20B1', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant)),
                const SizedBox(width: 4),
                Expanded(child: TextField(
                  controller: _amountCtl, autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  maxLength: 12,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                    _ThousandsSeparatorFormatter(),
                  ],
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant),
                  decoration: InputDecoration(hintText: '0.00',
                      hintStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant.withOpacity(0.3)),
                      border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero, counterText: ''),
                )),
              ]),
            ),
            const SizedBox(height: 10),

            // Quick presets - horizontally scrollable single row
            Text('Quick presets', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [1000, 3000, 5000, 10000, 15000, 20000].map((amt) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      final formatted = _formatWithCommas(amt.toDouble());
                      _amountCtl.text = formatted;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: cs.outline.withOpacity(0.15)),
                        borderRadius: BorderRadius.circular(14)),
                      child: Text('\u20B1${_formatWithCommas(amt.toDouble())}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
                    ),
                  ),
                );
              }).toList()),
            ),
          ])),

          // STICKY: Add Budget button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving || _hasCustomCategoryError ? null : _save,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add Budget'),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  String _formatWithCommas(double value) {
    final intVal = value.toInt();
    final str = intVal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
