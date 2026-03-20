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
  String _category = kGoalCategories.first;
  final _nameCtl = TextEditingController();
  final _targetCtl = TextEditingController();
  final _savedCtl = TextEditingController();
  DateTime? _deadline;
  bool _saving = false;

  @override
  void dispose() { _nameCtl.dispose(); _targetCtl.dispose(); _savedCtl.dispose(); super.dispose(); }

  IconData _icon(String c) {
    switch (c) {
      case 'Emergency Fund': return LucideIcons.shield;
      case 'Debt Payoff': return LucideIcons.creditCard;
      case 'Savings': return LucideIcons.piggyBank;
      case 'Investment': return LucideIcons.trendingUp;
      case 'Retirement': return LucideIcons.clock;
      case 'Travel': return LucideIcons.plane;
      case 'Education': return LucideIcons.graduationCap;
      case 'Home': return LucideIcons.home;
      case 'Vehicle': return LucideIcons.car;
      default: return LucideIcons.moreHorizontal;
    }
  }

  Future<void> _save() async {
    final name = _nameCtl.text.trim();
    final target = double.tryParse(_targetCtl.text.replaceAll(',', ''));
    if (name.isEmpty || target == null || target <= 0) return;
    setState(() => _saving = true);
    try {
      final saved = double.tryParse(_savedCtl.text.replaceAll(',', '')) ?? 0;
      await ref.read(goalRepositoryProvider).createGoal(
          name: name, targetAmount: target, currentAmount: saved,
          category: _category, deadline: _deadline);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) { setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.8, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
      builder: (context, ctl) => Container(
        decoration: BoxDecoration(color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: ListView(controller: ctl, padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), children: [
          Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: cs.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
          const Center(child: Text('Create a New Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),

          // Category
          const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: kGoalCategories.map((c) {
            final selected = _category == c;
            return GestureDetector(
              onTap: () => setState(() => _category = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
                  border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_icon(c), size: 12, color: selected ? cs.primary : cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(c, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: selected ? cs.primary : cs.onSurfaceVariant)),
                ]),
              ),
            );
          }).toList()),
          const SizedBox(height: 16),

          // Goal Name
          const Text('Goal Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TextField(controller: _nameCtl,
              decoration: InputDecoration(isDense: true, hintText: 'e.g., Emergency Fund',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  border: InputBorder.none),
              style: const TextStyle(fontSize: 14)),
          Divider(color: cs.outline.withValues(alpha: 0.10)),
          const SizedBox(height: 10),

          // Target Amount
          const Text('Target Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('₱', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant)),
            const SizedBox(width: 4),
            Expanded(child: TextField(
              controller: _targetCtl, autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant),
              decoration: InputDecoration(hintText: '0.00',
                  hintStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                  border: InputBorder.none, contentPadding: EdgeInsets.zero),
            )),
          ]),
          const SizedBox(height: 12),

          // Saved So Far + Deadline
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Saved So Far', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextField(controller: _savedCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                decoration: InputDecoration(isDense: true, hintText: '0.00', prefixText: '₱ ',
                    prefixStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Deadline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(context: context,
                      initialDate: DateTime.now().add(const Duration(days: 90)),
                      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
                  if (picked != null) setState(() => _deadline = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Text(_deadline != null
                        ? '${_deadline!.month.toString().padLeft(2, '0')}/${_deadline!.day.toString().padLeft(2, '0')}/${_deadline!.year}'
                        : 'mm/dd/yyyy',
                        style: TextStyle(fontSize: 12, color: _deadline != null ? cs.onSurface : cs.onSurfaceVariant)),
                    const Spacer(),
                    Icon(LucideIcons.calendar, size: 14, color: cs.onSurfaceVariant),
                  ]),
                ),
              ),
            ])),
          ]),
          const SizedBox(height: 20),

          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create Goal'),
          ),
        ]),
      ),
    );
  }
}
