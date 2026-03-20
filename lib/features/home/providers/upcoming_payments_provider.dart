import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/bill.dart';
import '../../../data/models/debt.dart';
import '../../../data/models/insurance_policy.dart';
import '../../../data/models/contribution.dart';
import '../../tools/providers/tool_providers.dart';

enum PaymentType { bill, debt, insurance, contribution }

class UpcomingPayment {
  final String id;
  final PaymentType type;
  final String title;
  final String subtitle;
  final double amount;
  final int daysUntilDue;

  const UpcomingPayment({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.daysUntilDue,
  });
}

class UpcomingPaymentsData {
  final List<UpcomingPayment> items;
  final double totalDue;
  final int overdueCount;

  const UpcomingPaymentsData({
    required this.items,
    required this.totalDue,
    required this.overdueCount,
  });
}

String _urgencyLabel(int days) {
  if (days < 0) return 'Overdue';
  if (days == 0) return 'Due today';
  return '${days}d';
}

/// Aggregates upcoming payments from bills, debts, insurance, and contributions.
final upcomingPaymentsProvider = FutureProvider<UpcomingPaymentsData>((ref) async {
  const daysAhead = 30;
  final results = <UpcomingPayment>[];
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);

  int _daysUntil(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return dateOnly.difference(todayOnly).inDays;
  }

  DateTime _safeDate(int year, int month, int day) {
    // Clamp day to last day of month
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay));
  }

  int _cycleMonths(String cycle) {
    switch (cycle) {
      case 'monthly': return 1;
      case 'quarterly': return 3;
      case 'semi_annual': return 6;
      case 'annual': return 12;
      default: return 1;
    }
  }

  // ── Bills ──
  try {
    final bills = await ref.read(billsProvider.future);
    for (final bill in bills) {
      if (!bill.isActive || bill.dueDay == null) continue;

      DateTime nextDue;
      if (bill.lastPaidDate == null) {
        // Find next occurrence from today
        nextDue = _safeDate(today.year, today.month, bill.dueDay!);
        if (nextDue.isBefore(todayOnly)) {
          final m = _cycleMonths(bill.billingCycle);
          nextDue = _safeDate(nextDue.year, nextDue.month + m, nextDue.day);
        }
      } else {
        final lastPaid = DateTime.parse(bill.lastPaidDate!);
        final m = _cycleMonths(bill.billingCycle);
        nextDue = _safeDate(lastPaid.year, lastPaid.month + m, bill.dueDay!);
        while (nextDue.isBefore(todayOnly)) {
          nextDue = _safeDate(nextDue.year, nextDue.month + m, nextDue.day);
        }
      }

      final days = _daysUntil(nextDue);
      if (days > daysAhead) continue;

      results.add(UpcomingPayment(
        id: 'bill-${bill.id}',
        type: PaymentType.bill,
        title: bill.name,
        subtitle: bill.provider ?? bill.category,
        amount: bill.amount,
        daysUntilDue: days,
      ));
    }
  } catch (_) {}

  // ── Debts ──
  try {
    final debts = await ref.read(debtsProvider.future);
    for (final debt in debts) {
      if (debt.isPaidOff || debt.dueDay == null) continue;

      var nextDue = _safeDate(today.year, today.month, debt.dueDay!);
      if (nextDue.isBefore(todayOnly)) {
        nextDue = _safeDate(today.year, today.month + 1, debt.dueDay!);
      }

      final days = _daysUntil(nextDue);
      if (days > daysAhead) continue;

      results.add(UpcomingPayment(
        id: 'debt-${debt.id}',
        type: PaymentType.debt,
        title: debt.name,
        subtitle: debt.lender ?? 'Debt payment',
        amount: debt.minimumPayment,
        daysUntilDue: days,
      ));
    }
  } catch (_) {}

  // ── Insurance ──
  try {
    final policies = await ref.read(insurancePoliciesProvider.future);
    for (final policy in policies) {
      if (!policy.isActive || policy.renewalDate == null) continue;

      final renewal = DateTime.parse(policy.renewalDate!);
      final cm = _cycleMonths(policy.premiumFrequency);
      var nextDue = renewal;

      // Walk back to find nearest past due
      while (nextDue.isAfter(todayOnly)) {
        nextDue = DateTime(nextDue.year, nextDue.month - cm, nextDue.day);
      }
      // Walk forward to find next upcoming
      while (nextDue.isBefore(todayOnly)) {
        nextDue = DateTime(nextDue.year, nextDue.month + cm, nextDue.day);
      }

      final days = _daysUntil(nextDue);
      if (days > daysAhead) continue;

      results.add(UpcomingPayment(
        id: 'insurance-${policy.id}',
        type: PaymentType.insurance,
        title: policy.name,
        subtitle: policy.provider ?? 'Insurance premium',
        amount: policy.premiumAmount,
        daysUntilDue: days,
      ));
    }
  } catch (_) {}

  // ── Contributions (unpaid for current month) ──
  try {
    final contributions = await ref.read(contributionsProvider.future);
    final currentPeriod =
        '${today.year}-${today.month.toString().padLeft(2, '0')}';
    const typeLabels = {'sss': 'SSS', 'philhealth': 'PhilHealth', 'pagibig': 'Pag-IBIG'};

    for (final contrib in contributions) {
      if (contrib.isPaid || contrib.period != currentPeriod) continue;

      // Due by last day of the month
      final parts = contrib.period.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final dueDate = DateTime(y, m + 1, 0); // last day
      final days = _daysUntil(dueDate);
      if (days > daysAhead) continue;

      results.add(UpcomingPayment(
        id: 'contribution-${contrib.id}',
        type: PaymentType.contribution,
        title: '${typeLabels[contrib.type] ?? contrib.type} Contribution',
        subtitle: contrib.period,
        amount: contrib.employeeShare,
        daysUntilDue: days,
      ));
    }
  } catch (_) {}

  // Sort by urgency: overdue first, then soonest
  results.sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));

  final totalDue = results.fold<double>(0, (sum, item) => sum + item.amount);
  final overdueCount = results.where((i) => i.daysUntilDue < 0).length;

  return UpcomingPaymentsData(
    items: results,
    totalDue: totalDue,
    overdueCount: overdueCount,
  );
});
