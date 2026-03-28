import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../accounts/providers/account_providers.dart';
import '../providers/goal_providers.dart';
import '../../../shared/utils/snackbar_helper.dart';

// Formats numbers with thousand separators: 10000 → 10,000
class _ThousandsSeparatorFormatter extends TextInputFormatter {
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

class AddGoalDialog extends ConsumerStatefulWidget {
  const AddGoalDialog({super.key});
  @override
  ConsumerState<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends ConsumerState<AddGoalDialog> {
  String _category = kGoalCategories.first;
  final _nameCtl = TextEditingController();
  final _targetCtl = TextEditingController();
  final _savedCtl = TextEditingController();
  final _customCategoryCtl = TextEditingController();
  DateTime? _deadline;
  String? _accountId;
  bool _saving = false;
  String? _customCategoryError;
  bool _showAllCategories = false;

  static const _visibleCategoryCount = 5;

  @override
  void dispose() { _nameCtl.dispose(); _targetCtl.dispose(); _savedCtl.dispose(); _customCategoryCtl.dispose(); super.dispose(); }

  /// Check if the custom category duplicates an existing one (case-insensitive).
  /// Checks both built-in categories and existing goal categories.
  void _validateCustomCategory(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) {
      setState(() => _customCategoryError = null);
      return;
    }
    // Check built-in categories
    if (kGoalCategories.any((c) => c.toLowerCase() == trimmed && c != 'Other')) {
      setState(() => _customCategoryError = 'This category already exists \u2014 select it above');
      return;
    }
    // Check existing goal categories
    final goals = ref.read(goalsProvider).valueOrNull ?? [];
    if (goals.any((g) => g.category.toLowerCase() == trimmed)) {
      setState(() => _customCategoryError = 'This category already exists');
      return;
    }
    setState(() => _customCategoryError = null);
  }

  bool get _hasCustomCategoryError => _category == 'Other' && _customCategoryError != null;

  /// The effective category to save — uses custom input when "Other" is selected.
  String get _effectiveCategory {
    if (_category == 'Other') {
      final custom = _customCategoryCtl.text.trim();
      return custom.isNotEmpty ? custom : 'Other';
    }
    return _category;
  }

  IconData _icon(String c) {
    switch (c) {
      case 'Emergency Fund': return LucideIcons.shield;
      case 'Debt Payoff': return LucideIcons.creditCard;
      case 'Savings': return LucideIcons.piggyBank;
      case 'Investment': return LucideIcons.trendingUp;
      case 'Retirement': return LucideIcons.clock;
      case 'Travel': return LucideIcons.plane;
      case 'Education': return LucideIcons.graduationCap;
      case 'Home': return LucideIcons.home;
      case 'Vehicle': return LucideIcons.car;
      case 'Other': return LucideIcons.moreHorizontal;
      default: return LucideIcons.moreHorizontal;
    }
  }

  Future<void> _save() async {
    final name = InputSanitizer.sanitize(_nameCtl.text);
    final target = double.tryParse(_targetCtl.text.replaceAll(',', ''));
    if (name.isEmpty || target == null || target <= 0) return;
    if (target > 999999999) {
      showAppSnackBar(context, 'Amount must be less than \u20B1999,999,999', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = double.tryParse(_savedCtl.text.replaceAll(',', '')) ?? 0;
      final category = _category == 'Other'
          ? InputSanitizer.sanitize(_customCategoryCtl.text).trim()
          : _effectiveCategory;
      await ref.read(goalRepositoryProvider).createGoal(
          name: name, targetAmount: target, currentAmount: saved,
          category: category.isEmpty ? 'Other' : category, deadline: _deadline,
          accountId: _accountId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) { setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Determine visible categories
    final visibleCategories = _showAllCategories
        ? kGoalCategories
        : kGoalCategories.take(_visibleCategoryCount).toList();
    // Ensure the selected category is always visible
    if (!_showAllCategories && !visibleCategories.contains(_category)) {
      // Selected category is hidden — show all
    }

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.9, maxChildSize: 0.95, minChildSize: 0.3, expand: false,
      builder: (context, ctl) => Container(
        decoration: BoxDecoration(color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          // Drag handle + title
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: cs.outline.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
          ),
          const Center(child: Text('Create a New Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),

          // Scrollable content
          Expanded(child: ListView(controller: ctl, padding: EdgeInsets.fromLTRB(20, 0, 20, 0 + keyboardHeight), children: [
            // Category
            const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              ...visibleCategories.map((c) {
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
              }),
              if (!_showAllCategories && kGoalCategories.length > _visibleCategoryCount)
                GestureDetector(
                  onTap: () => setState(() => _showAllCategories = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outline.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(14)),
                    child: Text('More...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                        color: cs.primary)),
                  ),
                ),
            ]),

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

            // Goal Name
            const Text('Goal Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                border: Border.all(color: cs.outline.withOpacity(0.12)),
                borderRadius: BorderRadius.circular(10)),
              child: TextField(controller: _nameCtl,
                  maxLength: 100,
                  decoration: InputDecoration(isDense: true, hintText: 'e.g., Emergency Fund',
                      hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.4)),
                      counterText: '',
                      border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                  style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 10),

            // Target Amount
            const Text('Target Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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
                  controller: _targetCtl, autofocus: true,
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

            // Quick presets for target
            Text('Quick presets', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [10000, 25000, 50000, 100000, 250000, 500000].map((amt) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _targetCtl.text = _formatWithCommas(amt.toDouble());
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
            const SizedBox(height: 10),

            // Saved So Far + Deadline on one row
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Saved So Far (optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    border: Border.all(color: cs.outline.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(10)),
                  child: TextField(controller: _savedCtl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    maxLength: 12,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                      _ThousandsSeparatorFormatter(),
                    ],
                    decoration: InputDecoration(isDense: true, hintText: '0.00 (optional)', prefixText: '\u20B1 ',
                        prefixStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                        counterText: ''),
                    style: const TextStyle(fontSize: 14)),
                ),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Deadline (optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(context: context,
                        initialDate: DateTime.now().add(const Duration(days: 90)),
                        firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
                    if (picked != null) setState(() => _deadline = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      border: Border.all(color: cs.outline.withOpacity(0.12)),
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Text(_deadline != null
                          ? '${_deadline!.month.toString().padLeft(2, '0')}/${_deadline!.day.toString().padLeft(2, '0')}/${_deadline!.year}'
                          : 'mm/dd/yyyy',
                          style: TextStyle(fontSize: 12, color: _deadline != null ? cs.onSurface : cs.onSurfaceVariant)),
                      const Spacer(),
                      Icon(LucideIcons.calendar, size: 14, color: cs.onSurfaceVariant),
                    ]),
                  ),
                ),
              ])),
            ]),
            const SizedBox(height: 10),

            // Linked Account
            const Text('Linked Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Builder(builder: (context) {
              final cs = Theme.of(context).colorScheme;
              final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
              final selected = accounts.where((a) => a.id == _accountId).firstOrNull;
              return PopupMenuButton<String>(
                onSelected: (id) => setState(() => _accountId = id),
                itemBuilder: (_) => accounts.map<PopupMenuEntry<String>>((a) => PopupMenuItem<String>(
                  value: a.id,
                  child: Text(a.name, style: const TextStyle(fontSize: 13)),
                )).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    border: Border.all(color: cs.outline.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(
                      selected?.name ?? 'Select account (for fund transfers)',
                      style: TextStyle(fontSize: 12, color: selected != null ? cs.onSurface : cs.onSurfaceVariant),
                    )),
                    Icon(LucideIcons.chevronDown, size: 14, color: cs.onSurfaceVariant),
                  ]),
                ),
              );
            }),
          ])),

          // STICKY: Create Goal button
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
                    : const Text('Create Goal'),
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
