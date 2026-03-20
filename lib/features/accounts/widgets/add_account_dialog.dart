import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/account_types.dart';
import '../providers/account_providers.dart';

class AddAccountDialog extends ConsumerStatefulWidget {
  const AddAccountDialog({super.key});

  @override
  ConsumerState<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<AddAccountDialog> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _type = 'bank';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter an account name.');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      final balance = double.tryParse(_balanceController.text.replaceAll(',', '')) ?? 0;
      await ref.read(accountRepositoryProvider).createAccount(
        name: name,
        type: _type,
        balance: balance,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() { _saving = false; _error = 'Failed to create account.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Add Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(LucideIcons.x, size: 20)),
          ]),
          const SizedBox(height: 12),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error)),
            ),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Account Name', hintText: 'e.g., BDO, GCash'),
            autofocus: true,
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: kAccountTypes.map((t) => DropdownMenuItem(value: t.value, child: Text(t.label))).toList(),
            onChanged: (v) => setState(() => _type = v ?? 'bank'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,\-]'))],
            decoration: const InputDecoration(labelText: 'Opening Balance', prefixText: '₱ '),
          ),
          const SizedBox(height: 16),

          // Quick presets
          Wrap(spacing: 8, runSpacing: 8, children: kCommonAccounts.map((preset) {
            return GestureDetector(
              onTap: () {
                _nameController.text = preset.name;
                setState(() => _type = preset.type);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(preset.name, style: const TextStyle(fontSize: 12)),
              ),
            );
          }).toList()),
          const SizedBox(height: 16),

          FilledButton(
            onPressed: _saving ? null : _handleSave,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create Account'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
