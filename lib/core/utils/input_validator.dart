/// Centralized input validation and sanitization for all data writes.
/// Applied at the repository level so validation cannot be bypassed by UI bugs.
///
/// Usage:
///   final name = InputValidator.name(rawName);
///   final amount = InputValidator.amount(rawAmount);

import 'input_sanitizer.dart';

class InputValidator {
  InputValidator._();

  // ─── Constants ──────────────────────────────────────────────────────────────

  static const maxAmount = 999999999.99;
  static const maxSalary = 9999999.0;
  static const maxInterestRate = 100.0;
  static const maxNameLength = 100;
  static const maxDescriptionLength = 500;
  static const maxProviderLength = 100;
  static const maxLabelLength = 50;
  static const maxTagCount = 20;
  static const maxChatMessage = 2000;

  // ─── String validators ──────────────────────────────────────────────────────

  /// Sanitize and truncate a name field. Returns empty string for null/blank.
  static String name(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    return InputSanitizer.sanitize(value, maxLength: maxNameLength);
  }

  /// Require a non-empty name. Throws on blank.
  static String requireName(String? value, [String field = 'Name']) {
    final result = name(value);
    if (result.isEmpty) throw ArgumentError('$field is required');
    return result;
  }

  /// Sanitize a description/notes field.
  static String description(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    return InputSanitizer.sanitize(value, maxLength: maxDescriptionLength);
  }

  /// Sanitize a category or tag label.
  static String label(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    return InputSanitizer.sanitize(value, maxLength: maxLabelLength);
  }

  /// Sanitize a provider/lender name.
  static String provider(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    return InputSanitizer.sanitize(value, maxLength: maxProviderLength);
  }

  /// Sanitize a chat message.
  static String chatMessage(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    return InputSanitizer.sanitize(value, maxLength: maxChatMessage);
  }

  /// Sanitize a comma-separated tags string. Returns sanitized string.
  static String tags(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final parts = value
        .split(',')
        .map((t) => label(t))
        .where((t) => t.isNotEmpty)
        .take(maxTagCount)
        .toList();
    return parts.join(',');
  }

  // ─── Numeric validators ─────────────────────────────────────────────────────

  /// Validate and clamp a monetary amount. Returns 0 for null/NaN/Infinity.
  static double amount(dynamic value) {
    final num = _toDouble(value);
    if (num.isNaN || num.isInfinite) return 0;
    return num.clamp(-maxAmount, maxAmount);
  }

  /// Validate a positive monetary amount (balance, target, etc.).
  static double positiveAmount(dynamic value) {
    final num = amount(value);
    return num < 0 ? 0 : num;
  }

  /// Require a non-zero amount. Throws on zero/null/NaN.
  static double requireAmount(dynamic value, [String field = 'Amount']) {
    final num = amount(value);
    if (num == 0) throw ArgumentError('$field is required');
    return num;
  }

  /// Validate an interest rate (0–100%).
  static double interestRate(dynamic value) {
    final num = _toDouble(value);
    if (num.isNaN || num.isInfinite) return 0;
    return num.clamp(0, maxInterestRate);
  }

  /// Validate a salary amount.
  static double salary(dynamic value) {
    final num = _toDouble(value);
    if (num.isNaN || num.isInfinite) return 0;
    return num.clamp(0, maxSalary);
  }

  /// Validate a day of month (1–31). Returns null if invalid.
  static int? dayOfMonth(dynamic value) {
    final num = _toInt(value);
    if (num == null || num < 1 || num > 31) return null;
    return num;
  }

  // ─── Date validators ────────────────────────────────────────────────────────

  /// Validate a date string (YYYY-MM-DD). Returns today if invalid.
  static String date(String? value) {
    if (value == null || value.isEmpty) return _today();
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return _today();
    return value;
  }

  /// Validate a DateTime. Returns now if null.
  static DateTime dateTime(DateTime? value) {
    return value ?? DateTime.now();
  }

  // ─── UUID validator ─────────────────────────────────────────────────────────

  static final _uuidRe = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Validate a UUID. Returns null if invalid.
  static String? uuid(String? value) {
    if (value == null || !_uuidRe.hasMatch(value)) return null;
    return value;
  }

  /// Require a valid UUID. Throws on invalid.
  static String requireUuid(String? value, [String field = 'ID']) {
    final result = uuid(value);
    if (result == null) throw ArgumentError('Invalid $field');
    return result;
  }

  // ─── Enum validator ─────────────────────────────────────────────────────────

  /// Validate a value is in the allowed set. Returns null if not found.
  static String? enumValue(String? value, List<String> allowed) {
    if (value == null || !allowed.contains(value)) return null;
    return value;
  }

  /// Require a valid enum value. Throws if not in allowed set.
  static String requireEnum(String? value, List<String> allowed, [String field = 'Value']) {
    final result = enumValue(value, allowed);
    if (result == null) throw ArgumentError('Invalid $field: $value');
    return result;
  }

  // ─── Currency ───────────────────────────────────────────────────────────────

  /// Validate and normalize a currency code. Defaults to PHP.
  static String currency(String? value) {
    if (value == null || value.trim().isEmpty) return 'PHP';
    final code = value.trim().toUpperCase();
    if (code.length > 10) return 'PHP';
    return code;
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '')) ?? 0;
    return 0;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.isFinite ? value.toInt() : null;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
