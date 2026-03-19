/// Due-date utilities for bills, debts, insurance, and contributions.
/// Direct port of due-dates.ts.

/// Get the next due date for a bill based on its due_day and billing_cycle.
DateTime? getNextBillDueDate(
  int? dueDay,
  String billingCycle,
  String? lastPaidDate,
) {
  if (dueDay == null) return null;

  final today = _getToday();
  final currentMonth = _safeDate(today.year, today.month, dueDay);

  if (lastPaidDate == null) {
    if (!currentMonth.isBefore(today)) return currentMonth;
    return _addCycleMonths(currentMonth, billingCycle);
  }

  final parts = lastPaidDate.split('-').map(int.parse).toList();
  final lastPaid = DateTime(parts[0], parts[1], parts[2]);

  var nextDue = _safeDate(lastPaid.year, lastPaid.month, dueDay);
  nextDue = _addCycleMonths(nextDue, billingCycle);

  while (nextDue.isBefore(today)) {
    nextDue = _addCycleMonths(nextDue, billingCycle);
  }

  return nextDue;
}

/// Get the next due date for a debt payment based on its due_day.
DateTime? getNextDebtDueDate(int? dueDay) {
  if (dueDay == null) return null;

  final today = _getToday();
  final thisMonth = _safeDate(today.year, today.month, dueDay);
  if (!thisMonth.isBefore(today)) return thisMonth;
  return _safeDate(today.year, today.month + 1, dueDay);
}

/// Get the next premium due date for an insurance policy.
DateTime? getNextPremiumDueDate(
  String? renewalDate,
  String premiumFrequency,
) {
  if (renewalDate == null) return null;

  final today = _getToday();
  final parts = renewalDate.split('-').map(int.parse).toList();
  var nextDue = DateTime(parts[0], parts[1], parts[2]);

  final cycleMonths = _getCycleMonths(premiumFrequency);

  while (nextDue.isAfter(today)) {
    nextDue = DateTime(nextDue.year, nextDue.month - cycleMonths, nextDue.day);
  }

  while (nextDue.isBefore(today)) {
    nextDue = DateTime(nextDue.year, nextDue.month + cycleMonths, nextDue.day);
  }

  return nextDue;
}

/// Get the current contribution period (YYYY-MM).
String getCurrentContributionPeriod() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

/// Get days until a date from today. Negative = overdue.
int daysUntil(DateTime date) {
  final today = _getToday();
  return date.difference(today).inDays;
}

/// Get urgency label and color name.
({String label, String color}) getUrgencyLabel(int days) {
  if (days < 0) return (label: 'Overdue', color: 'red');
  if (days == 0) return (label: 'Due today', color: 'amber');
  if (days <= 3) return (label: '${days}d', color: 'amber');
  if (days <= 7) return (label: '${days}d', color: 'muted');
  return (label: '${days}d', color: 'muted');
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

DateTime _getToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Build a date clamping day to last day of month.
DateTime _safeDate(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day.clamp(1, lastDay));
}

int _getCycleMonths(String cycle) {
  switch (cycle) {
    case 'monthly':
      return 1;
    case 'quarterly':
      return 3;
    case 'semi_annual':
      return 6;
    case 'annual':
      return 12;
    default:
      return 1;
  }
}

DateTime _addCycleMonths(DateTime date, String cycle) {
  final months = _getCycleMonths(cycle);
  return _safeDate(date.year, date.month + months, date.day);
}
