import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/milestone_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/models/debt.dart';
import '../../../shared/widgets/milestone_celebration.dart';
import '../../accounts/providers/account_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../providers/tool_providers.dart';

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

class RecordDebtPaymentDialog extends ConsumerStatefulWidget {
  final Debt debt;
  const RecordDebtPaymentDialog({super.key, required this.debt});
  @override
  ConsumerState<RecordDebtPaymentDialog> createState() => _RecordDebtPaymentDialogState();
}

class _RecordDebtPaymentDialogState extends ConsumerState<RecordDebtPaymentDialog> {
  late final TextEditingController _amountCtl;
  final _noteCtl = TextEditingController();
  String? _accountId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtl = TextEditingController(
      text: widget.debt.minimumPayment > 0
          ? widget.debt.minimumPayment.toStringAsFixed(2)
          : '',
    );
    _accountId = widget.debt.accountId;
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountCtl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showError('Amount must be greater than 0');
      return;
    }
    if (_accountId == null) {
      _showError('Please select an account to deduct from');
      return;
    }

    setState(() => _saving = true);
    try {
      // 1. Create an expense transaction for the payment
      final txnRepo = ref.read(transactionRepositoryProvider);
      await txnRepo.createTransaction(
        amount: -amount,
        category: 'Debt Payment',
        description: InputSanitizer.sanitize(_noteCtl.text).isEmpty
            ? 'Payment for ${widget.debt.name}'
            : InputSanitizer.sanitize(_noteCtl.text),
        date: _date,
        accountId: _accountId,
      );

      // 2. Reduce the debt balance
      final debtRepo = ref.read(debtRepositoryProvider);
      final newBalance = (widget.debt.currentBalance - amount).clamp(0.0, double.infinity);
      await debtRepo.updateDebt(widget.debt.id, {
        'current_balance': newBalance,
        'is_paid_off': newBalance <= 0,
      });

      ref.invalidate(debtsProvider);
      ref.invalidate(debtSummaryProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(accountsProvider);

      if (mounted) {
        final ctx = context;
        Navigator.of(ctx).pop(true);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Payment of ${formatCurrency(amount)} recorded')),
        );
        // Fire-and-forget debt milestone checks
        _checkDebtMilestones(ctx, newBalance);
      }
    } catch (e) {
      setState(() => _saving = false);
      _showError('Failed to record payment: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.expense),
    );
  }

  Future<void> _checkDebtMilestones(BuildContext ctx, double newBalance) async {
    try {
      // First debt payment
      final m1 = await MilestoneService.checkAndTrigger('first_debt_payment');
      if (m1 != null && ctx.mounted) {
        showMilestoneCelebration(ctx, m1);
        return;
      }
      // 50% paid off on this specific debt
      final debt = widget.debt;
      if (debt.originalAmount > 0 && newBalance <= debt.originalAmount * 0.5) {
        final m2 = await MilestoneService.checkAndTrigger('debt_50_percent');
        if (m2 != null && ctx.mounted) {
          showMilestoneCelebration(ctx, m2);
          return;
        }
      }
      // Fully paid off this debt — check if ALL debts are now paid
      if (newBalance <= 0) {
        final m3 = await MilestoneService.checkAndTrigger('first_debt_paid');
        if (m3 != null && ctx.mounted) {
          showMilestoneCelebration(ctx, m3);
          return;
        }
        // Check all debts paid
        final debtRepo = ref.read(debtRepositoryProvider);
        final debts = await debtRepo.getDebts();
        if (debts.every((d) => d.isPaidOff || d.id == debt.id)) {
          final m4 = await MilestoneService.checkAndTrigger('all_debts_paid');
          if (m4 != null && ctx.mounted) {
            showMilestoneCelebration(ctx, m4);
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.7,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Center(child: Container(
              width: 36, height: 4, margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: cs.outline.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2)),
            )),

            Text('Record Payment', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('For: ${widget.debt.name}',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            Text('Balance: ${formatCurrency(widget.debt.currentBalance)}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),

            // Amount
            _label('Amount *'),
            const SizedBox(height: 6),
            _amountField(cs),
            const SizedBox(height: 12),

            // Date
            _label('Date'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Expanded(child: Text(
                    '${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')}/${_date.year}',
                    style: const TextStyle(fontSize: 13),
                  )),
                  Icon(LucideIcons.calendar, size: 14, color: cs.onSurfaceVariant),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // Account
            _label('Account *'),
            const SizedBox(height: 6),
            _accountDropdown(cs, accounts),
            const SizedBox(height: 12),

            // Note
            _label('Note (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _noteCtl,
              decoration: _inputDecoration(cs, 'Add a note...'),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Submit
            FilledButton(
              onPressed: _saving ? null : _handleSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: TextStyle(
      fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant));

  InputDecoration _inputDecoration(ColorScheme cs, String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withOpacity(0.4)),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.outline.withOpacity(0.15))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.outline.withOpacity(0.15))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.primary)),
  );

  Widget _amountField(ColorScheme cs) {
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
          controller: _amountCtl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 12,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            _ThousandsSeparatorFormatter(),
          ],
          decoration: const InputDecoration(
            hintText: '0.00', isDense: true, counterText: '',
            border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 14),
        )),
      ]),
    );
  }

  Widget _accountDropdown(ColorScheme cs, List accounts) {
    final selected = accounts.where((a) => a.id == _accountId).firstOrNull;
    return PopupMenuButton<String>(
      onSelected: (id) => setState(() => _accountId = id),
      itemBuilder: (_) => accounts.map<PopupMenuEntry<String>>((a) => PopupMenuItem<String>(
        value: a.id,
        child: Row(children: [
          Expanded(child: Text(a.name, style: const TextStyle(fontSize: 13))),
          Text(formatCurrency(a.balance), style: TextStyle(fontSize: 11, color: AppColors.income)),
        ]),
      )).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Expanded(child: Text(selected?.name ?? 'Select account',
              style: TextStyle(fontSize: 13, color: selected != null ? cs.onSurface : cs.onSurfaceVariant))),
          Icon(LucideIcons.chevronDown, size: 14, color: cs.onSurfaceVariant),
        ]),
      ),
    );
  }
}
