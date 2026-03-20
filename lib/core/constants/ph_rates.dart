/// Philippine government contribution rates and tax brackets.
/// Based on 2024 schedules.

// ─── SSS 2024 ─────────────────────────────────────────────────────────────────

class SSSRate {
  static const double employee = 0.045;
  static const double employer = 0.095;
  static const double total = 0.14;
  static const double minMsc = 4000;
  static const double maxMsc = 30000;
  static const double ecMin = 10;
  static const double ecMax = 30;
}

// ─── PhilHealth 2024 ──────────────────────────────────────────────────────────

class PhilHealthRate {
  static const double rate = 0.05;
  static const double employee = 0.025;
  static const double employer = 0.025;
  static const double minSalary = 10000;
  static const double maxSalary = 100000;
}

// ─── Pag-IBIG / HDMF ─────────────────────────────────────────────────────────

class PagIbigRate {
  static const double employeeHigh = 0.02;
  static const double employerHigh = 0.02;
  static const double employeeLow = 0.01;
  static const double employerLow = 0.02;
  static const double salaryThreshold = 1500;
  static const double maxCompensation = 10000;
}

// ─── TRAIN Law Tax Brackets (2023+, annual) ───────────────────────────────────

class TaxBracket {
  final double min;
  final double max;
  final double base;
  final double rate;
  const TaxBracket({
    required this.min,
    required this.max,
    required this.base,
    required this.rate,
  });
}

const List<TaxBracket> kTrainTaxBrackets = [
  TaxBracket(min: 0, max: 250000, base: 0, rate: 0),
  TaxBracket(min: 250000, max: 400000, base: 0, rate: 0.15),
  TaxBracket(min: 400000, max: 800000, base: 22500, rate: 0.20),
  TaxBracket(min: 800000, max: 2000000, base: 102500, rate: 0.25),
  TaxBracket(min: 2000000, max: 8000000, base: 402500, rate: 0.30),
  TaxBracket(min: 8000000, max: double.infinity, base: 2202500, rate: 0.35),
];

// ─── Employment Types ─────────────────────────────────────────────────────────

enum EmploymentType {
  employed('Employed'),
  selfEmployed('Self-Employed / Freelancer'),
  voluntary('Voluntary Member'),
  ofw('OFW');

  final String label;
  const EmploymentType(this.label);
}

// ─── BIR Deadlines ────────────────────────────────────────────────────────────

class BirDeadline {
  final String label;
  final String form;
  final String due;
  const BirDeadline({
    required this.label,
    required this.form,
    required this.due,
  });
}

const List<BirDeadline> kBirDeadlines = [
  BirDeadline(label: 'Q1 (Jan–Mar)', form: '1701Q', due: 'May 15'),
  BirDeadline(label: 'Q2 (Apr–Jun)', form: '1701Q', due: 'August 15'),
  BirDeadline(label: 'Q3 (Jul–Sep)', form: '1701Q', due: 'November 15'),
  BirDeadline(label: 'Annual', form: '1701/1701A', due: 'April 15'),
];

// ─── Bill Categories ──────────────────────────────────────────────────────────

enum BillCategory {
  electricity,
  water,
  internet,
  mobile,
  cableTv,
  rent,
  associationDues,
  streaming,
  software,
  gym,
  other;

  String get label {
    switch (this) {
      case BillCategory.electricity: return 'Electricity';
      case BillCategory.water: return 'Water';
      case BillCategory.internet: return 'Internet';
      case BillCategory.mobile: return 'Mobile';
      case BillCategory.cableTv: return 'Cable TV';
      case BillCategory.rent: return 'Rent';
      case BillCategory.associationDues: return 'Association Dues';
      case BillCategory.streaming: return 'Streaming';
      case BillCategory.software: return 'Software';
      case BillCategory.gym: return 'Gym';
      case BillCategory.other: return 'Other';
    }
  }
}
