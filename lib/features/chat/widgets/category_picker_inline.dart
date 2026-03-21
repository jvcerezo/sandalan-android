import 'package:flutter/material.dart';
import '../../../core/constants/categories.dart';

class CategoryPickerInline extends StatelessWidget {
  final bool isIncome;
  final ValueChanged<String> onSelected;

  const CategoryPickerInline({
    super.key,
    required this.isIncome,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categories = isIncome ? kIncomeCategories : kExpenseCategories;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: categories.map((cat) {
            return ActionChip(
              label: Text(cat, style: const TextStyle(fontSize: 12)),
              onPressed: () => onSelected(cat),
              backgroundColor: cs.surfaceContainerHighest,
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ),
    );
  }
}
