import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

/// Result from the budget rollover dialog.
enum BudgetRolloverChoice { rollover, startFresh, dismiss }

class BudgetRolloverResult {
  final BudgetRolloverChoice choice;
  final bool autoRollover;

  const BudgetRolloverResult({
    required this.choice,
    this.autoRollover = false,
  });
}

/// Dialog shown at the start of a new month asking the user what to do with budgets.
class BudgetRolloverDialog extends StatefulWidget {
  final DateTime currentMonth;

  const BudgetRolloverDialog({super.key, required this.currentMonth});

  @override
  State<BudgetRolloverDialog> createState() => _BudgetRolloverDialogState();
}

class _BudgetRolloverDialogState extends State<BudgetRolloverDialog> {
  bool _autoRollover = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final monthLabel = DateFormat('MMMM yyyy').format(widget.currentMonth);

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.calendarCheck, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('New Month!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "It's $monthLabel! What would you like to do with your budgets?",
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          // Option 1: Roll over
          _OptionTile(
            icon: LucideIcons.refreshCw,
            title: 'Roll over from last month',
            subtitle: 'Copies budgets and carries unused amounts forward',
            color: colorScheme.primary,
            onTap: () => _select(BudgetRolloverChoice.rollover),
          ),
          const SizedBox(height: 10),

          // Option 2: Start fresh
          _OptionTile(
            icon: LucideIcons.sparkles,
            title: 'Start fresh',
            subtitle: 'No budgets for this month',
            color: colorScheme.secondary,
            onTap: () => _select(BudgetRolloverChoice.startFresh),
          ),
          const SizedBox(height: 16),

          // Automation checkbox
          InkWell(
            onTap: () => setState(() => _autoRollover = !_autoRollover),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _autoRollover,
                      onChanged: (v) => setState(() => _autoRollover = v ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Do this automatically every month',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const BudgetRolloverResult(choice: BudgetRolloverChoice.dismiss)),
          child: const Text("I'll do it later"),
        ),
      ],
    );
  }

  void _select(BudgetRolloverChoice choice) {
    Navigator.pop(context, BudgetRolloverResult(
      choice: choice,
      autoRollover: _autoRollover,
    ));
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
