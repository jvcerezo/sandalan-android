import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/categories.dart';
import '../providers/goal_providers.dart';

class AddGoalDialog extends ConsumerStatefulWidget {
  const AddGoalDialog({super.key});

  @override
  ConsumerState<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends ConsumerState<AddGoalDialog> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  String _category = kGoalCategories.first;
  DateTime? _deadline;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final target = double.tryParse(_targetController.text.replaceAll(',', ''));
    if (name.isEmpty || target == null || target <= 0) return;

    setState(() => _saving = true);
    try {
      await ref.read(goalRepositoryProvider).createGoal(
        name: name,
        targetAmount: target,
        category: _category,
        deadline: _deadline,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Add Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(LucideIcons.x, size: 20)),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Goal Name', hintText: 'e.g., Emergency Fund'),
          autofocus: true,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _targetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
          decoration: const InputDecoration(labelText: 'Target Amount', prefixText: '₱ '),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _category,
          decoration: const InputDecoration(labelText: 'Category'),
          items: kGoalCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _category = v ?? kGoalCategories.first),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(LucideIcons.calendar, size: 20),
          title: Text(_deadline != null
              ? '${_deadline!.month}/${_deadline!.day}/${_deadline!.year}'
              : 'Set deadline (optional)'),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 90)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (picked != null) setState(() => _deadline = picked);
          },
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _handleSave,
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _saving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create Goal'),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}
