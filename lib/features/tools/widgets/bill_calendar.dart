import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/bill.dart';
import '../../../data/models/debt.dart';
import '../../../data/models/insurance_policy.dart';
import '../providers/tool_providers.dart';

/// Type of due event for coloring dots on the calendar.
enum DueType { bill, debt, insurance, contribution }

class DueEvent {
  final DueType type;
  final String title;
  final double amount;
  final int day;

  const DueEvent({
    required this.type,
    required this.title,
    required this.amount,
    required this.day,
  });

  Color get dotColor {
    switch (type) {
      case DueType.bill:
        return const Color(0xFFEF4444); // red
      case DueType.debt:
        return const Color(0xFFF97316); // orange
      case DueType.insurance:
        return const Color(0xFF14B8A6); // teal
      case DueType.contribution:
        return const Color(0xFF8B5CF6); // purple
    }
  }
}

/// Full monthly calendar view showing colored dots on due dates.
class BillDueCalendar extends ConsumerStatefulWidget {
  const BillDueCalendar({super.key});

  @override
  ConsumerState<BillDueCalendar> createState() => _BillDueCalendarState();
}

class _BillDueCalendarState extends ConsumerState<BillDueCalendar> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
    });
  }

  List<DueEvent> _collectDueEvents(
    List<Bill> bills,
    List<Debt> debts,
    List<InsurancePolicy> policies,
  ) {
    final events = <DueEvent>[];

    for (final bill in bills) {
      if (!bill.isActive || bill.dueDay == null) continue;
      events.add(DueEvent(
        type: DueType.bill,
        title: bill.name,
        amount: bill.amount,
        day: bill.dueDay!,
      ));
    }

    for (final debt in debts) {
      if (debt.isPaidOff || debt.dueDay == null) continue;
      events.add(DueEvent(
        type: DueType.debt,
        title: debt.name,
        amount: debt.minimumPayment,
        day: debt.dueDay!,
      ));
    }

    for (final policy in policies) {
      if (!policy.isActive || policy.renewalDate == null) continue;
      final renewal = DateTime.tryParse(policy.renewalDate!);
      if (renewal != null) {
        events.add(DueEvent(
          type: DueType.insurance,
          title: policy.name,
          amount: policy.premiumAmount,
          day: renewal.day,
        ));
      }
    }

    // Contributions: due last day of month
    final lastDay = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    events.add(DueEvent(
      type: DueType.contribution,
      title: 'Government contributions',
      amount: 0,
      day: lastDay,
    ));

    return events;
  }

  void _showDaySheet(BuildContext context, int day, List<DueEvent> events) {
    final dayEvents = events.where((e) => e.day == day).toList();
    if (dayEvents.isEmpty) return;

    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Due on Day $day',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...dayEvents.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: e.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                if (e.amount > 0)
                  Text(formatCurrency(e.amount),
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ]),
            )),
            const SizedBox(height: 8),
            // Legend
            Wrap(spacing: 12, runSpacing: 4, children: [
              _LegendDot(color: const Color(0xFFEF4444), label: 'Bill'),
              _LegendDot(color: const Color(0xFFF97316), label: 'Debt'),
              _LegendDot(color: const Color(0xFF14B8A6), label: 'Insurance'),
              _LegendDot(color: const Color(0xFF8B5CF6), label: 'Contribution'),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final billsAsync = ref.watch(billsProvider);
    final debtsAsync = ref.watch(debtsProvider);
    final policiesAsync = ref.watch(insurancePoliciesProvider);

    final bills = billsAsync.valueOrNull ?? [];
    final debts = debtsAsync.valueOrNull ?? [];
    final policies = policiesAsync.valueOrNull ?? [];

    final events = _collectDueEvents(bills, debts, policies);
    final eventsByDay = <int, List<DueEvent>>{};
    for (final e in events) {
      eventsByDay.putIfAbsent(e.day, () => []).add(e);
    }

    final now = DateTime.now();
    final today = now.day;
    final isCurrentMonth = _viewMonth.year == now.year && _viewMonth.month == now.month;
    final firstDayOfMonth = _viewMonth;
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun
    // Make calendar start on Monday
    final offset = startWeekday - 1;

    const dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthName = _monthNames[_viewMonth.month - 1];

    return Column(
      children: [
        // Header: < March 2026 >
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _prevMonth,
              icon: const Icon(LucideIcons.chevronLeft, size: 18),
            ),
            Text('$monthName ${_viewMonth.year}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(LucideIcons.chevronRight, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Day headers
        Row(
          children: dayHeaders.map((d) => Expanded(
            child: Center(
              child: Text(d,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 4),

        // Day grid
        ...List.generate(6, (week) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = week * 7 + col;
              final day = cellIndex - offset + 1;
              if (day < 1 || day > daysInMonth) {
                return const Expanded(child: SizedBox(height: 44));
              }

              final isToday = isCurrentMonth && day == today;
              final isPast = isCurrentMonth && day < today;
              final dayEvents = eventsByDay[day] ?? [];
              final hasEvents = dayEvents.isNotEmpty;

              return Expanded(
                child: GestureDetector(
                  onTap: hasEvents ? () => _showDaySheet(context, day, events) : null,
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isToday ? cs.primary.withValues(alpha: 0.1) : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday ? Border.all(color: cs.primary, width: 1.5) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                            color: isToday
                                ? cs.primary
                                : isPast
                                    ? cs.onSurfaceVariant.withValues(alpha: 0.4)
                                    : cs.onSurface,
                          ),
                        ),
                        if (hasEvents) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dayEvents.take(4).map((e) => Container(
                              width: 4, height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: e.dotColor,
                                shape: BoxShape.circle,
                              ),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
        const SizedBox(height: 8),

        // Legend
        Wrap(spacing: 12, runSpacing: 4, children: const [
          _LegendDot(color: Color(0xFFEF4444), label: 'Bill'),
          _LegendDot(color: Color(0xFFF97316), label: 'Debt'),
          _LegendDot(color: Color(0xFF14B8A6), label: 'Insurance'),
          _LegendDot(color: Color(0xFF8B5CF6), label: 'Contribution'),
        ]),
      ],
    );
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 6, height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10,
          color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}

/// Compact 7-day strip for the home screen showing upcoming due dates.
class DueThisWeekStrip extends ConsumerWidget {
  const DueThisWeekStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final billsAsync = ref.watch(billsProvider);
    final debtsAsync = ref.watch(debtsProvider);
    final policiesAsync = ref.watch(insurancePoliciesProvider);

    final bills = billsAsync.valueOrNull ?? [];
    final debts = debtsAsync.valueOrNull ?? [];
    final policies = policiesAsync.valueOrNull ?? [];

    final now = DateTime.now();
    final next7 = List.generate(7, (i) => now.add(Duration(days: i)));

    // Collect due days for this month
    final dueDays = <int, List<DueEvent>>{};
    for (final bill in bills) {
      if (!bill.isActive || bill.dueDay == null) continue;
      dueDays.putIfAbsent(bill.dueDay!, () => []).add(DueEvent(
        type: DueType.bill, title: bill.name, amount: bill.amount, day: bill.dueDay!,
      ));
    }
    for (final debt in debts) {
      if (debt.isPaidOff || debt.dueDay == null) continue;
      dueDays.putIfAbsent(debt.dueDay!, () => []).add(DueEvent(
        type: DueType.debt, title: debt.name, amount: debt.minimumPayment, day: debt.dueDay!,
      ));
    }
    for (final policy in policies) {
      if (!policy.isActive || policy.renewalDate == null) continue;
      final renewal = DateTime.tryParse(policy.renewalDate!);
      if (renewal != null) {
        dueDays.putIfAbsent(renewal.day, () => []).add(DueEvent(
          type: DueType.insurance, title: policy.name, amount: policy.premiumAmount, day: renewal.day,
        ));
      }
    }

    // Check if any of the next 7 days have events
    final hasAnyEvents = next7.any((d) => (dueDays[d.day] ?? []).isNotEmpty);
    if (!hasAnyEvents) return const SizedBox.shrink();

    const dayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DUE THIS WEEK',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 0.8, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Row(
          children: next7.map((date) {
            final isToday = date.day == now.day && date.month == now.month;
            final events = dueDays[date.day] ?? [];

            return Expanded(
              child: Column(
                children: [
                  Text(dayAbbr[date.weekday - 1],
                      style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday ? cs.primary.withValues(alpha: 0.1) : null,
                      border: isToday ? Border.all(color: cs.primary, width: 1.5) : null,
                    ),
                    child: Center(
                      child: Text('${date.day}',
                          style: TextStyle(fontSize: 11,
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                              color: isToday ? cs.primary : cs.onSurface)),
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (events.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: events.take(3).map((e) => Container(
                        width: 4, height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        decoration: BoxDecoration(
                          color: e.dotColor,
                          shape: BoxShape.circle,
                        ),
                      )).toList(),
                    )
                  else
                    const SizedBox(height: 4),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StripLegendDot(color: const Color(0xFFEF4444), label: 'Bills'),
            const SizedBox(width: 12),
            _StripLegendDot(color: const Color(0xFFF97316), label: 'Debts'),
            const SizedBox(width: 12),
            _StripLegendDot(color: const Color(0xFF14B8A6), label: 'Insurance'),
            const SizedBox(width: 12),
            _StripLegendDot(color: const Color(0xFF8B5CF6), label: 'Contrib.'),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _StripLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _StripLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}
