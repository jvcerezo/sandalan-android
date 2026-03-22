import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Section of the Add Transaction dialog that shows the repeat/recurring settings.
class RecurringTransactionSection extends StatelessWidget {
  final int repeatInterval;
  final String repeatFrequency;
  final TimeOfDay? repeatTime;
  final DateTime? repeatEndDate;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<String> onFrequencyChanged;
  final ValueChanged<TimeOfDay?> onTimeChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final ColorScheme cs;

  const RecurringTransactionSection({
    super.key,
    required this.repeatInterval,
    required this.repeatFrequency,
    required this.repeatTime,
    required this.repeatEndDate,
    required this.onIntervalChanged,
    required this.onFrequencyChanged,
    required this.onTimeChanged,
    required this.onEndDateChanged,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.04),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.repeat, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text('Repeat settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          SizedBox(width: 50, child: TextField(
            decoration: const InputDecoration(isDense: true),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: '$repeatInterval'),
            onChanged: (v) {
              final parsed = int.tryParse(v) ?? 1;
              onIntervalChanged(parsed.clamp(1, 365));
            },
          )),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField<String>(
            value: repeatFrequency, isDense: true,
            items: ['daily', 'weekly', 'monthly'].map((f) =>
                DropdownMenuItem(value: f, child: Text('${f[0].toUpperCase()}${f.substring(1)}(s)'))).toList(),
            onChanged: (v) => onFrequencyChanged(v ?? 'monthly'),
          )),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Time (optional)', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: repeatTime ?? TimeOfDay.now(),
                );
                if (picked != null) onTimeChanged(picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Text(
                    repeatTime != null ? repeatTime!.format(context) : '--:-- --',
                    style: TextStyle(fontSize: 12,
                        color: repeatTime != null ? cs.onSurface : cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Icon(LucideIcons.clock, size: 14, color: cs.onSurfaceVariant),
                ]),
              ),
            ),
          ])),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('End date (optional)', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: repeatEndDate ?? DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) onEndDateChanged(picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Text(
                    repeatEndDate != null
                        ? '${repeatEndDate!.month.toString().padLeft(2, '0')}/${repeatEndDate!.day.toString().padLeft(2, '0')}/${repeatEndDate!.year}'
                        : 'mm/dd/yyyy',
                    style: TextStyle(fontSize: 12,
                        color: repeatEndDate != null ? cs.onSurface : cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Icon(LucideIcons.calendar, size: 14, color: cs.onSurfaceVariant),
                ]),
              ),
            ),
          ])),
        ]),
      ]),
    );
  }
}
