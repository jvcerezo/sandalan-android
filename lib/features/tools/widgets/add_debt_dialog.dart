import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../core/theme/color_tokens.dart';
import '../../accounts/providers/account_providers.dart';
import '../providers/tool_providers.dart';
import '../../../shared/utils/snackbar_helper.dart';

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(',', '');
    if (text.isEmpty) return newValue;
    final parts = text.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';
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

class AddDebtDialog extends ConsumerStatefulWidget {
  const AddDebtDialog({super.key});
  @override
  ConsumerState<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends ConsumerState<AddDebtDialog> {
  final _nameCtl = TextEditingController();
  final _balanceCtl = TextEditingController();
  final _rateCtl = TextEditingController(text: '0');
  final _minPayCtl = TextEditingController(text: '0');
  final _lenderCtl = TextEditingController();
  final _dueDayCtl = TextEditingController();
  String _type = 'personal_loan';
  String? _accountId;
  bool _saving = false;

  static const _types = {
    'personal_loan': 'Personal Loan',
    'credit_card': 'Credit Card',
    'car_loan': 'Car Loan',
    'home_loan': 'Housing Loan',
    'sss_loan': 'Student Loan',
    'other': 'Other',
  };

  @override
  void dispose() {
    _nameCtl.dispose();
    _balanceCtl.dispose();
    _rateCtl.dispose();
    _minPayCtl.dispose();
    _lenderCtl.dispose();
    _dueDayCtl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = InputSanitizer.sanitize(_nameCtl.text);
    if (name.isEmpty) {
      _showError('Name is required');
      return;
    }
    final balance = double.tryParse(_balanceCtl.text.replaceAll(',', ''));
    if (balance == null || balance <= 0) {
      _showError('Balance must be greater than 0');
      return;
    }
    if (balance > 999999999) {
      _showError('Balance cannot exceed 999,999,999');
      return;
    }
    final rate = double.tryParse(_rateCtl.text.replaceAll(',', '')) ?? 0;
    if (rate < 0 || rate > 300) {
      _showError('Interest rate must be between 0% and 300%');
      return;
    }
    final minPay = double.tryParse(_minPayCtl.text.replaceAll(',', '')) ?? 0;
    if (minPay < 0) {
      _showError('Minimum payment cannot be negative');
      return;
    }
    int? dueDay;
    if (_dueDayCtl.text.trim().isNotEmpty) {
      dueDay = int.tryParse(_dueDayCtl.text.trim());
      if (dueDay != null) dueDay = dueDay.clamp(1, 31);
    }

    setState(() => _saving = true);
    try {
      await ref.read(debtRepositoryProvider).createDebt(
        name: name,
        type: _type,
        currentBalance: balance,
        originalAmount: balance,
        interestRate: rate / 100,
        minimumPayment: minPay,
        lender: InputSanitizer.sanitize(_lenderCtl.text).isEmpty ? null : InputSanitizer.sanitize(_lenderCtl.text),
        dueDay: dueDay,
        accountId: _accountId,
      );
      ref.invalidate(debtsProvider);
      ref.invalidate(debtSummaryProvider);
      if (mounted) {
        Navigator.of(context).pop(true);
        showSuccessSnackBar(context, 'Debt added successfully');
      }
    } catch (e) {
      setState(() => _saving = false);
      _showError('Failed to save: $e');
    }
  }

  void _showError(String msg) {
    showAppSnackBar(context, msg, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Drag handle + title
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Center(child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2)),
            )),
          ),
          const Center(child: Text('Add Debt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),

          // Scrollable form fields
          Expanded(child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            children: [
              _label('Name *'),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtl,
                maxLength: 100,
                decoration: _inputDecoration(cs, 'e.g. BPI Credit Card'),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),

              _label('Balance / Amount *'),
              const SizedBox(height: 6),
              _amountField(cs, _balanceCtl, 'Amount'),
              const SizedBox(height: 12),

              _label('Interest Rate % (annual)'),
              const SizedBox(height: 6),
              TextField(
                controller: _rateCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                decoration: _inputDecoration(cs, '0'),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),

              _label('Minimum Monthly Payment'),
              const SizedBox(height: 6),
              _amountField(cs, _minPayCtl, '0'),
              const SizedBox(height: 12),

              _label('Type'),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, children: _types.entries.map((e) {
                final selected = _type == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _type = e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected ? cs.primary.withOpacity(0.1) : Colors.transparent,
                      border: Border.all(color: selected ? cs.primary : cs.outline.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                        color: selected ? cs.primary : cs.onSurfaceVariant)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 12),

              _label('Lender (optional)'),
              const SizedBox(height: 6),
              TextField(
                controller: _lenderCtl,
                maxLength: 100,
                decoration: _inputDecoration(cs, 'e.g. BPI, SSS'),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Due Day (1-31)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _dueDayCtl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                    decoration: _inputDecoration(cs, 'e.g. 15'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Linked Account'),
                  const SizedBox(height: 6),
                  _accountDropdown(cs, accounts),
                ])),
              ]),
            ],
          )),

          // Sticky button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _handleSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add Debt'),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: TextStyle(
      fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant));

  InputDecoration _inputDecoration(ColorScheme cs, String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withOpacity(0.4)),
    isDense: true,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.outline.withOpacity(0.15))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.outline.withOpacity(0.15))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.primary)),
  );

  Widget _amountField(ColorScheme cs, TextEditingController ctl, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Text('\u20B1', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          controller: ctl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 12,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            _ThousandsSeparatorFormatter(),
          ],
          decoration: InputDecoration(
            hintText: hint, isDense: true, counterText: '',
            border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 14),
        )),
      ]),
    );
  }

  Widget _accountDropdown(ColorScheme cs, List accounts) {
    final selected = accounts.where((a) => a.id == _accountId).firstOrNull;
    return PopupMenuButton<String?>(
      onSelected: (id) => setState(() => _accountId = id),
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('None', style: TextStyle(fontSize: 13))),
        ...accounts.map((a) => PopupMenuItem(
          value: a.id,
          child: Row(children: [
            Expanded(child: Text(a.name, style: const TextStyle(fontSize: 13))),
            Text(formatCurrency(a.balance), style: TextStyle(fontSize: 11, color: AppColors.income)),
          ]),
        )),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Expanded(child: Text(selected?.name ?? 'None',
              style: TextStyle(fontSize: 13, color: selected != null ? cs.onSurface : cs.onSurfaceVariant))),
          Icon(LucideIcons.chevronDown, size: 14, color: cs.onSurfaceVariant),
        ]),
      ),
    );
  }
}
