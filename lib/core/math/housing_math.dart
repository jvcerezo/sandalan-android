/// Philippine housing affordability and Pag-IBIG loan calculations.
/// Direct port of housing-math.ts.

import 'dart:math' as math;

// ─── Types ────────────────────────────────────────────────────────────────────

class LoanAmortization {
  final double monthlyPayment;
  final double totalPaid;
  final double totalInterest;
  final double loanAmount;
  final double annualRate;
  final int termYears;

  const LoanAmortization({
    required this.monthlyPayment,
    required this.totalPaid,
    required this.totalInterest,
    required this.loanAmount,
    required this.annualRate,
    required this.termYears,
  });
}

class RentVsBuyComparison {
  final int years;
  final double totalRent;
  final double totalBuyCost;
  final double buyEquity;
  final double rentAdvantage; // positive = renting is cheaper
  final int? breakEvenYear;

  const RentVsBuyComparison({
    required this.years,
    required this.totalRent,
    required this.totalBuyCost,
    required this.buyEquity,
    required this.rentAdvantage,
    required this.breakEvenYear,
  });
}

class RentVsBuyParams {
  final double propertyPrice;
  final double downPaymentPercent;
  final double loanRate;
  final int loanTermYears;
  final double monthlyRent;
  final double annualRentIncrease;
  final double annualPropertyAppreciation;
  final double monthlyAssociationDues;
  final double annualPropertyTaxRate;

  const RentVsBuyParams({
    required this.propertyPrice,
    required this.downPaymentPercent,
    required this.loanRate,
    required this.loanTermYears,
    required this.monthlyRent,
    required this.annualRentIncrease,
    required this.annualPropertyAppreciation,
    required this.monthlyAssociationDues,
    required this.annualPropertyTaxRate,
  });
}

// ─── Functions ────────────────────────────────────────────────────────────────

/// Calculate monthly amortization using standard PMT formula.
LoanAmortization calculateAmortization(
  double loanAmount,
  double annualRate,
  int termYears,
) {
  final monthlyRate = annualRate / 12;
  final numPayments = termYears * 12;

  double monthlyPayment;
  if (monthlyRate == 0) {
    monthlyPayment = loanAmount / numPayments;
  } else {
    monthlyPayment = (loanAmount *
            monthlyRate *
            math.pow(1 + monthlyRate, numPayments)) /
        (math.pow(1 + monthlyRate, numPayments) - 1);
  }

  monthlyPayment = _round2(monthlyPayment);
  final totalPaid = _round2(monthlyPayment * numPayments);

  return LoanAmortization(
    monthlyPayment: monthlyPayment,
    totalPaid: totalPaid,
    totalInterest: _round2(totalPaid - loanAmount),
    loanAmount: loanAmount,
    annualRate: annualRate,
    termYears: termYears,
  );
}

/// Compare total costs of renting vs buying over multiple time horizons.
List<RentVsBuyComparison> compareRentVsBuy(RentVsBuyParams params) {
  final downPayment = params.propertyPrice * (params.downPaymentPercent / 100);
  final loanAmount = params.propertyPrice - downPayment;
  final loan = calculateAmortization(
    loanAmount,
    params.loanRate,
    params.loanTermYears,
  );

  const horizons = [5, 10, 15, 20, 30];
  int? breakEvenYear;

  return horizons.map((years) {
    // Rent total
    double totalRent = 0;
    double currentRent = params.monthlyRent;
    for (int y = 0; y < years; y++) {
      totalRent += currentRent * 12;
      currentRent *= 1 + params.annualRentIncrease;
    }
    totalRent = totalRent.roundToDouble();

    // Buy total
    final amortMonths = math.min(years * 12, params.loanTermYears * 12);
    final amortCost = loan.monthlyPayment * amortMonths;
    final duesCost = params.monthlyAssociationDues * years * 12;
    final taxCost = params.propertyPrice * params.annualPropertyTaxRate * years;
    final totalBuyCost =
        (downPayment + amortCost + duesCost + taxCost).roundToDouble();

    // Equity
    final propertyValue = params.propertyPrice *
        math.pow(1 + params.annualPropertyAppreciation, years);
    final buyEquity = propertyValue.roundToDouble();

    final rentAdvantage = totalBuyCost - totalRent;

    if (breakEvenYear == null && rentAdvantage < 0) {
      breakEvenYear = years;
    }

    return RentVsBuyComparison(
      years: years,
      totalRent: totalRent,
      totalBuyCost: totalBuyCost,
      buyEquity: buyEquity,
      rentAdvantage: rentAdvantage,
      breakEvenYear: breakEvenYear,
    );
  }).toList();
}

double _round2(double value) => (value * 100).roundToDouble() / 100;
