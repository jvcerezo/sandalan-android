import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/models/transaction.dart';
import '../../accounts/providers/account_providers.dart';
import '../../accounts/widgets/add_account_dialog.dart';
import '../../tools/providers/tool_providers.dart';
import '../providers/transaction_providers.dart';

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

class AddTransactionDialog extends ConsumerStatefulWidget {
  final bool isIncome;
  final String? defaultAccountId;
  final Transaction? editTransaction;

  const AddTransactionDialog({super.key, this.isIncome = false, this.defaultAccountId, this.editTransaction});

  @override
  ConsumerState<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _SplitEntry {
  String? accountId;
  final TextEditingController amountCtl;
  _SplitEntry({this.accountId}) : amountCtl = TextEditingController();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  late bool _isIncome;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagsController = TextEditingController();
  final _customCategoryController = TextEditingController();
  String? _selectedAccountId;
  String _category = '';
  DateTime _date = DateTime.now();
  bool _showRepeat = false;
  bool _showSplit = false;
  final List<_SplitEntry> _splitEntries = [];
  int _repeatInterval = 1;
  String _repeatFrequency = 'monthly';
  TimeOfDay? _repeatTime;
  DateTime? _repeatEndDate;
  bool _saving = false;
  bool _autoSelected = false;
  String? _customCategoryError;

  @override
  void initState() {
    super.initState();
    final edit = widget.editTransaction;
    if (edit != null) {
      _isIncome = edit.amount > 0;
      _selectedAccountId = edit.accountId;
      _amountController.text = edit.amount.abs().toStringAsFixed(2);
      _noteController.text = edit.description;
      _tagsController.text = edit.tags?.join(', ') ?? '';
      _date = DateTime.parse(edit.date);
      _category = _categories.contains(edit.category) ? edit.category : 'Other';
      if (_category == 'Other' && edit.category != 'Other') {
        _customCategoryController.text = edit.category;
      }
      _autoSelected = true;
    } else {
      _isIncome = widget.isIncome;
      _selectedAccountId = widget.defaultAccountId;
      _category = _categories.first;
    }
    // Initialize with 2 split entries
    _splitEntries.add(_SplitEntry());
    _splitEntries.add(_SplitEntry());
  }

  List<String> get _categories => _isIncome ? kIncomeCategories : kExpenseCategories;

  /// Check if the custom category duplicates an existing one (case-insensitive).
  void _validateCustomCategory(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isNotEmpty &&
        _categories.any((c) => c.toLowerCase() == trimmed && c != 'Other')) {
      setState(() => _customCategoryError = 'This category already exists \u2014 select it above');
    } else {
      setState(() => _customCategoryError = null);
    }
  }

  bool get _hasCustomCategoryError => _category == 'Other' && _customCategoryError != null;

  /// The effective category to save — uses custom input when "Other" is selected.
  String get _effectiveCategory {
    if (_category == 'Other') {
      final custom = _customCategoryController.text.trim();
      return custom.isNotEmpty ? custom : 'Other';
    }
    return _category;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Compute the next run date from today based on frequency and interval.
  String _computeNextRunDate() {
    final now = _date;
    late DateTime next;
    switch (_repeatFrequency) {
      case 'daily':
        next = now.add(Duration(days: _repeatInterval));
        break;
      case 'weekly':
        next = now.add(Duration(days: 7 * _repeatInterval));
        break;
      case 'monthly':
      default:
        next = DateTime(now.year, now.month + _repeatInterval, now.day);
        break;
    }
    return next.toIso8601String().substring(0, 10);
  }

  /// Create a recurring transaction entry via the repository.
  Future<void> _createRecurringTransaction(double amount, List<String>? tags) async {
    try {
      final recurringRepo = ref.read(recurringTransactionRepositoryProvider);
      final signedAmount = _isIncome ? amount : -amount;
      final timeStr = _repeatTime != null
          ? '${_repeatTime!.hour.toString().padLeft(2, '0')}:${_repeatTime!.minute.toString().padLeft(2, '0')}:00'
          : null;

      await recurringRepo.createRecurring({
        'amount': signedAmount,
        'category': _effectiveCategory,
        'description': InputSanitizer.sanitize(_noteController.text),
        'currency': 'PHP',
        'account_id': _selectedAccountId,
        'frequency': _repeatFrequency,
        'interval_count': _repeatInterval,
        'start_date': _date.toIso8601String().substring(0, 10),
        'end_date': _repeatEndDate?.toIso8601String().substring(0, 10),
        'next_run_date': _computeNextRunDate(),
        'run_time': timeStr,
        'is_active': true,
        'tags': tags,
      });
    } catch (_) {
      // Non-critical — the immediate transaction was already saved.
      // The recurring entry failing shouldn't block the user.
    }
  }

  Future<void> _handleSave() async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];

    if (_showSplit) {
      // Split mode validations
      // Check all accounts selected
      final hasUnselected = _splitEntries.any((e) => e.accountId == null);
      if (hasUnselected) {
        _showError('Select an account for each split part');
        return;
      }

      // Check duplicate accounts
      final accountIds = _splitEntries.map((e) => e.accountId).toList();
      if (accountIds.toSet().length != accountIds.length) {
        _showError('Select different accounts for each split part');
        return;
      }

      // Parse split amounts and validate upper bound
      double splitTotal = 0;
      for (final entry in _splitEntries) {
        final amt = double.tryParse(entry.amountCtl.text.replaceAll(',', '')) ?? 0;
        if (amt > 999999999) {
          _showError('Amount must be less than \u20B1999,999,999');
          return;
        }
        splitTotal += amt;
      }

      if (splitTotal <= 0) {
        _showError('Enter an amount for each split part');
        return;
      }

      // Check insufficient balance for each split entry (expense only)
      if (!_isIncome) {
        for (final entry in _splitEntries) {
          final amt = double.tryParse(entry.amountCtl.text.replaceAll(',', '')) ?? 0;
          final acct = accounts.where((a) => a.id == entry.accountId).firstOrNull;
          if (acct != null && acct.type != 'credit_card' && amt > acct.balance) {
            _showError('Insufficient balance in ${acct.name}');
            return;
          }
        }
      }

      // For split mode, use the split total as the main amount
      setState(() => _saving = true);

      try {
        final repo = ref.read(transactionRepositoryProvider);
        final tags = _tagsController.text.trim().isEmpty
            ? null
            : _tagsController.text.split(',').map((t) => InputSanitizer.sanitize(t)).where((t) => t.isNotEmpty).toList();

        // Create a transaction for each split entry
        for (final entry in _splitEntries) {
          final amt = double.tryParse(entry.amountCtl.text.replaceAll(',', '')) ?? 0;
          if (amt <= 0) continue;
          await repo.createTransaction(
            amount: -amt,
            category: _effectiveCategory,
            description: InputSanitizer.sanitize(_noteController.text),
            date: _date,
            accountId: entry.accountId,
            tags: tags,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction added!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        setState(() => _saving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: $e')),
          );
        }
      }
      return;
    }

    // Normal (non-split) mode
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Enter a valid amount');
      return;
    }

    // Amount upper bound
    if (amount > 999999999) {
      _showError('Amount must be less than \u20B1999,999,999');
      return;
    }

    // Account selection check
    if (_selectedAccountId == null) {
      _showError('Select an account');
      return;
    }

    // Insufficient balance check (expense, non-credit-card)
    if (!_isIncome) {
      final selectedAccount = accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
      if (selectedAccount != null && selectedAccount.type != 'credit_card' && amount > selectedAccount.balance) {
        _showError('Insufficient balance in ${selectedAccount.name}');
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final tags = _tagsController.text.trim().isEmpty
          ? null
          : _tagsController.text.split(',').map((t) => InputSanitizer.sanitize(t)).where((t) => t.isNotEmpty).toList();

      final edit = widget.editTransaction;
      if (edit != null) {
        await repo.updateTransaction(
          id: edit.id,
          amount: _isIncome ? amount : -amount,
          category: _effectiveCategory,
          description: InputSanitizer.sanitize(_noteController.text),
          date: _date,
          accountId: _selectedAccountId,
          tags: tags,
        );
      } else {
        await repo.createTransaction(
          amount: _isIncome ? amount : -amount,
          category: _effectiveCategory,
          description: InputSanitizer.sanitize(_noteController.text),
          date: _date,
          accountId: _selectedAccountId,
          tags: tags,
        );

        // Create recurring transaction if repeat is enabled
        if (_showRepeat) {
          await _createRecurringTransaction(amount, tags);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(edit != null
                ? 'Transaction updated!'
                : _showRepeat
                    ? 'Transaction added with repeat!'
                    : 'Transaction added!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];

    // Auto-select first account if none selected yet
    if (_selectedAccountId == null && accounts.isNotEmpty && !_autoSelected) {
      _autoSelected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedAccountId = accounts.first.id;
            _splitEntries[0].accountId = accounts.first.id;
          });
        }
      });
    }

    final selectedAccount = accounts.where((a) => a.id == _selectedAccountId).firstOrNull;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
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
            // Drag handle
            Center(child: Container(
              width: 36, height: 4, margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2)),
            )),

            // No accounts — guide user to create one first
            if (accounts.isEmpty) ...[
              const SizedBox(height: 32),
              Center(child: Icon(LucideIcons.wallet, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3))),
              const SizedBox(height: 16),
              Text(
                _isIncome ? 'Create an account to add income' : 'Create an account to add expenses',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'You need at least one account (e.g., Cash, GCash, BDO) before you can track transactions.',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  // Close this dialog, open Add Account, then re-open this dialog
                  Navigator.pop(context);
                  final created = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddAccountDialog(),
                  );
                  if (created == true && context.mounted) {
                    // Re-open transaction dialog after account is created
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AddTransactionDialog(
                        isIncome: _isIncome,
                        defaultAccountId: widget.defaultAccountId,
                      ),
                    );
                  }
                },
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Create Account'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 32),
            ] else ...[

            // Header: "Add Expense" / "Add Income" + Split + Repeat toggle
            Row(children: [
              Text(widget.editTransaction != null
                  ? 'Edit ${_isIncome ? 'Income' : 'Expense'}'
                  : (_isIncome ? 'Add Income' : 'Add Expense'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (!_isIncome) ...[
                GestureDetector(
                  onTap: () => setState(() {
                    _showSplit = !_showSplit;
                    if (_showSplit) {
                      _showRepeat = false;
                      _splitEntries[0].accountId = _selectedAccountId;
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _showSplit ? cs.primary : Colors.transparent,
                      border: Border.all(color: _showSplit ? cs.primary : cs.outline.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(LucideIcons.gitBranch, size: 12,
                          color: _showSplit ? cs.onPrimary : cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('Split', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                          color: _showSplit ? cs.onPrimary : cs.onSurfaceVariant)),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              GestureDetector(
                onTap: () => setState(() {
                  _showRepeat = !_showRepeat;
                  if (_showRepeat) _showSplit = false;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _showRepeat ? cs.primary : Colors.transparent,
                    border: Border.all(color: _showRepeat ? cs.primary : cs.outline.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(LucideIcons.repeat, size: 12,
                        color: _showRepeat ? cs.onPrimary : cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('Repeat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                        color: _showRepeat ? cs.onPrimary : cs.onSurfaceVariant)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // ─── Account selector (hidden in split mode) ─────────────
            if (!_showSplit) ...[
              Text('Account', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              // Account dropdown
              PopupMenuButton<String>(
                onSelected: (id) => setState(() => _selectedAccountId = id),
                itemBuilder: (_) => accounts.map((a) => PopupMenuItem(
                  value: a.id,
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(a.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(a.currency, style: TextStyle(fontSize: 10, color: cs.primary, fontWeight: FontWeight.w500)),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(a.type, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                    ])),
                    Text(formatCurrency(a.balance, currencyCode: a.currency),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.income)),
                    if (a.id == _selectedAccountId) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check, size: 16, color: cs.primary),
                    ],
                  ]),
                )).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(selectedAccount?.name ?? 'Select account',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    if (selectedAccount != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(selectedAccount.currency,
                            style: TextStyle(fontSize: 10, color: cs.primary, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 6),
                      Text(formatCurrency(selectedAccount.balance, currencyCode: selectedAccount.currency),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.income)),
                    ],
                    const SizedBox(width: 4),
                    Icon(LucideIcons.chevronDown, size: 14, color: cs.onSurfaceVariant),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ─── Split mode ─────────────────────────────────────
            if (_showSplit) ...[
              Text('Total amount', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              // Show total from split entries
              Builder(builder: (_) {
                double total = 0;
                for (final e in _splitEntries) {
                  total += double.tryParse(e.amountCtl.text.replaceAll(',', '')) ?? 0;
                }
                return Text('\u20B1 ${_formatWithCommas(total)}',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant));
              }),
              const SizedBox(height: 12),
              Text('Split between accounts', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              ...List.generate(_splitEntries.length, (i) {
                final entry = _splitEntries[i];
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
                          onSelected: (id) => setState(() => entry.accountId = id),
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
                      if (_splitEntries.length > 2) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _splitEntries.removeAt(i)),
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
                            _ThousandsSeparatorFormatter(),
                          ],
                          onChanged: (_) => setState(() {}),
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
              // Add account button — styled as outlined chip
              GestureDetector(
                onTap: () => setState(() => _splitEntries.add(_SplitEntry())),
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

            // ─── Normal amount input ──────────────────────────────
            if (!_showSplit) ...[
            // Amount input
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text('\u20B1', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant)),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                    _ThousandsSeparatorFormatter(),
                  ],
                  autofocus: true,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                    border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ]),
            ],
            const SizedBox(height: 12),

            // Category
            Text('Category', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: _categories.map((c) {
              final selected = _category == c;
              return GestureDetector(
                onTap: () => setState(() => _category = c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
                    border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_categoryIcon(c), size: 12,
                        color: selected ? cs.primary : cs.onSurfaceVariant),
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
                controller: _customCategoryController,
                onChanged: _validateCustomCategory,
                decoration: InputDecoration(
                  hintText: 'Type a custom category name...',
                  hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  errorText: _customCategoryError,
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
            const SizedBox(height: 14),

            // Note + Date row
            Row(children: [
              Expanded(child: TextField(
                controller: _noteController,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Add a note... (optional)',
                  hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  border: InputBorder.none, contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
                style: const TextStyle(fontSize: 13),
              )),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context, initialDate: _date,
                    firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Text('${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')}/${_date.year}',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.calendar, size: 14, color: cs.onSurfaceVariant),
                  ]),
                ),
              ),
            ]),
            Divider(color: cs.outline.withValues(alpha: 0.10)),
            const SizedBox(height: 8),

            // Tags
            TextField(
              controller: _tagsController,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Add tags... (optional)',
                hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                border: InputBorder.none, contentPadding: EdgeInsets.zero,
                counterText: '',
              ),
              style: const TextStyle(fontSize: 13),
            ),
            Divider(color: cs.outline.withValues(alpha: 0.10)),
            const SizedBox(height: 8),

            // Repeat settings (expandable)
            if (_showRepeat) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.04),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(LucideIcons.repeat, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Text('Repeat settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    SizedBox(width: 50, child: TextField(
                      decoration: const InputDecoration(isDense: true),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: '$_repeatInterval'),
                      onChanged: (v) {
                        final parsed = int.tryParse(v) ?? 1;
                        _repeatInterval = parsed.clamp(1, 365);
                      },
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _repeatFrequency, isDense: true,
                      items: ['daily', 'weekly', 'monthly'].map((f) =>
                          DropdownMenuItem(value: f, child: Text('${f[0].toUpperCase()}${f.substring(1)}(s)'))).toList(),
                      onChanged: (v) => setState(() => _repeatFrequency = v ?? 'monthly'),
                    )),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Time (optional)', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _repeatTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) setState(() => _repeatTime = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            Text(
                              _repeatTime != null ? _repeatTime!.format(context) : '--:-- --',
                              style: TextStyle(fontSize: 12,
                                  color: _repeatTime != null ? cs.onSurface : cs.onSurfaceVariant),
                            ),
                            const Spacer(),
                            Icon(LucideIcons.clock, size: 14, color: cs.onSurfaceVariant),
                          ]),
                        ),
                      ),
                    ])),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('End date (optional)', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _repeatEndDate ?? DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (picked != null) setState(() => _repeatEndDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            Text(
                              _repeatEndDate != null
                                  ? '${_repeatEndDate!.month.toString().padLeft(2, '0')}/${_repeatEndDate!.day.toString().padLeft(2, '0')}/${_repeatEndDate!.year}'
                                  : 'mm/dd/yyyy',
                              style: TextStyle(fontSize: 12,
                                  color: _repeatEndDate != null ? cs.onSurface : cs.onSurfaceVariant),
                            ),
                            const Spacer(),
                            Icon(LucideIcons.calendar, size: 14, color: cs.onSurfaceVariant),
                          ]),
                        ),
                      ),
                    ])),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
            ],

            // Submit button
            FilledButton(
              onPressed: _saving || _hasCustomCategoryError ? null : _handleSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.editTransaction != null
                      ? 'Save Changes'
                      : _showRepeat
                          ? 'Set Recurring ${_isIncome ? 'Income' : 'Expense'}'
                          : _showSplit
                              ? 'Add Split Expense'
                              : 'Add ${_isIncome ? 'Income' : 'Expense'}'),
            ),
            ], // end else (has accounts)
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food': return LucideIcons.utensils;
      case 'Housing': return LucideIcons.home;
      case 'Transportation': return LucideIcons.car;
      case 'Entertainment': return LucideIcons.film;
      case 'Healthcare': return LucideIcons.heart;
      case 'Education': return LucideIcons.graduationCap;
      case 'Family Support': return LucideIcons.moreHorizontal;
      case 'Salary': return LucideIcons.banknote;
      case 'Freelance': return LucideIcons.briefcase;
      case 'Investment': return LucideIcons.trendingUp;
      default: return LucideIcons.moreHorizontal;
    }
  }

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
}
