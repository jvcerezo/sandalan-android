import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/models/transaction.dart';
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

/// Bottom sheet dialog for confirming a pending auto-generated transaction.
/// The user can edit the amount and select an account before confirming.
class ConfirmPaymentDialog extends ConsumerStatefulWidget {
  final Transaction pendingTransaction;
  const ConfirmPaymentDialog({super.key, required this.pendingTransaction});

  @override
  ConsumerState<ConfirmPaymentDialog> createState() => _ConfirmPaymentDialogState();
}

class _ConfirmPaymentDialogState extends ConsumerState<ConfirmPaymentDialog> {
  late final TextEditingController _amountCtl;
  String? _accountId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  Transaction get _txn => widget.pendingTransaction;

  @override
  void initState() {
    super.initState();
    _amountCtl = TextEditingController(
      text: _txn.amount.abs().toStringAsFixed(2),
    );
    _accountId = _txn.accountId;
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  String get _sourceType {
    if (_txn.tags != null) {
      if (_txn.tags!.contains('bill')) return 'bill';
      if (_txn.tags!.contains('debt')) return 'debt';
      if (_txn.tags!.contains('insurance')) return 'insurance';
    }
    return 'payment';
  }

  String get _sourceLabel {
    switch (_sourceType) {
      case 'bill': return 'Bill Payment';
      case 'debt': return 'Debt Payment';
      case 'insurance': return 'Insurance Premium';
      default: return 'Payment';
    }
  }

  /// The source item ID (bill/debt/insurance id) from tags[1].
  String? get _sourceId {
    if (_txn.tags != null && _txn.tags!.length >= 2) {
      return _txn.tags![1];
    }
    return null;
  }

  Future<void> _handleConfirm() async {
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
      final txnRepo = ref.read(transactionRepositoryProvider);

      // If amount was changed, update the transaction first.
      if (amount != _txn.amount.abs()) {
        await txnRepo.updateTransaction(
          id: _txn.id,
          amount: -amount,
          date: _date,
        );
      }

      // Confirm the transaction (marks as confirmed and deducts from account).
      await txnRepo.confirmTransaction(_txn.id, _accountId!);

      // If debt, reduce balance.
      if (_sourceType == 'debt' && _sourceId != null) {
        final debtRepo = ref.read(debtRepositoryProvider);
        final debts = await debtRepo.getDebts();
        final match = debts.where((d) => d.id == _sourceId).firstOrNull;
        if (match != null) {
          final newBalance = (match.currentBalance - amount).clamp(0.0, double.infinity);
          await debtRepo.updateDebt(match.id, {
            'current_balance': newBalance,
            'is_paid_off': newBalance <= 0,
          });
          ref.invalidate(debtsProvider);
          ref.invalidate(debtSummaryProvider);
        }
      }

      // If bill, mark as paid.
      if (_sourceType == 'bill' && _sourceId != null) {
        final billRepo = ref.read(billRepositoryProvider);
        await billRepo.markPaid(_sourceId!);
        ref.invalidate(billsProvider);
        ref.invalidate(billsSummaryProvider);
      }

      // Invalidate all relevant providers.
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(pendingTransactionsProvider);
      ref.invalidate(pendingBillTransactionsProvider);
      ref.invalidate(pendingDebtTransactionsProvider);
      ref.invalidate(pendingInsuranceTransactionsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment of ${formatCurrency(amount)} confirmed')),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      _showError('Failed to confirm payment: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.expense),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.4,
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
              width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2)),
            )),

            Text('Confirm $_sourceLabel',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_txn.description,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),

            // Auto-generated badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(LucideIcons.zap, size: 12, color: AppColors.warning),
                const SizedBox(width: 4),
                Text('Auto-generated — review amount before confirming',
                    style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w500)),
              ]),
            ),
            const SizedBox(height: 16),

            // Amount
            _label('Amount (editable) *'),
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
                  border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
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
            const SizedBox(height: 20),

            // Confirm button
            FilledButton.icon(
              onPressed: _saving ? null : _handleConfirm,
              icon: _saving
                  ? const SizedBox(height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.checkCircle2, size: 16),
              label: const Text('Confirm Payment'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: TextStyle(
      fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant));

  Widget _amountField(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Text('\u20B1', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          controller: _amountCtl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            _ThousandsSeparatorFormatter(),
          ],
          decoration: const InputDecoration(
            hintText: '0.00', isDense: true,
            border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 14),
        )),
        Icon(LucideIcons.edit3, size: 14, color: cs.onSurfaceVariant),
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
          border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
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
