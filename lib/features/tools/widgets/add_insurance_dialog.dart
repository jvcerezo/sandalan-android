import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/color_tokens.dart';
import '../../accounts/providers/account_providers.dart';
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

class AddInsuranceDialog extends ConsumerStatefulWidget {
  const AddInsuranceDialog({super.key});
  @override
  ConsumerState<AddInsuranceDialog> createState() => _AddInsuranceDialogState();
}

class _AddInsuranceDialogState extends ConsumerState<AddInsuranceDialog> {
  final _nameCtl = TextEditingController();
  final _premiumCtl = TextEditingController();
  final _coverageCtl = TextEditingController();
  final _providerCtl = TextEditingController();
  final _policyNumCtl = TextEditingController();
  String _type = 'life';
  String _frequency = 'annual';
  DateTime? _renewalDate;
  String? _accountId;
  bool _saving = false;

  static const _types = {
    'life': 'Life',
    'health': 'Health/HMO',
    'ctpl': 'Car (CTPL)',
    'car': 'Car (Comprehensive)',
    'property': 'Property',
    'other': 'Other',
  };

  static const _frequencies = {
    'monthly': 'Monthly',
    'quarterly': 'Quarterly',
    'semi_annual': 'Semi-Annual',
    'annual': 'Annual',
  };

  @override
  void dispose() {
    _nameCtl.dispose();
    _premiumCtl.dispose();
    _coverageCtl.dispose();
    _providerCtl.dispose();
    _policyNumCtl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) {
      _showError('Policy name is required');
      return;
    }
    final premium = double.tryParse(_premiumCtl.text.replaceAll(',', ''));
    if (premium == null || premium <= 0) {
      _showError('Annual premium must be greater than 0');
      return;
    }
    final coverage = double.tryParse(_coverageCtl.text.replaceAll(',', ''));
    if (coverage != null && coverage < 0) {
      _showError('Coverage amount cannot be negative');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(insuranceRepositoryProvider).createPolicy({
        'name': name,
        'type': _type,
        'premium_amount': premium,
        'premium_frequency': _frequency,
        'coverage_amount': coverage,
        'provider': _providerCtl.text.trim().isEmpty ? null : _providerCtl.text.trim(),
        'policy_number': _policyNumCtl.text.trim().isEmpty ? null : _policyNumCtl.text.trim(),
        'renewal_date': _renewalDate?.toIso8601String().substring(0, 10),
        'account_id': _accountId,
        'is_active': true,
      });
      ref.invalidate(insurancePoliciesProvider);
      ref.invalidate(insuranceSummaryProvider);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Policy added successfully')),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      _showError('Failed to save: $e');
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
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
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

            const Text('Add Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Policy Name
            _label('Policy Name *'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtl,
              maxLength: 100,
              decoration: _inputDecoration(cs, 'e.g. Sun Life VUL'),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Type chips
            _label('Type'),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: _types.entries.map((e) {
              final selected = _type == e.key;
              return GestureDetector(
                onTap: () => setState(() => _type = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
                    border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: selected ? cs.primary : cs.onSurfaceVariant)),
                ),
              );
            }).toList()),
            const SizedBox(height: 12),

            // Annual Premium
            _label('Premium Amount *'),
            const SizedBox(height: 6),
            _amountField(cs, _premiumCtl, 'Premium amount'),
            const SizedBox(height: 12),

            // Coverage Amount
            _label('Coverage Amount'),
            const SizedBox(height: 6),
            _amountField(cs, _coverageCtl, '0'),
            const SizedBox(height: 12),

            // Provider
            _label('Provider (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _providerCtl,
              maxLength: 100,
              decoration: _inputDecoration(cs, 'e.g. Sun Life, AXA'),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Policy Number
            _label('Policy Number (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _policyNumCtl,
              maxLength: 50,
              decoration: _inputDecoration(cs, 'e.g. POL-123456'),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Payment Frequency
            _label('Payment Frequency'),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: _frequencies.entries.map((e) {
              final selected = _frequency == e.key;
              return GestureDetector(
                onTap: () => setState(() => _frequency = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
                    border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: selected ? cs.primary : cs.onSurfaceVariant)),
                ),
              );
            }).toList()),
            const SizedBox(height: 12),

            // Renewal Date
            _label('Renewal Date'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _renewalDate ?? DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setState(() => _renewalDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Expanded(child: Text(
                    _renewalDate != null
                        ? '${_renewalDate!.month.toString().padLeft(2, '0')}/${_renewalDate!.day.toString().padLeft(2, '0')}/${_renewalDate!.year}'
                        : 'Select date',
                    style: TextStyle(fontSize: 13,
                        color: _renewalDate != null ? cs.onSurface : cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  )),
                  Icon(LucideIcons.calendar, size: 14, color: cs.onSurfaceVariant),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // Linked Account
            _label('Linked Account (optional)'),
            const SizedBox(height: 6),
            _accountDropdown(cs, accounts),
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
                  : const Text('Add Policy'),
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
    hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
    isDense: true,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.15))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.15))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.primary)),
  );

  Widget _amountField(ColorScheme cs, TextEditingController ctl, String hint) {
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
          controller: ctl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            _ThousandsSeparatorFormatter(),
          ],
          decoration: InputDecoration(
            hintText: hint, isDense: true,
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
          border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
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
