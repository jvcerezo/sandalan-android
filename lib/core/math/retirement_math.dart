/// SSS pension estimation and retirement projection utilities.
/// Direct port of retirement-math.ts.

import 'dart:math' as math;

// ─── Types ────────────────────────────────────────────────────────────────────

class SSSPensionEstimate {
  final double monthlyPension;
  final double averageMSC;
  final int creditedYears;
  final String formula;

  const SSSPensionEstimate({
    required this.monthlyPension,
    required this.averageMSC,
    required this.creditedYears,
    required this.formula,
  });
}

class RetirementProjection {
  final SSSPensionEstimate sssPension;
  final double desiredMonthlyIncome;
  final double monthlyGap;
  final double totalSavingsNeeded;
  final double currentSavings;
  final double savingsShortfall;
  final double requiredMonthlySavings;
  final int yearsToRetirement;

  const RetirementProjection({
    required this.sssPension,
    required this.desiredMonthlyIncome,
    required this.monthlyGap,
    required this.totalSavingsNeeded,
    required this.currentSavings,
    required this.savingsShortfall,
    required this.requiredMonthlySavings,
    required this.yearsToRetirement,
  });
}

// ─── Functions ────────────────────────────────────────────────────────────────

/// Estimate SSS monthly pension based on average MSC and credited years.
/// Formula: max(P300 + 20% AMSC + 2% AMSC * (CYS - 10), P1,200, 40% AMSC)
SSSPensionEstimate estimateSSSPension(
  double averageMSC,
  int creditedYears,
) {
  if (creditedYears < 10) {
    return SSSPensionEstimate(
      monthlyPension: 0,
      averageMSC: averageMSC,
      creditedYears: creditedYears,
      formula: 'Minimum 10 years (120 months) of contributions required',
    );
  }

  final formula1 =
      300 + averageMSC * 0.2 + averageMSC * 0.02 * (creditedYears - 10);
  const formula2 = 1200.0;
  final formula3 = averageMSC * 0.4;
  final monthlyPension =
      _round2(math.max(formula1, math.max(formula2, formula3)));

  return SSSPensionEstimate(
    monthlyPension: monthlyPension,
    averageMSC: averageMSC,
    creditedYears: creditedYears,
    formula:
        'max(P300 + 20% × P${averageMSC.toStringAsFixed(0)} + 2% × P${averageMSC.toStringAsFixed(0)} × ${creditedYears - 10}, P1,200, 40% × P${averageMSC.toStringAsFixed(0)})',
  );
}

/// Project retirement readiness. Uses 4% safe withdrawal rule.
RetirementProjection projectRetirement({
  required int currentAge,
  required int retirementAge,
  required double monthlySalary,
  required double currentSavings,
  required double desiredMonthlyIncome,
  required int contributionYears,
}) {
  // Estimate MSC (clamped)
  final msc = math.min(
      30000.0, math.max(4000.0, (monthlySalary / 500).round() * 500.0));
  final totalCYS =
      contributionYears + math.max<int>(0, retirementAge - currentAge);
  final sssPension = estimateSSSPension(msc, math.min<int>(totalCYS, 40));

  final monthlyGap =
      math.max(0.0, desiredMonthlyIncome - sssPension.monthlyPension);

  // 4% rule
  final annualGap = monthlyGap * 12;
  final totalSavingsNeeded =
      annualGap > 0 ? (annualGap / 0.04).roundToDouble() : 0.0;
  final savingsShortfall =
      math.max(0.0, totalSavingsNeeded - currentSavings);

  final yearsToRetirement = math.max(0, retirementAge - currentAge);
  final monthsToRetirement = yearsToRetirement * 12;

  // Required monthly savings assuming 7% annual returns (MP2-like)
  double requiredMonthlySavings = 0;
  if (monthsToRetirement > 0 && savingsShortfall > 0) {
    const monthlyRate = 0.07 / 12;
    final futureCurrentSavings =
        currentSavings * math.pow(1 + monthlyRate, monthsToRetirement);
    final remaining = totalSavingsNeeded - futureCurrentSavings;
    if (remaining > 0) {
      final fvFactor =
          (math.pow(1 + monthlyRate, monthsToRetirement) - 1) / monthlyRate;
      requiredMonthlySavings = _round2(remaining / fvFactor);
    }
  }

  return RetirementProjection(
    sssPension: sssPension,
    desiredMonthlyIncome: desiredMonthlyIncome,
    monthlyGap: monthlyGap,
    totalSavingsNeeded: totalSavingsNeeded,
    currentSavings: currentSavings,
    savingsShortfall: savingsShortfall,
    requiredMonthlySavings: math.max(0, requiredMonthlySavings),
    yearsToRetirement: yearsToRetirement,
  );
}

double _round2(double value) => (value * 100).roundToDouble() / 100;
