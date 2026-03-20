import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/categories.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/models/account.dart';
import '../../accounts/providers/account_providers.dart';
import '../providers/transaction_providers.dart';

class AddTransactionDialog extends ConsumerStatefulWidget {
  final String? defaultAccountId;

  const AddTransactionDialog({super.key, this.defaultAccountId});

  @override
  ConsumerState<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  bool _isIncome = false;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'Food';
  String? _accountId;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _accountId = widget.defaultAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> get _categories => _isIncome ? kIncomeCategories : kExpenseCategories;

  Future<void> _handleSave() async {
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.createTransaction(
        amount: _isIncome ? amount : -amount,
        category: _category,
        description: _descriptionController.text.trim(),
        date: _date,
        accountId: _accountId,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Failed to save transaction.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Add Transaction',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(LucideIcons.x, size: 20),
              ),
            ]),
            const SizedBox(height: 12),

            // Type toggle
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _isIncome = false;
                    _category = kExpenseCategories.first;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isIncome ? AppColors.expense.withValues(alpha: 0.1) : Colors.transparent,
                      border: Border.all(
                        color: !_isIncome ? AppColors.expense : colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('Expense',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: !_isIncome ? AppColors.expense : colorScheme.onSurfaceVariant,
                        ))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _isIncome = true;
                    _category = kIncomeCategories.first;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isIncome ? AppColors.income.withValues(alpha: 0.1) : Colors.transparent,
                      border: Border.all(
                        color: _isIncome ? AppColors.income : colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('Income',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: _isIncome ? AppColors.income : colorScheme.onSurfaceVariant,
                        ))),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: TextStyle(fontSize: 12, color: colorScheme.error)),
              ),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              autofocus: true,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₱ ',
                prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                hintText: '0.00',
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 12),

            // Category
            DropdownButtonFormField<String>(
              value: _categories.contains(_category) ? _category : _categories.first,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? _categories.first),
            ),
            const SizedBox(height: 12),

            // Account
            if (accounts.isNotEmpty)
              DropdownButtonFormField<String?>(
                value: _accountId,
                decoration: const InputDecoration(labelText: 'Account'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No account')),
                  ...accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                ],
                onChanged: (v) => setState(() => _accountId = v),
              ),
            const SizedBox(height: 12),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.calendar, size: 20),
              title: Text(formatDateDisplay(_date)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 16),

            // Save
            FilledButton(
              onPressed: _saving ? null : _handleSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: _isIncome ? AppColors.income : AppColors.expense,
              ),
              child: _saving
                  ? const SizedBox(height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isIncome ? 'Add Income' : 'Add Expense'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String formatDateDisplay(DateTime date) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
