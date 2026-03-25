import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Section of the Add Transaction dialog that shows the repeat/recurring settings.
class RecurringTransactionSection extends StatelessWidget {
  final int repeatInterval;
  final String repeatFrequency;
  final TimeOfDay? repeatTime;
  final DateTime? repeatEndDate;
  final int? repeatDay;
  final String? repeatDates;
  final DateTime? biweeklyStartDate;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<String> onFrequencyChanged;
  final ValueChanged<TimeOfDay?> onTimeChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final ValueChanged<int?> onRepeatDayChanged;
  final ValueChanged<String?> onRepeatDatesChanged;
  final ValueChanged<DateTime?> onBiweeklyStartDateChanged;
  final ColorScheme cs;

  const RecurringTransactionSection({
    super.key,
    required this.repeatInterval,
    required this.repeatFrequency,
    required this.repeatTime,
    required this.repeatEndDate,
    this.repeatDay,
    this.repeatDates,
    this.biweeklyStartDate,
    required this.onIntervalChanged,
    required this.onFrequencyChanged,
    required this.onTimeChanged,
    required this.onEndDateChanged,
    this.onRepeatDayChanged = _noOpInt,
    this.onRepeatDatesChanged = _noOpString,
    this.onBiweeklyStartDateChanged = _noOpDate,
    required this.cs,
  });

  static void _noOpInt(int? v) {}
  static void _noOpString(String? v) {}
  static void _noOpDate(DateTime? v) {}

  static const _frequencies = [
    ('daily', 'Daily'),
    ('weekly', 'Weekly'),
    ('biweekly', 'Biweekly'),
    ('twice_monthly', 'Twice a Month'),
    ('monthly', 'Monthly'),
    ('quarterly', 'Quarterly'),
    ('yearly', 'Yearly'),
  ];

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.04),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.repeat, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text('Repeat settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
        ]),
        const SizedBox(height: 12),

        // Frequency chips
        Wrap(spacing: 6, runSpacing: 6, children: _frequencies.map((f) {
          final selected = repeatFrequency == f.$1;
          return GestureDetector(
            onTap: () {
              onFrequencyChanged(f.$1);
              // Set default day to today's weekday for weekly/biweekly
              if (f.$1 == 'weekly' || f.$1 == 'biweekly') {
                onRepeatDayChanged(DateTime.now().weekday);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? cs.primary : Colors.transparent,
                border: Border.all(color: selected ? cs.primary : cs.outline.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(f.$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant)),
            ),
          );
        }).toList()),
        const SizedBox(height: 12),

        // Conditional fields based on frequency
        if (repeatFrequency == 'weekly' || repeatFrequency == 'biweekly') ...[
          Text('Day of week', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(spacing: 4, runSpacing: 4, children: List.generate(7, (i) {
            final dayNum = i + 1; // 1=Mon, 7=Sun
            final selected = (repeatDay ?? DateTime.now().weekday) == dayNum;
            return GestureDetector(
              onTap: () => onRepeatDayChanged(dayNum),
              child: Container(
                width: 38, height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? cs.primary : Colors.transparent,
                  border: Border.all(color: selected ? cs.primary : cs.outline.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_dayNames[i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                    color: selected ? cs.onPrimary : cs.onSurfaceVariant)),
              ),
            );
          })),
          const SizedBox(height: 10),
        ],

        if (repeatFrequency == 'biweekly') ...[
          Text('Starting from', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: biweeklyStartDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) onBiweeklyStartDateChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Text(
                  biweeklyStartDate != null
                      ? '${biweeklyStartDate!.month.toString().padLeft(2, '0')}/${biweeklyStartDate!.day.toString().padLeft(2, '0')}/${biweeklyStartDate!.year}'
                      : 'Select start date',
                  style: TextStyle(fontSize: 12,
                      color: biweeklyStartDate != null ? cs.onSurface : cs.onSurfaceVariant),
                ),
                const Spacer(),
                Icon(LucideIcons.calendar, size: 14, color: cs.onSurfaceVariant),
              ]),
            ),
          ),
          const SizedBox(height: 10),
        ],

        if (repeatFrequency == 'twice_monthly') ...[
          Text('Payment dates', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _TwiceMonthlyField(
              label: '1st date',
              defaultValue: repeatDates != null ? repeatDates!.split(',').first.trim() : '15',
              onChanged: (v) {
                final parts = (repeatDates ?? '15,30').split(',');
                final second = parts.length > 1 ? parts[1].trim() : '30';
                onRepeatDatesChanged('$v,$second');
              },
              cs: cs,
            )),
            const SizedBox(width: 8),
            Expanded(child: _TwiceMonthlyField(
              label: '2nd date',
              defaultValue: repeatDates != null && repeatDates!.split(',').length > 1
                  ? repeatDates!.split(',')[1].trim() : '30',
              onChanged: (v) {
                final parts = (repeatDates ?? '15,30').split(',');
                final first = parts.first.trim();
                onRepeatDatesChanged('$first,$v');
              },
              cs: cs,
            )),
          ]),
          const SizedBox(height: 10),
        ],

        // Time and end date
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
                  border: Border.all(color: cs.outline.withOpacity(0.15)),
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
                  border: Border.all(color: cs.outline.withOpacity(0.15)),
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

class _TwiceMonthlyField extends StatelessWidget {
  final String label;
  final String defaultValue;
  final ValueChanged<String> onChanged;
  final ColorScheme cs;

  const _TwiceMonthlyField({
    required this.label,
    required this.defaultValue,
    required this.onChanged,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
      const SizedBox(height: 4),
      TextField(
        controller: TextEditingController(text: defaultValue),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) {
          final parsed = int.tryParse(v);
          if (parsed != null && parsed >= 1 && parsed <= 31) onChanged(v);
        },
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: cs.outline.withOpacity(0.15)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: cs.outline.withOpacity(0.15)),
          ),
        ),
        style: const TextStyle(fontSize: 12),
      ),
    ]);
  }
}
