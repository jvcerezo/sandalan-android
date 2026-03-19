/// Debt payoff strategy calculations — Avalanche and Snowball methods.
/// Direct port of debt-math.ts.

import 'dart:math' as math;

// ─── Types ────────────────────────────────────────────────────────────────────

class DebtInput {
  final String id;
  final String name;
  final double balance;
  final double annualRate; // as decimal, e.g. 0.24 for 24%
  final double minimumPayment;

  const DebtInput({
    required this.id,
    required this.name,
    required this.balance,
    required this.annualRate,
    required this.minimumPayment,
  });
}

class PayoffMonth {
  final int month;
  final Map<String, double> payments;
  final Map<String, double> remainingBalances;
  final double totalInterestPaid;

  const PayoffMonth({
    required this.month,
    required this.payments,
    required this.remainingBalances,
    required this.totalInterestPaid,
  });
}

class PayoffResult {
  final String strategy;
  final int months;
  final double totalInterestPaid;
  final double totalPaid;
  final List<String> payoffOrder;
  final List<PayoffMonth> schedule;

  const PayoffResult({
    required this.strategy,
    required this.months,
    required this.totalInterestPaid,
    required this.totalPaid,
    required this.payoffOrder,
    required this.schedule,
  });
}

// ─── Core simulation ──────────────────────────────────────────────────────────

PayoffResult _simulatePayoff(
  List<DebtInput> debts,
  double monthlyBudget,
  String strategy,
) {
  if (debts.isEmpty || monthlyBudget <= 0) {
    return PayoffResult(
      strategy: strategy,
      months: 0,
      totalInterestPaid: 0,
      totalPaid: 0,
      payoffOrder: [],
      schedule: [],
    );
  }

  final balances = <String, double>{};
  for (final d in debts) {
    balances[d.id] = d.balance;
  }

  final payoffOrder = <String>[];
  final schedule = <PayoffMonth>[];
  double totalInterestPaid = 0;
  double totalPaid = 0;
  int month = 0;
  const maxMonths = 600; // 50 years cap

  while (balances.values.any((b) => b > 0.01) && month < maxMonths) {
    month++;
    final monthPayments = <String, double>{};
    double monthInterest = 0;
    double remainingBudget = monthlyBudget;

    // Apply interest and pay minimums
    for (final d in debts) {
      if (balances[d.id]! <= 0) continue;
      final monthlyRate =
          d.annualRate > 0 ? math.pow(1 + d.annualRate, 1 / 12) - 1 : 0.0;
      final interest = balances[d.id]! * monthlyRate;
      balances[d.id] = balances[d.id]! + interest;
      monthInterest += interest;

      final minPay = math.min(d.minimumPayment, balances[d.id]!);
      balances[d.id] = balances[d.id]! - minPay;
      monthPayments[d.id] = minPay;
      remainingBudget -= minPay;
      totalPaid += minPay;
    }

    totalInterestPaid += monthInterest;

    // Apply extra to priority debt
    if (remainingBudget > 0) {
      final activeDebts = debts.where((d) => balances[d.id]! > 0.01).toList();
      if (activeDebts.isNotEmpty) {
        DebtInput priority;
        if (strategy == 'avalanche') {
          priority = activeDebts.reduce(
              (a, b) => a.annualRate >= b.annualRate ? a : b);
        } else {
          priority = activeDebts.reduce(
              (a, b) => balances[a.id]! <= balances[b.id]! ? a : b);
        }
        final extra = math.min(remainingBudget, balances[priority.id]!);
        balances[priority.id] = balances[priority.id]! - extra;
        monthPayments[priority.id] =
            (monthPayments[priority.id] ?? 0) + extra;
        remainingBudget -= extra;
        totalPaid += extra;
      }
    }

    // Check for newly paid-off debts
    for (final d in debts) {
      if (balances[d.id]! <= 0.01 && !payoffOrder.contains(d.id)) {
        balances[d.id] = 0;
        payoffOrder.add(d.id);
      }
    }

    // Record snapshot every 6 months
    if (month % 6 == 0 || balances.values.every((b) => b <= 0.01)) {
      schedule.add(PayoffMonth(
        month: month,
        payments: Map.of(monthPayments),
        remainingBalances: Map.of(balances),
        totalInterestPaid: totalInterestPaid,
      ));
    }
  }

  return PayoffResult(
    strategy: strategy,
    months: month,
    totalInterestPaid: _round2(totalInterestPaid),
    totalPaid: _round2(totalPaid),
    payoffOrder: payoffOrder,
    schedule: schedule,
  );
}

// ─── Public API ───────────────────────────────────────────────────────────────

/// Pay highest interest rate first (mathematically optimal).
PayoffResult calculateAvalanche(List<DebtInput> debts, double monthlyBudget) =>
    _simulatePayoff(debts, monthlyBudget, 'avalanche');

/// Pay smallest balance first (psychological wins).
PayoffResult calculateSnowball(List<DebtInput> debts, double monthlyBudget) =>
    _simulatePayoff(debts, monthlyBudget, 'snowball');

/// Monthly payment needed to pay off a debt in N months (PMT formula).
double calculateMonthlyPayment(
  double principal,
  double annualRate,
  int months,
) {
  if (months <= 0) return 0;
  if (annualRate == 0) return principal / months;
  final r = math.pow(1 + annualRate, 1 / 12) - 1;
  if (r <= -1) return 0;
  final factor = math.pow(1 + r, months);
  if (factor == 1) return principal / months;
  return (principal * r * factor) / (factor - 1);
}

/// Months needed to pay off a debt given a fixed monthly payment.
int calculatePayoffMonths(
  double principal,
  double annualRate,
  double monthlyPayment,
) {
  if (monthlyPayment <= 0) return -1; // infinity
  if (annualRate == 0) return (principal / monthlyPayment).ceil();
  final r = math.pow(1 + annualRate, 1 / 12) - 1;
  if (monthlyPayment <= principal * r) return -1; // can't cover interest
  return (-math.log(1 - (principal * r) / monthlyPayment) / math.log(1 + r))
      .ceil();
}

/// Total interest paid over the life of a loan.
double calculateTotalInterest(
  double principal,
  double annualRate,
  int months,
) {
  final payment = calculateMonthlyPayment(principal, annualRate, months);
  return _round2(payment * months - principal);
}

double _round2(double value) => (value * 100).roundToDouble() / 100;
