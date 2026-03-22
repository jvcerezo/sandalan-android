import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/id_generator.dart' show IdGenerator;
import '../../../data/models/expense_template.dart';
import 'quick_add_strip.dart';

/// Shows a bottom sheet to manage expense templates.
void showManageTemplatesSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ManageTemplatesSheet(ref: ref),
  );
}

class _ManageTemplatesSheet extends StatefulWidget {
  final WidgetRef ref;
  const _ManageTemplatesSheet({required this.ref});

  @override
  State<_ManageTemplatesSheet> createState() => _ManageTemplatesSheetState();
}

class _ManageTemplatesSheetState extends State<_ManageTemplatesSheet> {
  bool _adding = false;
  final _nameCtl = TextEditingController();
  final _amountCtl = TextEditingController();
  String _category = kExpenseCategories.first;
  String? _editingId;

  @override
  void dispose() {
    _nameCtl.dispose();
    _amountCtl.dispose();
    super.dispose();
  }

  void _startEdit(ExpenseTemplate t) {
    setState(() {
      _adding = true;
      _editingId = t.id;
      _nameCtl.text = t.name;
      _amountCtl.text = t.amount.toStringAsFixed(0);
      _category = kExpenseCategories.contains(t.category) ? t.category : kExpenseCategories.first;
    });
  }

  void _save() {
    final name = _nameCtl.text.trim();
    final amount = double.tryParse(_amountCtl.text) ?? 0;
    if (name.isEmpty || amount <= 0) return;

    final notifier = widget.ref.read(templatesProvider.notifier);
    if (_editingId != null) {
      final existing = widget.ref.read(templatesProvider).firstWhere((t) => t.id == _editingId);
      notifier.updateTemplate(existing.copyWith(
        name: name,
        amount: amount,
        category: _category,
        description: name,
      ));
    } else {
      notifier.addTemplate(ExpenseTemplate(
        id: IdGenerator.generate('local-tpl'),
        name: name,
        amount: amount,
        category: _category,
        description: name,
        lastUsed: DateTime.now(),
      ));
    }

    setState(() {
      _adding = false;
      _editingId = null;
      _nameCtl.clear();
      _amountCtl.clear();
      _category = kExpenseCategories.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final templates = widget.ref.watch(templatesProvider);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Center(child: Container(
          width: 36, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 16),
          decoration: BoxDecoration(
            color: colorScheme.outline.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        )),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Text('Manage Templates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (!_adding)
              IconButton(
                icon: const Icon(LucideIcons.plus, size: 20),
                onPressed: () => setState(() => _adding = true),
              ),
            IconButton(
              icon: const Icon(LucideIcons.x, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]),
        ),
        const SizedBox(height: 8),

        // Add/Edit form
        if (_adding) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              TextField(
                controller: _nameCtl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  isDense: true,
                  hintText: 'e.g., Coffee',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  isDense: true,
                  prefixText: '\u20b1 ',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                isDense: true,
                decoration: const InputDecoration(labelText: 'Category', isDense: true),
                items: kExpenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) { if (v != null) setState(() => _category = v); },
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() { _adding = false; _editingId = null; _nameCtl.clear(); _amountCtl.clear(); }),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(_editingId != null ? 'Update' : 'Add'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
            ]),
          ),
        ],

        // Template list
        Flexible(
          child: templates.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: [
                    Icon(LucideIcons.zap, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text('No templates yet', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('Add your frequent expenses for quick logging',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  ]),
                )
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  onReorder: (oldIndex, newIndex) {
                    widget.ref.read(templatesProvider.notifier).reorder(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final t = templates[index];
                    return ListTile(
                      key: ValueKey(t.id),
                      leading: Icon(LucideIcons.gripVertical, size: 16, color: colorScheme.onSurfaceVariant),
                      title: Text(t.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text('${t.category} · \u20b1${t.amount.toStringAsFixed(0)} · Used ${t.useCount}x',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: Icon(LucideIcons.pencil, size: 16, color: colorScheme.onSurfaceVariant),
                          onPressed: () => _startEdit(t),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFEF4444)),
                          onPressed: () => widget.ref.read(templatesProvider.notifier).removeTemplate(t.id),
                        ),
                      ]),
                    );
                  },
                ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
}
