/// Philippine government contribution and tax calculation utilities.
/// Rates based on 2024 schedules — direct port of ph-math.ts.

import 'dart:math' as math;
import '../constants/ph_rates.dart';

// ─── Result types ─────────────────────────────────────────────────────────────

class SSSContribution {
  final double msc;
  final double employee;
  final double employer;
  final double ec;
  final double total;

  const SSSContribution({
    required this.msc,
    required this.employee,
    required this.employer,
    required this.ec,
    required this.total,
  });
}

class PhilHealthContribution {
  final double monthlySalary;
  final double employee;
  final double employer;
  final double total;

  const PhilHealthContribution({
    required this.monthlySalary,
    required this.employee,
    required this.employer,
    required this.total,
  });
}

class PagIbigContribution {
  final double employee;
  final double employer;
  final double total;

  const PagIbigContribution({
    required this.employee,
    required this.employer,
    required this.total,
  });
}

class GovernmentDeductions {
  final SSSContribution sss;
  final PhilHealthContribution philhealth;
  final PagIbigContribution pagibig;
  final double totalEmployee;
  final double totalEmployer;
  final double netTakeHome;

  const GovernmentDeductions({
    required this.sss,
    required this.philhealth,
    required this.pagibig,
    required this.totalEmployee,
    required this.totalEmployer,
    required this.netTakeHome,
  });
}

class TaxComputation {
  final double grossAnnual;
  final double nonTaxableBenefits;
  final double taxableIncome;
  final double taxDue;
  final double effectiveRate;
  final double quarterlyEstimate;

  const TaxComputation({
    required this.grossAnnual,
    required this.nonTaxableBenefits,
    required this.taxableIncome,
    required this.taxDue,
    required this.effectiveRate,
    required this.quarterlyEstimate,
  });
}

class ThirteenthMonthResult {
  final double gross;
  final double taxExemptPortion;
  final double taxable;

  const ThirteenthMonthResult({
    required this.gross,
    required this.taxExemptPortion,
    required this.taxable,
  });
}

// ─── SSS ──────────────────────────────────────────────────────────────────────

/// Compute SSS Monthly Salary Credit and contributions.
SSSContribution calculateSSS(
  double monthlySalary, {
  EmploymentType employmentType = EmploymentType.employed,
}) {
  // Determine MSC (rounded to nearest 500, clamped to min/max)
  double msc;
  if (monthlySalary < 3250) {
    msc = SSSRate.minMsc;
  } else if (monthlySalary >= 29750) {
    msc = SSSRate.maxMsc;
  } else {
    msc = (monthlySalary / 500).round() * 500.0;
  }

  final isSelfPay = employmentType == EmploymentType.selfEmployed ||
      employmentType == EmploymentType.ofw;

  final employee =
      isSelfPay ? (msc * SSSRate.total).roundToDouble() : (msc * SSSRate.employee).roundToDouble();
  final employer = isSelfPay ? 0.0 : (msc * SSSRate.employer).roundToDouble();

  // EC premium: ₱10 for MSC ≤ ₱14,500, ₱30 above (employer only)
  final ec = employmentType == EmploymentType.employed
      ? (msc <= 14500 ? SSSRate.ecMin : SSSRate.ecMax)
      : 0.0;

  return SSSContribution(
    msc: msc,
    employee: employee,
    employer: employer,
    ec: ec,
    total: employee + employer + ec,
  );
}

// ─── PhilHealth ───────────────────────────────────────────────────────────────

/// Compute PhilHealth premium.
PhilHealthContribution calculatePhilHealth(
  double monthlySalary, {
  EmploymentType employmentType = EmploymentType.employed,
}) {
  final clampedSalary = monthlySalary.clamp(PhilHealthRate.minSalary, PhilHealthRate.maxSalary);
  final totalPremium = _round2(clampedSalary * PhilHealthRate.rate);

  final isSelfPay = employmentType == EmploymentType.selfEmployed ||
      employmentType == EmploymentType.ofw;

  final employee =
      isSelfPay ? totalPremium : _round2(clampedSalary * PhilHealthRate.employee);
  final employer =
      isSelfPay ? 0.0 : _round2(clampedSalary * PhilHealthRate.employer);

  return PhilHealthContribution(
    monthlySalary: clampedSalary,
    employee: employee,
    employer: employer,
    total: employee + employer,
  );
}

// ─── Pag-IBIG ─────────────────────────────────────────────────────────────────

/// Compute Pag-IBIG mandatory contribution.
PagIbigContribution calculatePagIbig(
  double monthlySalary, {
  EmploymentType employmentType = EmploymentType.employed,
}) {
  final base = math.min(monthlySalary, PagIbigRate.maxCompensation);
  final isHigh = monthlySalary > PagIbigRate.salaryThreshold;

  final isSelfPay = employmentType == EmploymentType.selfEmployed ||
      employmentType == EmploymentType.ofw;

  final employeeRate = isHigh ? PagIbigRate.employeeHigh : PagIbigRate.employeeLow;
  final employerRate = isHigh ? PagIbigRate.employerHigh : PagIbigRate.employerLow;

  final employee = _round2(base * employeeRate);
  final employer = isSelfPay ? 0.0 : _round2(base * employerRate);

  return PagIbigContribution(
    employee: employee,
    employer: employer,
    total: employee + employer,
  );
}

// ─── Combined ─────────────────────────────────────────────────────────────────

/// Compute all three government deductions together.
GovernmentDeductions calculateGovernmentDeductions(
  double monthlySalary, {
  EmploymentType employmentType = EmploymentType.employed,
}) {
  final sss = calculateSSS(monthlySalary, employmentType: employmentType);
  final philhealth = calculatePhilHealth(monthlySalary, employmentType: employmentType);
  final pagibig = calculatePagIbig(monthlySalary, employmentType: employmentType);

  final totalEmployee = sss.employee + philhealth.employee + pagibig.employee;
  final totalEmployer = sss.employer + sss.ec + philhealth.employer + pagibig.employer;

  return GovernmentDeductions(
    sss: sss,
    philhealth: philhealth,
    pagibig: pagibig,
    totalEmployee: totalEmployee,
    totalEmployer: totalEmployer,
    netTakeHome: monthlySalary - totalEmployee,
  );
}

// ─── TRAIN Law Income Tax ─────────────────────────────────────────────────────

/// Compute annual income tax under the TRAIN Law (2023+).
TaxComputation computeIncomeTax(
  double grossAnnualIncome, {
  double nonTaxableBenefits = 0,
}) {
  final taxableIncome = math.max(0.0, grossAnnualIncome - nonTaxableBenefits);

  double taxDue = 0;
  for (final bracket in kTrainTaxBrackets) {
    if (taxableIncome > bracket.min) {
      final upperBound =
          bracket.max == double.infinity ? taxableIncome : bracket.max;
      final taxableInBracket = math.min(taxableIncome, upperBound) - bracket.min;
      taxDue = bracket.base + taxableInBracket * bracket.rate;
    }
  }

  final effectiveRate = taxableIncome > 0 ? taxDue / taxableIncome : 0.0;

  return TaxComputation(
    grossAnnual: grossAnnualIncome,
    nonTaxableBenefits: nonTaxableBenefits,
    taxableIncome: taxableIncome,
    taxDue: _round2(taxDue),
    effectiveRate: _round2(effectiveRate * 100), // as percentage
    quarterlyEstimate: _round2(taxDue / 4),
  );
}

/// Compute optional 8% flat income tax for self-employed.
TaxComputation computeFlatTax(double grossAnnualIncome) {
  final taxable = math.max(0.0, grossAnnualIncome - 250000);
  final taxDue = taxable * 0.08;

  return TaxComputation(
    grossAnnual: grossAnnualIncome,
    nonTaxableBenefits: 0,
    taxableIncome: taxable,
    taxDue: _round2(taxDue),
    effectiveRate: grossAnnualIncome > 0
        ? _round2((taxDue / grossAnnualIncome) * 100)
        : 0,
    quarterlyEstimate: _round2(taxDue / 4),
  );
}

// ─── 13th Month ───────────────────────────────────────────────────────────────

/// Calculate 13th month pay. First ₱90,000 is tax-exempt.
ThirteenthMonthResult calculate13thMonth(
  double basicMonthlySalary, {
  int monthsWorked = 12,
}) {
  final gross = (basicMonthlySalary / 12) * monthsWorked;
  const taxExemptCap = 90000.0;
  final taxExemptPortion = math.min(gross, taxExemptCap);
  final taxable = math.max(0.0, gross - taxExemptCap);

  return ThirteenthMonthResult(
    gross: _round2(gross),
    taxExemptPortion: _round2(taxExemptPortion),
    taxable: _round2(taxable),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

double _round2(double value) => (value * 100).roundToDouble() / 100;
