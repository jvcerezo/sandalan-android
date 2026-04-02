import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/investment.dart';
import '../../../core/utils/input_validator.dart';
import '../../../data/repositories/local_investment_repository.dart';
import '../../../core/services/milestone_service.dart';
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

const _types = [
  ('mp2', 'MP2'),
  ('uitf', 'UITF'),
  ('mutual_fund', 'Mutual Fund'),
  ('stocks', 'Stocks'),
  ('bonds', 'Bonds/RTB'),
  ('time_deposit', 'Time Deposit'),
  ('digital', 'Digital'),
  ('crypto', 'Crypto'),
  ('real_estate', 'Real Estate'),
  ('other', 'Other'),
];

class AddInvestmentDialog extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const AddInvestmentDialog({super.key, required this.onSaved});

  @override
  ConsumerState<AddInvestmentDialog> createState() => _State();
}

class _State extends ConsumerState<AddInvestmentDialog> {
  String _type = 'mp2';
  final _nameCtl = TextEditingController();
  final _amountCtl = TextEditingController();
  final _valueCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  final _navpuCtl = TextEditingController();
  final _unitsCtl = TextEditingController();
  final _rateCtl = TextEditingController();
  DateTime _dateStarted = DateTime.now();
  DateTime? _maturityDate;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtl.dispose(); _amountCtl.dispose(); _valueCtl.dispose();
    _notesCtl.dispose(); _navpuCtl.dispose(); _unitsCtl.dispose();
    _rateCtl.dispose();
    super.dispose();
  }

  bool get _isUitfType => _type == 'uitf' || _type == 'mutual_fund';
  bool get _isBondType => _type == 'bonds' || _type == 'time_deposit';

  Future<void> _save() async {
    final name = InputValidator.name(_nameCtl.text);
    final amount = InputValidator.positiveAmount(_amountCtl.text.replaceAll(',', ''));
    final value = InputValidator.positiveAmount(
        _valueCtl.text.replaceAll(',', '').isEmpty ? amount : _valueCtl.text.replaceAll(',', ''));
    if (name.isEmpty || amount <= 0) {
      showAppSnackBar(context, 'Name and amount are required', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = LocalInvestmentRepository(
          AppDatabase.instance, Supabase.instance.client);
      final now = DateTime.now();
      final notes = InputValidator.description(_notesCtl.text);
      final navpu = InputValidator.provider(_navpuCtl.text);
      final units = double.tryParse(_unitsCtl.text);
      final rate = InputValidator.interestRate(_rateCtl.text);
      await repo.createInvestment(Investment(
        id: const Uuid().v4(), userId: Supabase.instance.client.auth.currentUser?.id ?? 'guest',
        name: name, type: _type, amountInvested: amount, currentValue: value,
        dateStarted: _dateStarted, notes: notes.isEmpty ? null : notes,
        navpu: navpu.isEmpty ? null : navpu,
        units: units != null && units.isFinite ? units : null,
        interestRate: rate > 0 ? rate : null,
        maturityDate: _maturityDate,
        createdAt: now, updatedAt: now,
      ));
      widget.onSaved();
      MilestoneService.checkAndTrigger('first_investment');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      showAppSnackBar(context, 'Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: keyboardHeight > 0 ? 0.95 : 0.9, maxChildSize: 0.95, minChildSize: 0.0,
      snap: true, snapSizes: const [0.0, 0.9],
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView(controller: ctrl, padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardHeight), children: [
          Center(child: Container(width: 32, height: 4, margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: cs.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)))),
          const Text('Add Investment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Type chips
          Text('Type', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: _types.map((t) {
            final sel = _type == t.$1;
            return GestureDetector(
              onTap: () => setState(() => _type = t.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? cs.primary : cs.outline.withOpacity(0.3)),
                ),
                child: Text(t.$2, style: TextStyle(fontSize: 12,
                    color: sel ? cs.onPrimary : cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
              ),
            );
          }).toList()),
          const SizedBox(height: 12),

          TextField(controller: _nameCtl, decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words, maxLength: 100),
          const SizedBox(height: 8),
          TextField(controller: _amountCtl, decoration: const InputDecoration(labelText: 'Amount Invested (₱)', prefixText: '₱ ', counterText: ''),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              maxLength: 12, maxLengthEnforcement: MaxLengthEnforcement.enforced,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')), _ThousandsSeparatorFormatter()]),
          const SizedBox(height: 8),
          TextField(controller: _valueCtl, decoration: const InputDecoration(labelText: 'Current Value (₱)', prefixText: '₱ ', hintText: 'Optional', counterText: ''),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              maxLength: 12, maxLengthEnforcement: MaxLengthEnforcement.enforced,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')), _ThousandsSeparatorFormatter()]),
          const SizedBox(height: 8),

          // Date started
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: context,
                  initialDate: _dateStarted, firstDate: DateTime(2000), lastDate: DateTime.now());
              if (d != null) setState(() => _dateStarted = d);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date Started'),
              child: Text('${_dateStarted.month}/${_dateStarted.day}/${_dateStarted.year}'),
            ),
          ),
          const SizedBox(height: 8),

          // Conditional fields
          if (_isUitfType) ...[
            Row(children: [
              Expanded(child: TextField(controller: _navpuCtl,
                  decoration: const InputDecoration(labelText: 'NAVPU'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _unitsCtl,
                  decoration: const InputDecoration(labelText: 'Units Held'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true))),
            ]),
            const SizedBox(height: 8),
          ],
          if (_isBondType) ...[
            Row(children: [
              Expanded(child: TextField(controller: _rateCtl,
                  decoration: const InputDecoration(labelText: 'Interest Rate %'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(context: context,
                      initialDate: DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(), lastDate: DateTime(2060));
                  if (d != null) setState(() => _maturityDate = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Maturity Date'),
                  child: Text(_maturityDate != null
                      ? '${_maturityDate!.month}/${_maturityDate!.day}/${_maturityDate!.year}'
                      : 'Select'),
                ),
              )),
            ]),
            const SizedBox(height: 8),
          ],

          TextField(controller: _notesCtl, decoration: const InputDecoration(labelText: 'Notes', hintText: 'Optional'),
              maxLines: 2, maxLength: 500),
          const SizedBox(height: 16),

          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Add Investment'),
          ),
        ]),
      ),
    );
  }
}
