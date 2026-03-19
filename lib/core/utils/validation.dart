/// Input validation constants and guards.
/// Direct port of validation.ts.

import 'dart:math' as math;

// ─── Amount Limits ────────────────────────────────────────────────────────────

/// Maximum amount for any monetary input (₱999,999,999.99).
const double kMaxAmount = 999999999.99;

/// Maximum salary input.
const double kMaxSalary = 9999999;

/// Maximum interest rate (%).
const double kMaxInterestRate = 100;

/// Maximum loan/calculator term in years.
const int kMaxTermYears = 100;

// ─── String Limits ────────────────────────────────────────────────────────────

/// Max length for names (accounts, goals, debts, bills, policies).
const int kMaxNameLength = 100;

/// Max length for descriptions and notes.
const int kMaxDescriptionLength = 500;

/// Max length for provider/lender names.
const int kMaxProviderLength = 100;

/// Max length for short labels (categories, tags).
const int kMaxLabelLength = 50;

// ─── Date Limits ──────────────────────────────────────────────────────────────

/// Earliest reasonable date (Jan 1, 2000).
const String kMinDate = '2000-01-01';

/// Get a max date string (10 years from now).
String getMaxDate() {
  final d = DateTime.now().add(const Duration(days: 3650));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Get today's date as YYYY-MM-DD.
String getTodayDate() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ─── Math Guards ──────────────────────────────────────────────────────────────

/// Clamp a number to a safe range.
double clampAmount(double value) {
  if (value.isNaN || value.isInfinite) return 0;
  return value.clamp(-kMaxAmount, kMaxAmount);
}

/// Safe division that returns [fallback] instead of Infinity/NaN.
double safeDivide(double numerator, double denominator, [double fallback = 0]) {
  if (denominator == 0 || denominator.isInfinite) return fallback;
  final result = numerator / denominator;
  if (result.isInfinite || result.isNaN) return fallback;
  return result;
}

/// Safe percentage (0-100).
double safePercent(double part, double whole) {
  return math.min(100, math.max(0, safeDivide(part, whole) * 100));
}
