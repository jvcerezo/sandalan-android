import 'package:flutter_test/flutter_test.dart';
import 'package:sandalan/core/math/housing_math.dart';

void main() {
  group('Loan Amortization', () {
    test('0% rate returns principal/months', () {
      final result = calculateAmortization(1200000, 0, 10);
      expect(result.monthlyPayment, closeTo(10000, 0.01));
      expect(result.totalInterest, closeTo(0, 1));
    });

    test('standard Pag-IBIG rate produces reasonable payment', () {
      // 2M loan at 6.5% for 30 years
      final result = calculateAmortization(2000000, 0.065, 30);
      expect(result.monthlyPayment, greaterThan(10000));
      expect(result.monthlyPayment, lessThan(20000));
      expect(result.totalInterest, greaterThan(result.loanAmount)); // Interest > principal for long terms
    });

    test('total paid = monthly * months', () {
      final result = calculateAmortization(1000000, 0.08, 15);
      expect(result.totalPaid, closeTo(result.monthlyPayment * 180, 1));
    });

    test('total interest = total paid - loan amount', () {
      final result = calculateAmortization(1000000, 0.08, 15);
      expect(result.totalInterest, closeTo(result.totalPaid - result.loanAmount, 1));
    });
  });

  group('Rent vs Buy Comparison', () {
    test('returns 5 time horizons', () {
      final results = compareRentVsBuy(const RentVsBuyParams(
        propertyPrice: 3000000,
        downPaymentPercent: 20,
        loanRate: 0.065,
        loanTermYears: 30,
        monthlyRent: 15000,
        annualRentIncrease: 0.05,
        annualPropertyAppreciation: 0.03,
        monthlyAssociationDues: 3000,
        annualPropertyTaxRate: 0.01,
      ));
      expect(results.length, 5);
      expect(results.map((r) => r.years).toList(), [5, 10, 15, 20, 30]);
    });

    test('rent total increases over time', () {
      final results = compareRentVsBuy(const RentVsBuyParams(
        propertyPrice: 3000000,
        downPaymentPercent: 20,
        loanRate: 0.065,
        loanTermYears: 30,
        monthlyRent: 15000,
        annualRentIncrease: 0.05,
        annualPropertyAppreciation: 0.03,
        monthlyAssociationDues: 3000,
        annualPropertyTaxRate: 0.01,
      ));
      for (int i = 1; i < results.length; i++) {
        expect(results[i].totalRent, greaterThan(results[i - 1].totalRent));
      }
    });

    test('buy equity increases with property appreciation', () {
      final results = compareRentVsBuy(const RentVsBuyParams(
        propertyPrice: 3000000,
        downPaymentPercent: 20,
        loanRate: 0.065,
        loanTermYears: 30,
        monthlyRent: 15000,
        annualRentIncrease: 0.05,
        annualPropertyAppreciation: 0.03,
        monthlyAssociationDues: 3000,
        annualPropertyTaxRate: 0.01,
      ));
      for (int i = 1; i < results.length; i++) {
        expect(results[i].buyEquity, greaterThan(results[i - 1].buyEquity));
      }
    });
  });
}
