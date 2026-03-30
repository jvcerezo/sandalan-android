import 'package:flutter_test/flutter_test.dart';
import 'package:sandalan/core/math/retirement_math.dart';

void main() {
  group('SSS Pension Estimate', () {
    test('below 10 credited years returns 0 pension', () {
      final result = estimateSSSPension(20000, 9);
      expect(result.monthlyPension, 0);
      expect(result.formula, contains('Minimum 10 years'));
    });

    test('exactly 10 years returns basic pension', () {
      final result = estimateSSSPension(20000, 10);
      expect(result.monthlyPension, greaterThan(0));
    });

    test('20 years at max MSC returns reasonable pension', () {
      final result = estimateSSSPension(30000, 20);
      expect(result.monthlyPension, greaterThan(1200)); // Must beat P1,200 minimum
      expect(result.monthlyPension, lessThan(30000)); // Can't exceed MSC
    });

    test('formula uses max of three calculations', () {
      // Formula 1: 300 + 20% AMSC + 2% AMSC * (CYS-10)
      // Formula 2: 1200
      // Formula 3: 40% AMSC
      final result = estimateSSSPension(10000, 15);
      final f1 = 300 + 10000 * 0.2 + 10000 * 0.02 * 5; // 300+2000+1000=3300
      final f3 = 10000 * 0.4; // 4000
      // Should be max(3300, 1200, 4000) = 4000
      expect(result.monthlyPension, closeTo(4000, 0.01));
    });

    test('40 years is reasonable max', () {
      final result = estimateSSSPension(30000, 40);
      expect(result.monthlyPension, greaterThan(0));
      expect(result.creditedYears, 40);
    });
  });

  group('Retirement Projection', () {
    test('30-year-old targeting 60 has 30 years to retirement', () {
      final result = projectRetirement(
        currentAge: 30,
        retirementAge: 60,
        monthlySalary: 30000,
        currentSavings: 100000,
        desiredMonthlyIncome: 30000,
        contributionYears: 5,
      );
      expect(result.yearsToRetirement, 30);
    });

    test('high current savings reduces required monthly savings', () {
      final low = projectRetirement(
        currentAge: 30, retirementAge: 60, monthlySalary: 30000,
        currentSavings: 0, desiredMonthlyIncome: 30000, contributionYears: 5,
      );
      final high = projectRetirement(
        currentAge: 30, retirementAge: 60, monthlySalary: 30000,
        currentSavings: 5000000, desiredMonthlyIncome: 30000, contributionYears: 5,
      );
      expect(high.requiredMonthlySavings, lessThan(low.requiredMonthlySavings));
    });

    test('already retired (currentAge >= retirementAge) has 0 years', () {
      final result = projectRetirement(
        currentAge: 65, retirementAge: 60, monthlySalary: 30000,
        currentSavings: 1000000, desiredMonthlyIncome: 20000, contributionYears: 30,
      );
      expect(result.yearsToRetirement, 0);
    });

    test('SSS pension reduces monthly gap', () {
      final result = projectRetirement(
        currentAge: 30, retirementAge: 60, monthlySalary: 30000,
        currentSavings: 0, desiredMonthlyIncome: 30000, contributionYears: 10,
      );
      expect(result.sssPension.monthlyPension, greaterThan(0));
      expect(result.monthlyGap, lessThan(30000)); // Pension covers some
    });
  });
}
