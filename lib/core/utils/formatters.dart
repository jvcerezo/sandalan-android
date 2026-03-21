/// Currency and date formatting utilities.

import 'package:intl/intl.dart';
import '../constants/currencies.dart';

/// Format a number as currency with the given currency code.
String formatCurrency(double amount, {String currencyCode = 'PHP'}) {
  final symbol = currencySymbol(currencyCode);
  final formatter = NumberFormat.currency(
    symbol: symbol,
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

/// Format currency respecting hide-balances and compact mode.
///
/// [hidden] — when true, returns masked dots.
/// [compact] — when true, abbreviates large amounts (108.7K, 1.2M).
String displayAmount(double amount, {
  bool hidden = false,
  bool compact = false,
  String currencyCode = 'PHP',
}) {
  if (hidden) return '\u2022\u2022\u2022\u2022';
  if (compact) return formatDisplayCurrency(amount, currencyCode: currencyCode);
  return formatCurrency(amount, currencyCode: currencyCode);
}

/// Format a currency value compactly for dashboard/home display.
String formatDisplayCurrency(double amount, {String currencyCode = 'PHP'}) {
  final symbol = currencySymbol(currencyCode);
  final abs = amount.abs();
  final sign = amount < 0 ? '-' : '';
  if (abs >= 1000000) return '$sign$symbol${(abs / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '$sign$symbol${(abs / 1000).toStringAsFixed(1)}K';
  return formatCurrency(amount, currencyCode: currencyCode);
}

/// Format a number compactly (e.g., 1.2K, 3.5M).
String formatCompact(double amount) {
  return NumberFormat.compact().format(amount);
}

/// Format a date as "MMM d, yyyy" (e.g., "Mar 20, 2026").
String formatDate(DateTime date) {
  return DateFormat('MMM d, yyyy').format(date);
}

/// Format a date as "YYYY-MM-DD".
String formatDateIso(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

/// Format a date as relative (e.g., "Today", "Yesterday", "Mar 18").
String formatDateRelative(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly = DateTime(date.year, date.month, date.day);
  final diff = today.difference(dateOnly).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat('EEEE').format(date);
  return DateFormat('MMM d').format(date);
}

/// Get a greeting based on the current time.
String getTimeGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// Get a Filipino greeting based on the current time.
String getTimeGreetingFilipino() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Magandang umaga';
  if (hour < 17) return 'Magandang hapon';
  return 'Magandang gabi';
}
