import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../providers/account_providers.dart';
import '../../transactions/providers/transaction_providers.dart';

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

class TransferDialog extends ConsumerStatefulWidget {
  const TransferDialog({super.key});
  @override
  ConsumerState<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends ConsumerState<TransferDialog> {
  final _amountCtl = TextEditingController();
  final _noteCtl = TextEditingController();
  String? _fromAccountId;
  String? _toAccountId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_fromAccountId == null) {
      _showError('Please select a source account');
      return;
    }
    if (_toAccountId == null) {
      _showError('Please select a destination account');
      return;
    }
    if (_fromAccountId == _toAccountId) {
      _showError('Source and destination accounts must be different');
      return;
    }
    final amount = double.tryParse(_amountCtl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showError('Amount must be greater than 0');
      return;
    }

    // Check balance
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    final fromAccount = accounts.where((a) => a.id == _fromAccountId).firstOrNull;
    if (fromAccount != null && amount > fromAccount.balance) {
      _showError('Amount exceeds available balance of ${formatCurrency(fromAccount.balance)}');
      return;
    }

    setState(() => _saving = true);
    try {
      final txnRepo = ref.read(transactionRepositoryProvider);
      await txnRepo.createTransfer(
        fromAccountId: _fromAccountId!,
        toAccountId: _toAccountId!,
        amount: amount,
        date: _date,
        description: _noteCtl.text.trim().isEmpty ? 'Transfer' : _noteCtl.text.trim(),
      );

      ref.invalidate(accountsProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(transactionsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transferred ${formatCurrency(amount)}')),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      _showError('Failed to transfer: $e');
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
    final fromAccount = accounts.where((a) => a.id == _fromAccountId).firstOrNull;
    final toAccounts = accounts.where((a) => a.id != _fromAccountId).toList();

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
                color: cs.outline.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2)),
            )),

            const Text('Transfer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // From Account
            _label('From Account *'),
            const SizedBox(height: 6),
            PopupMenuButton<String>(
              onSelected: (id) => setState(() {
                _fromAccountId = id;
                if (_toAccountId == id) _toAccountId = null;
              }),
              itemBuilder: (_) => accounts.map((a) => PopupMenuItem(
                value: a.id,
                child: Row(children: [
                  Expanded(child: Text(a.name, style: const TextStyle(fontSize: 13))),
                  Text(formatCurrency(a.balance), style: TextStyle(fontSize: 11, color: AppColors.income)),
                  if (a.id == _fromAccountId) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check, size: 16, color: cs.primary),
                  ],
                ]),
              )).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Expanded(child: Text(fromAccount?.name ?? 'Select account',
                      style: TextStyle(fontSize: 13, color: fromAccount != null ? cs.onSurface : cs.onSurfaceVariant))),
                  if (fromAccount != null)
                    Text('Available: ${formatCurrency(fromAccount.balance)}',
                        style: TextStyle(fontSize: 11, color: AppColors.income, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.chevronDown, size: 14, color: cs.onSurfaceVariant),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // To Account
            _label('To Account *'),
            const SizedBox(height: 6),
            PopupMenuButton<String>(
              onSelected: (id) => setState(() => _toAccountId = id),
              itemBuilder: (_) => toAccounts.map((a) => PopupMenuItem(
                value: a.id,
                child: Row(children: [
                  Expanded(child: Text(a.name, style: const TextStyle(fontSize: 13))),
                  Text(formatCurrency(a.balance), style: TextStyle(fontSize: 11, color: AppColors.income)),
                  if (a.id == _toAccountId) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check, size: 16, color: cs.primary),
                  ],
                ]),
              )).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Expanded(child: Text(
                    accounts.where((a) => a.id == _toAccountId).firstOrNull?.name ?? 'Select account',
                    style: TextStyle(fontSize: 13,
                        color: _toAccountId != null ? cs.onSurface : cs.onSurfaceVariant),
                  )),
                  Icon(LucideIcons.chevronDown, size: 14, color: cs.onSurfaceVariant),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // Amount
            _label('Amount *'),
            const SizedBox(height: 6),
            Container(
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
            ),
            const SizedBox(height: 12),

            // Note
            _label('Note (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _noteCtl,
              decoration: InputDecoration(
                hintText: 'Add a note...',
                hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.15))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.15))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: cs.primary)),
              ),
              style: const TextStyle(fontSize: 13),
            ),
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
                  : const Text('Transfer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: TextStyle(
      fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant));
}
