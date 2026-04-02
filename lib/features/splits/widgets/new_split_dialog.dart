import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/id_generator.dart' show IdGenerator;
import '../../../core/utils/input_validator.dart';
import '../../../core/services/milestone_service.dart';
import '../../../data/models/bill_split.dart';

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

/// Shows a full-screen dialog to create a new bill split.
/// Returns the created BillSplit or null if cancelled.
Future<BillSplit?> showNewSplitDialog(BuildContext context, String userId) {
  return showModalBottomSheet<BillSplit>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _NewSplitSheet(userId: userId),
  );
}

class _NewSplitSheet extends StatefulWidget {
  final String userId;
  const _NewSplitSheet({required this.userId});

  @override
  State<_NewSplitSheet> createState() => _NewSplitSheetState();
}

class _NewSplitSheetState extends State<_NewSplitSheet> {
  final _amountCtl = TextEditingController();
  final _descCtl = TextEditingController();
  String _method = 'equal';
  final List<_ParticipantEntry> _participants = [
    _ParticipantEntry(name: 'You', controller: TextEditingController()),
    _ParticipantEntry(name: '', controller: TextEditingController()),
  ];

  @override
  void dispose() {
    _amountCtl.dispose();
    _descCtl.dispose();
    for (final p in _participants) {
      p.controller.dispose();
    }
    super.dispose();
  }

  void _addPerson() {
    setState(() {
      _participants.add(_ParticipantEntry(name: '', controller: TextEditingController()));
    });
  }

  void _removePerson(int index) {
    if (_participants.length <= 2) return;
    if (index == 0) return; // Can't remove "You"
    setState(() {
      _participants[index].controller.dispose();
      _participants.removeAt(index);
    });
  }

  void _recalculateEqual() {
    final total = double.tryParse(_amountCtl.text.replaceAll(',', '')) ?? 0;
    if (total <= 0 || _participants.isEmpty) return;
    final share = total / _participants.length;
    for (final p in _participants) {
      p.controller.text = share.toStringAsFixed(0);
    }
  }

  void _create() {
    final total = InputValidator.positiveAmount(_amountCtl.text);
    final desc = InputValidator.description(_descCtl.text);
    if (total <= 0 || desc.isEmpty) return;

    final participants = <SplitParticipant>[];
    for (int i = 0; i < _participants.length; i++) {
      final rawName = i == 0 ? 'You' : _participants[i].nameCtl?.text.trim() ?? _participants[i].name;
      final name = InputValidator.name(rawName);
      if (name.isEmpty) continue;
      final share = _method == 'equal'
          ? total / _participants.length
          : InputValidator.positiveAmount(_participants[i].controller.text);
      participants.add(SplitParticipant(
        name: name,
        share: share,
        isPaid: i == 0, // "You" always marked as paid
      ));
    }

    if (participants.length < 2) return;

    final split = BillSplit(
      id: IdGenerator.generate(),
      userId: widget.userId,
      description: desc,
      totalAmount: total,
      splitMethod: _method,
      participants: participants,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    MilestoneService.checkAndTrigger('first_split');
    Navigator.of(context).pop(split);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Drag handle
            Center(child: Container(
              width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            )),

            Row(children: [
              const Text('New Split', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(LucideIcons.x, size: 20, color: colorScheme.onSurfaceVariant),
              ),
            ]),
            const SizedBox(height: 16),

            // Total amount
            TextField(
              controller: _amountCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                _ThousandsSeparatorFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Total Amount',
                prefixText: '\u20b1 ',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) { if (_method == 'equal') _recalculateEqual(); },
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descCtl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Dinner at Jollibee',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Split method toggle
            Row(children: [
              const Text('Split method:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Equal', style: TextStyle(fontSize: 12)),
                selected: _method == 'equal',
                onSelected: (_) {
                  setState(() => _method = 'equal');
                  _recalculateEqual();
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Custom', style: TextStyle(fontSize: 12)),
                selected: _method == 'custom',
                onSelected: (_) => setState(() => _method = 'custom'),
              ),
            ]),
            const SizedBox(height: 16),

            // Participants
            Row(children: [
              const Text('Participants', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: _addPerson,
                icon: const Icon(LucideIcons.userPlus, size: 14),
                label: const Text('Add person', style: TextStyle(fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 8),

            for (var i = 0; i < _participants.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(
                    flex: 3,
                    child: i == 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('You', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          )
                        : TextField(
                            controller: _participants[i].nameCtl ??= TextEditingController(text: _participants[i].name),
                            decoration: InputDecoration(
                              hintText: 'Name',
                              isDense: true,
                              border: const OutlineInputBorder(),
                              suffixIcon: _participants.length > 2
                                  ? GestureDetector(
                                      onTap: () => _removePerson(i),
                                      child: Icon(LucideIcons.x, size: 14, color: colorScheme.onSurfaceVariant),
                                    )
                                  : null,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  if (_method == 'custom')
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _participants[i].controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                          _ThousandsSeparatorFormatter(),
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Amount',
                          prefixText: '\u20b1 ',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _participants[i].controller.text.isNotEmpty
                              ? '\u20b1${_participants[i].controller.text}'
                              : '\u20b10',
                          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                ]),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _create,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Create Split'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ParticipantEntry {
  String name;
  TextEditingController controller;
  TextEditingController? nameCtl;

  _ParticipantEntry({required this.name, required this.controller, this.nameCtl});
}
