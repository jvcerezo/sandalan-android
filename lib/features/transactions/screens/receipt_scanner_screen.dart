import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/categories.dart';
import '../../../core/services/receipt_scanner_service.dart';
import '../../../core/services/receipt_parser.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../data/merchants/merchant_categories.dart';
import '../../accounts/providers/account_providers.dart';
import '../../accounts/widgets/add_account_dialog.dart';
import '../providers/transaction_providers.dart';
import '../../../shared/utils/snackbar_helper.dart';

/// Formats numbers with thousand separators: 10000 -> 10,000
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(',', '');
    if (text.isEmpty) return newValue;

    final parts = text.split('.');
    final stripped = int.tryParse(parts[0])?.toString() ?? parts[0];
    String decPart = '';
    if (parts.length > 1) {
      final dec = parts[1].length > 2 ? parts[1].substring(0, 2) : parts[1];
      decPart = '.$dec';
    }

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

class ReceiptScannerScreen extends ConsumerStatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  ConsumerState<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

enum _ScanState { idle, scanning, review }

class _ReceiptScannerScreenState extends ConsumerState<ReceiptScannerScreen> {
  _ScanState _scanState = _ScanState.idle;
  String? _imagePath;
  ParsedReceipt? _receipt;
  String? _errorMessage;

  // Form fields
  final _storeNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedAccountId;
  String? _selectedDestAccountId; // For transfers
  String _category = 'Other';
  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _autoSelected = false;
  String? _originalCategory; // Track for learned merchants

  @override
  void dispose() {
    _storeNameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _scanState = _ScanState.scanning;
        _imagePath = pickedFile.path;
        _errorMessage = null;
      });

      await _scanReceipt(pickedFile.path);
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied' || e.code == 'photo_access_denied') {
        _showPermissionDenied(source);
      } else {
        setState(() {
          _scanState = _ScanState.idle;
          _errorMessage = 'Could not access ${source == ImageSource.camera ? 'camera' : 'photos'}.';
        });
      }
    } catch (e) {
      setState(() {
        _scanState = _ScanState.idle;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  void _showPermissionDenied(ImageSource source) {
    final label = source == ImageSource.camera ? 'camera' : 'photo library';
    setState(() {
      _scanState = _ScanState.idle;
      _errorMessage = 'Please allow access to your $label in Settings to scan receipts.';
    });
  }

  Future<void> _scanReceipt(String path) async {
    try {
      final receipt = await ReceiptScannerService.instance.scan(path);

      if (receipt.rawText.isEmpty) {
        setState(() {
          _scanState = _ScanState.idle;
          _errorMessage = 'Could not read the receipt. Try better lighting or a clearer photo.';
        });
        return;
      }

      // Pre-fill form fields
      _storeNameController.text = receipt.storeName ?? '';
      if (receipt.totalAmount != null) {
        _amountController.text = receipt.totalAmount!.toStringAsFixed(2);
      } else {
        _amountController.text = '';
      }

      // Build note from receipt data
      final noteParts = <String>[];
      switch (receipt.receiptType) {
        case ReceiptType.atmWithdrawal:
          noteParts.add('ATM Withdrawal');
          if (receipt.bankName != null) noteParts.add(receipt.bankName!);
          if (receipt.maskedCardNumber != null) noteParts.add('Card: ${receipt.maskedCardNumber}');
        case ReceiptType.bankTransfer:
          noteParts.add(receipt.transferType ?? 'Fund Transfer');
          if (receipt.sourceAccount != null) noteParts.add('From: ${receipt.sourceAccount}');
          if (receipt.destinationAccount != null) noteParts.add('To: ${receipt.destinationAccount}');
        case ReceiptType.billPayment:
          noteParts.add('Bill Payment');
          if (receipt.billerName != null) noteParts.add(receipt.billerName!);
          if (receipt.accountNumber != null) noteParts.add('Acct: ${receipt.accountNumber}');
        case ReceiptType.digitalWallet:
          noteParts.add(receipt.walletName ?? 'Digital Wallet');
          if (receipt.walletAction != null) {
            switch (receipt.walletAction!) {
              case DigitalWalletAction.cashIn:
                noteParts.add('Cash In');
              case DigitalWalletAction.cashOut:
                noteParts.add('Cash Out');
              case DigitalWalletAction.sendMoney:
                noteParts.add('Send Money');
              case DigitalWalletAction.payQr:
                noteParts.add('QR Payment');
              case DigitalWalletAction.unknown:
                break;
            }
          }
          if (receipt.merchantName != null) noteParts.add(receipt.merchantName!);
        case ReceiptType.purchase:
        case ReceiptType.unknown:
          if (receipt.storeName != null) noteParts.add(receipt.storeName!);
          if (receipt.items.isNotEmpty) {
            final itemSummary = receipt.items
                .take(5)
                .map((i) => i.name)
                .join(', ');
            noteParts.add(itemSummary);
          }
      }
      _noteController.text = noteParts.join(' - ');

      // Set date
      _date = receipt.date ?? DateTime.now();

      // Match category from merchant database (for purchases/bills)
      if (receipt.receiptType == ReceiptType.purchase ||
          receipt.receiptType == ReceiptType.unknown) {
        String matchedCategory = 'Other';
        if (receipt.storeName != null) {
          final learned = await LearnedMerchants.matchWithLearned(receipt.storeName!);
          if (learned != null) {
            matchedCategory = learned;
          }
        }
        _category = matchedCategory;
        _originalCategory = matchedCategory;
      } else if (receipt.receiptType == ReceiptType.billPayment) {
        _category = 'Housing'; // Utilities are under Housing
        _originalCategory = 'Housing';
      } else {
        _category = 'Transfer';
        _originalCategory = 'Transfer';
      }

      setState(() {
        _receipt = receipt;
        _scanState = _ScanState.review;
      });
    } catch (e) {
      setState(() {
        _scanState = _ScanState.idle;
        _errorMessage = 'Could not read the receipt. Try better lighting or a clearer photo.';
      });
    }
  }

  void _showError(String message) {
    showAppSnackBar(context, message, isError: true);
  }

  bool get _isTransferReceipt {
    if (_receipt == null) return false;
    final type = _receipt!.receiptType;
    if (type == ReceiptType.atmWithdrawal || type == ReceiptType.bankTransfer) {
      return true;
    }
    if (type == ReceiptType.digitalWallet) {
      final action = _receipt!.walletAction;
      return action == DigitalWalletAction.cashIn ||
          action == DigitalWalletAction.cashOut;
    }
    return false;
  }

  Future<void> _handleSave() async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];

    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Enter a valid amount');
      return;
    }

    if (amount > 999999999) {
      _showError('Amount must be less than \u20B1999,999,999');
      return;
    }

    if (_selectedAccountId == null) {
      _showError('Select an account');
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(transactionRepositoryProvider);

      if (_isTransferReceipt && _selectedDestAccountId != null) {
        // Create transfer: deduct from source, add to destination
        final description = InputSanitizer.sanitize(_noteController.text);

        // Deduct from source
        await repo.createTransaction(
          amount: -amount,
          category: 'Transfer',
          description: description,
          date: _date,
          accountId: _selectedAccountId,
          tags: ['receipt-scan', 'transfer'],
        );

        // Add to destination
        await repo.createTransaction(
          amount: amount,
          category: 'Transfer',
          description: description,
          date: _date,
          accountId: _selectedDestAccountId,
          tags: ['receipt-scan', 'transfer'],
        );

        if (mounted) {
          showSuccessSnackBar(context, 'Transfer recorded from receipt!');
          Navigator.of(context).pop(true);
        }
      } else {
        // Regular expense
        // Insufficient balance check (non-credit-card)
        final selectedAccount = accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
        if (selectedAccount != null && selectedAccount.type != 'credit_card' && amount > selectedAccount.balance) {
          setState(() => _saving = false);
          _showError('Insufficient balance in ${selectedAccount.name}');
          return;
        }

        await repo.createTransaction(
          amount: -amount,
          category: _category,
          description: InputSanitizer.sanitize(_noteController.text),
          date: _date,
          accountId: _selectedAccountId,
          tags: ['receipt-scan'],
        );

        // Learn merchant correction if user changed the category
        if (_category != _originalCategory && _storeNameController.text.trim().isNotEmpty) {
          await LearnedMerchants.learn(_storeNameController.text.trim(), _category);
        }

        if (mounted) {
          showSuccessSnackBar(context, 'Expense added from receipt!');
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      setState(() => _saving = false);
      showAppSnackBar(context, 'Failed to save: $e', isError: true);
    }
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
      default: return LucideIcons.moreHorizontal;
    }
  }

  IconData _receiptTypeIcon(ReceiptType type) {
    switch (type) {
      case ReceiptType.purchase: return LucideIcons.shoppingBag;
      case ReceiptType.atmWithdrawal: return LucideIcons.banknote;
      case ReceiptType.bankTransfer: return LucideIcons.arrowLeftRight;
      case ReceiptType.billPayment: return LucideIcons.fileText;
      case ReceiptType.digitalWallet: return LucideIcons.smartphone;
      case ReceiptType.unknown: return LucideIcons.scanLine;
    }
  }

  Color _receiptTypeBadgeColor(ReceiptType type, ColorScheme cs) {
    switch (type) {
      case ReceiptType.purchase: return cs.primary;
      case ReceiptType.atmWithdrawal: return Colors.orange;
      case ReceiptType.bankTransfer: return Colors.blue;
      case ReceiptType.billPayment: return Colors.purple;
      case ReceiptType.digitalWallet: return Colors.teal;
      case ReceiptType.unknown: return cs.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
                color: cs.outline.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2)),
            )),

            // Header
            Row(children: [
              const Text('Scan Receipt',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_scanState == _ScanState.review)
                GestureDetector(
                  onTap: () => setState(() {
                    _scanState = _ScanState.idle;
                    _receipt = null;
                    _imagePath = null;
                    _errorMessage = null;
                    _selectedDestAccountId = null;
                  }),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(LucideIcons.refreshCw, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Text('Rescan', style: TextStyle(fontSize: 13, color: cs.primary, fontWeight: FontWeight.w500)),
                  ]),
                ),
            ]),
            const SizedBox(height: 4),

            // Receipt type badge
            if (_scanState == _ScanState.review && _receipt != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _receiptTypeBadgeColor(_receipt!.receiptType, cs).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_receiptTypeIcon(_receipt!.receiptType), size: 12,
                      color: _receiptTypeBadgeColor(_receipt!.receiptType, cs)),
                  const SizedBox(width: 4),
                  Text(
                    ReceiptParser.receiptTypeLabel(_receipt!.receiptType),
                    style: TextStyle(fontSize: 11,
                        color: _receiptTypeBadgeColor(_receipt!.receiptType, cs),
                        fontWeight: FontWeight.w500),
                  ),
                ]),
              ),

            if (_scanState == _ScanState.idle) _buildPickerUI(cs),
            if (_scanState == _ScanState.scanning) _buildScanningUI(cs),
            if (_scanState == _ScanState.review) _buildReviewForm(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerUI(ColorScheme cs) {
    return Column(children: [
      const SizedBox(height: 24),

      // Error message
      if (_errorMessage != null) ...[
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.error.withOpacity(0.2)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(LucideIcons.alertCircle, size: 16, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(child: Text(_errorMessage!,
                style: TextStyle(fontSize: 13, color: AppColors.error, height: 1.3))),
          ]),
        ),
      ],

      // Illustration
      Icon(LucideIcons.scanLine, size: 56, color: cs.onSurfaceVariant.withOpacity(0.3)),
      const SizedBox(height: 16),
      Text('Scan a receipt to add a transaction',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: cs.onSurface)),
      const SizedBox(height: 6),
      Text('Purchases, ATM, transfers, bills, GCash & more',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
      const SizedBox(height: 32),

      // Camera button
      FilledButton.icon(
        onPressed: () => _pickImage(ImageSource.camera),
        icon: const Icon(LucideIcons.camera, size: 18),
        label: const Text('Take Photo'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(height: 10),

      // Gallery button
      OutlinedButton.icon(
        onPressed: () => _pickImage(ImageSource.gallery),
        icon: const Icon(LucideIcons.image, size: 18),
        label: const Text('Pick from Gallery'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(height: 32),
    ]);
  }

  Widget _buildScanningUI(ColorScheme cs) {
    return Column(children: [
      const SizedBox(height: 48),

      // Receipt thumbnail
      if (_imagePath != null)
        Container(
          height: 160,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withOpacity(0.15)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(
            File(_imagePath!),
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),

      const SizedBox(height: 16),
      SizedBox(
        width: 24, height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
      ),
      const SizedBox(height: 16),
      Text('Scanning receipt...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: cs.onSurface)),
      const SizedBox(height: 6),
      Text('Reading text from the image', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
      const SizedBox(height: 48),
    ]);
  }

  Widget _buildReviewForm(ColorScheme cs) {
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];

    // Auto-select first account
    if (_selectedAccountId == null && accounts.isNotEmpty && !_autoSelected) {
      _autoSelected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedAccountId = accounts.first.id);
      });
    }

    final selectedAccount = accounts.where((a) => a.id == _selectedAccountId).firstOrNull;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Receipt thumbnail (tappable)
      if (_imagePath != null)
        GestureDetector(
          onTap: () => _showFullImage(cs),
          child: Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outline.withOpacity(0.15)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              Image.file(
                File(_imagePath!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: 100,
              ),
              Positioned(
                right: 8, bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(LucideIcons.maximize2, size: 10, color: Colors.white),
                    SizedBox(width: 4),
                    Text('View', style: TextStyle(fontSize: 10, color: Colors.white)),
                  ]),
                ),
              ),
            ]),
          ),
        ),

      // ATM/Transfer details card
      if (_receipt != null && _isTransferReceipt)
        _buildTransferDetails(cs),

      // Bill payment details
      if (_receipt != null && _receipt!.receiptType == ReceiptType.billPayment)
        _buildBillDetails(cs),

      // No accounts
      if (accounts.isEmpty) ...[
        const SizedBox(height: 16),
        Center(child: Column(children: [
          Icon(LucideIcons.wallet, size: 40, color: cs.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text('Create an account first',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 6),
          Text('You need at least one account to add transactions.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddAccountDialog(),
              );
            },
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Create Account'),
          ),
        ])),
      ] else ...[

      // Store name (for purchases)
      if (!_isTransferReceipt) ...[
        _FieldLabel(
          label: 'Store Name',
          detected: _receipt?.storeName != null,
          notDetected: _receipt?.storeName == null,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _storeNameController,
          decoration: InputDecoration(
            hintText: 'Could not detect store name',
            hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withOpacity(0.4)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _receipt?.storeName != null
                  ? cs.primary.withOpacity(0.3)
                  : cs.outline.withOpacity(0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _receipt?.storeName != null
                  ? cs.primary.withOpacity(0.3)
                  : cs.outline.withOpacity(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.primary),
            ),
          ),
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 14),
      ],

      // Amount
      _FieldLabel(
        label: 'Amount',
        detected: _receipt?.totalAmount != null,
        notDetected: _receipt?.totalAmount == null,
      ),
      const SizedBox(height: 6),
      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Text('\u20B1', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant)),
        const SizedBox(width: 4),
        Expanded(
          child: TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              _ThousandsSeparatorFormatter(),
            ],
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant.withOpacity(0.3)),
              border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ]),
      if (_receipt?.totalAmount == null || _receipt?.totalAmount == 0)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Icon(LucideIcons.alertTriangle, size: 14, color: cs.error),
            const SizedBox(width: 4),
            Text(
              'Amount not detected — please enter it manually',
              style: TextStyle(fontSize: 12, color: cs.error),
            ),
          ]),
        ),
      const SizedBox(height: 14),

      // Source account selector
      Text(_isTransferReceipt ? 'From Account' : 'Account',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      const SizedBox(height: 6),
      _buildAccountSelector(
        cs: cs,
        accounts: accounts,
        selectedId: _selectedAccountId,
        selectedAccount: selectedAccount,
        onSelected: (id) => setState(() => _selectedAccountId = id),
      ),
      const SizedBox(height: 14),

      // Destination account (for transfers)
      if (_isTransferReceipt) ...[
        Text('To Account', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 6),
        _buildAccountSelector(
          cs: cs,
          accounts: accounts,
          selectedId: _selectedDestAccountId,
          selectedAccount: accounts.where((a) => a.id == _selectedDestAccountId).firstOrNull,
          onSelected: (id) => setState(() => _selectedDestAccountId = id),
          hintText: 'Select destination account',
        ),
        const SizedBox(height: 14),
      ],

      // Date
      _FieldLabel(
        label: 'Date',
        detected: _receipt?.date != null,
        notDetected: _receipt?.date == null,
      ),
      const SizedBox(height: 6),
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
            border: Border.all(color: _receipt?.date != null
                ? cs.primary.withOpacity(0.3)
                : cs.outline.withOpacity(0.15)),
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
      const SizedBox(height: 14),

      // Category (only for non-transfer receipts)
      if (!_isTransferReceipt) ...[
        Text('Category', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 4, children: kExpenseCategories.map((c) {
          final selected = _category == c;
          return GestureDetector(
            onTap: () => setState(() => _category = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? cs.primary.withOpacity(0.1) : Colors.transparent,
                border: Border.all(color: selected ? cs.primary : cs.outline.withOpacity(0.15)),
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
        const SizedBox(height: 14),
      ],

      // Note
      Text('Note', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      const SizedBox(height: 6),
      TextField(
        controller: _noteController,
        maxLength: 500,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: 'Add a note... (optional)',
          hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withOpacity(0.4)),
          border: InputBorder.none, contentPadding: EdgeInsets.zero,
          counterText: '',
        ),
        style: const TextStyle(fontSize: 13),
      ),
      Divider(color: cs.outline.withOpacity(0.10)),
      const SizedBox(height: 12),

      // Submit button
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _saving ? null : _handleSave,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _saving
              ? const SizedBox(height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_isTransferReceipt ? 'Record Transfer' : 'Add as Expense',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
      const SizedBox(height: 16), // Bottom safe area
      ], // end else (has accounts)
    ]);
  }

  Widget _buildAccountSelector({
    required ColorScheme cs,
    required List accounts,
    required String? selectedId,
    required dynamic selectedAccount,
    required void Function(String) onSelected,
    String hintText = 'Select account',
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (_) => accounts.map<PopupMenuEntry<String>>((a) => PopupMenuItem(
        value: a.id,
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(a.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.08),
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
          if (a.id == selectedId) ...[
            const SizedBox(width: 8),
            Icon(Icons.check, size: 16, color: cs.primary),
          ],
        ]),
      )).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(selectedAccount?.name ?? hintText,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          if (selectedAccount != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.08),
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
    );
  }

  Widget _buildTransferDetails(ColorScheme cs) {
    final receipt = _receipt!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.arrowLeftRight, size: 14, color: Colors.blue),
          const SizedBox(width: 6),
          Text('Transfer Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue)),
        ]),
        const SizedBox(height: 8),
        if (receipt.receiptType == ReceiptType.atmWithdrawal) ...[
          if (receipt.bankName != null)
            _detailRow('Bank', receipt.bankName!, cs),
          if (receipt.maskedCardNumber != null)
            _detailRow('Card', receipt.maskedCardNumber!, cs),
          if (receipt.availableBalance != null)
            _detailRow('Remaining', '\u20B1${receipt.availableBalance!.toStringAsFixed(2)}', cs),
        ],
        if (receipt.receiptType == ReceiptType.bankTransfer) ...[
          if (receipt.transferType != null)
            _detailRow('Type', receipt.transferType!, cs),
          if (receipt.sourceAccount != null)
            _detailRow('From', receipt.sourceAccount!, cs),
          if (receipt.destinationAccount != null)
            _detailRow('To', receipt.destinationAccount!, cs),
        ],
        if (receipt.receiptType == ReceiptType.digitalWallet) ...[
          if (receipt.walletName != null)
            _detailRow('Wallet', receipt.walletName!, cs),
          if (receipt.walletAction != null)
            _detailRow('Action', _walletActionLabel(receipt.walletAction!), cs),
        ],
      ]),
    );
  }

  Widget _buildBillDetails(ColorScheme cs) {
    final receipt = _receipt!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.fileText, size: 14, color: Colors.purple),
          const SizedBox(width: 6),
          Text('Bill Payment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.purple)),
        ]),
        const SizedBox(height: 8),
        if (receipt.billerName != null)
          _detailRow('Biller', receipt.billerName!, cs),
        if (receipt.accountNumber != null)
          _detailRow('Account', receipt.accountNumber!, cs),
      ]),
    );
  }

  Widget _detailRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))),
        Expanded(child: Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  String _walletActionLabel(DigitalWalletAction action) {
    switch (action) {
      case DigitalWalletAction.cashIn: return 'Cash In';
      case DigitalWalletAction.cashOut: return 'Cash Out';
      case DigitalWalletAction.sendMoney: return 'Send Money';
      case DigitalWalletAction.payQr: return 'QR Payment';
      case DigitalWalletAction.unknown: return 'Transaction';
    }
  }

  void _showFullImage(ColorScheme cs) {
    if (_imagePath == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(children: [
          InteractiveViewer(
            child: Image.file(File(_imagePath!), fit: BoxFit.contain),
          ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.x, size: 18, color: Colors.white),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Label widget showing detection status for a field.
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool detected;
  final bool notDetected;

  const _FieldLabel({
    required this.label,
    this.detected = false,
    this.notDetected = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      if (detected) ...[
        const SizedBox(width: 6),
        Icon(LucideIcons.checkCircle, size: 12, color: cs.primary),
        const SizedBox(width: 2),
        Text('auto-detected', style: TextStyle(fontSize: 10, color: cs.primary)),
      ],
      if (notDetected) ...[
        const SizedBox(width: 6),
        Icon(LucideIcons.alertCircle, size: 12, color: cs.onSurfaceVariant.withOpacity(0.5)),
        const SizedBox(width: 2),
        Text('not detected', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withOpacity(0.5))),
      ],
    ]);
  }
}
