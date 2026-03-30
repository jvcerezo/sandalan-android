import 'package:flutter_test/flutter_test.dart';
import 'package:sandalan/core/math/debt_math.dart';

void main() {
  final debts = [
    const DebtInput(id: 'a', name: 'Card A', balance: 50000, annualRate: 0.24, minimumPayment: 1500),
    const DebtInput(id: 'b', name: 'Card B', balance: 20000, annualRate: 0.36, minimumPayment: 1000),
  ];

  group('Avalanche (highest rate first)', () {
    test('prioritizes Card B (36%) over Card A (24%)', () {
      final result = calculateAvalanche(debts, 5000);
      expect(result.payoffOrder.first, 'b');
      expect(result.months, greaterThan(0));
      expect(result.totalInterestPaid, greaterThan(0));
    });
  });

  group('Snowball (smallest balance first)', () {
    test('prioritizes Card B (20k) over Card A (50k)', () {
      final result = calculateSnowball(debts, 5000);
      expect(result.payoffOrder.first, 'b');
    });

    test('snowball pays more interest than avalanche', () {
      final avalanche = calculateAvalanche(debts, 5000);
      final snowball = calculateSnowball(debts, 5000);
      expect(snowball.totalInterestPaid, greaterThanOrEqualTo(avalanche.totalInterestPaid));
    });
  });

  group('Monthly Payment (PMT)', () {
    test('0% rate returns principal/months', () {
      expect(calculateMonthlyPayment(12000, 0, 12), closeTo(1000, 0.01));
    });

    test('standard rate produces reasonable payment', () {
      final pmt = calculateMonthlyPayment(100000, 0.24, 12);
      expect(pmt, greaterThan(100000 / 12)); // must be more than principal alone
      expect(pmt, lessThan(15000)); // but not absurdly high
    });

    test('0 months returns 0', () {
      expect(calculateMonthlyPayment(10000, 0.12, 0), 0);
    });
  });

  group('Payoff Months', () {
    test('returns -1 when payment cannot cover interest', () {
      expect(calculatePayoffMonths(100000, 0.24, 100), -1);
    });

    test('0% rate = principal / payment (ceil)', () {
      expect(calculatePayoffMonths(10000, 0, 1000), 10);
    });

    test('reasonable payment returns finite months', () {
      final months = calculatePayoffMonths(50000, 0.24, 3000);
      expect(months, greaterThan(0));
      expect(months, lessThan(600));
    });
  });

  group('Total Interest', () {
    test('0% rate returns 0 interest', () {
      expect(calculateTotalInterest(10000, 0, 12), 0);
    });

    test('positive rate returns positive interest', () {
      expect(calculateTotalInterest(100000, 0.24, 24), greaterThan(0));
    });
  });

  group('Edge cases', () {
    test('empty debts list returns 0 months', () {
      final result = calculateAvalanche([], 5000);
      expect(result.months, 0);
      expect(result.totalPaid, 0);
    });

    test('0 budget returns 0 months', () {
      final result = calculateAvalanche(debts, 0);
      expect(result.months, 0);
    });
  });
}
