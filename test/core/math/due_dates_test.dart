import 'package:flutter_test/flutter_test.dart';
import 'package:sandalan/core/math/due_dates.dart';

void main() {
  group('getUrgencyLabel', () {
    test('negative days = Overdue, red', () {
      final result = getUrgencyLabel(-1);
      expect(result.label, 'Overdue');
      expect(result.color, 'red');
    });

    test('0 days = Due today, amber', () {
      final result = getUrgencyLabel(0);
      expect(result.label, 'Due today');
      expect(result.color, 'amber');
    });

    test('3 days = 3d, amber', () {
      final result = getUrgencyLabel(3);
      expect(result.label, '3d');
      expect(result.color, 'amber');
    });

    test('7 days = 7d, muted', () {
      final result = getUrgencyLabel(7);
      expect(result.label, '7d');
      expect(result.color, 'muted');
    });

    test('30 days = 30d, muted', () {
      final result = getUrgencyLabel(30);
      expect(result.label, '30d');
      expect(result.color, 'muted');
    });
  });

  group('daysUntil', () {
    test('future date returns positive', () {
      final future = DateTime.now().add(const Duration(days: 5));
      expect(daysUntil(future), greaterThanOrEqualTo(4));
    });

    test('past date returns negative', () {
      final past = DateTime.now().subtract(const Duration(days: 3));
      expect(daysUntil(past), lessThan(0));
    });

    test('today returns 0', () {
      final today = DateTime.now();
      final normalized = DateTime(today.year, today.month, today.day);
      expect(daysUntil(normalized), 0);
    });
  });

  group('getNextDebtDueDate', () {
    test('null dueDay returns null', () {
      expect(getNextDebtDueDate(null), isNull);
    });

    test('returns a date in the current or next month', () {
      final result = getNextDebtDueDate(15);
      expect(result, isNotNull);
      final now = DateTime.now();
      // Should be within the next ~31 days
      expect(result!.difference(DateTime(now.year, now.month, now.day)).inDays,
          greaterThanOrEqualTo(0));
      expect(result.difference(DateTime(now.year, now.month, now.day)).inDays,
          lessThanOrEqualTo(31));
    });
  });

  group('getNextBillDueDate', () {
    test('null dueDay returns null', () {
      expect(getNextBillDueDate(null, 'monthly', null), isNull);
    });

    test('monthly bill returns a future date', () {
      final result = getNextBillDueDate(15, 'monthly', null);
      expect(result, isNotNull);
    });

    test('quarterly bill skips 3 months from last paid', () {
      final now = DateTime.now();
      final lastPaid = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final result = getNextBillDueDate(1, 'quarterly', lastPaid);
      expect(result, isNotNull);
      // Should be ~3 months from last paid
      final diffDays = result!.difference(DateTime(now.year, now.month, 1)).inDays;
      expect(diffDays, greaterThanOrEqualTo(80)); // ~3 months
    });

    test('annual bill skips 12 months', () {
      final now = DateTime.now();
      final lastPaid = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final result = getNextBillDueDate(1, 'annual', lastPaid);
      expect(result, isNotNull);
      final diffDays = result!.difference(DateTime(now.year, now.month, 1)).inDays;
      expect(diffDays, greaterThanOrEqualTo(350)); // ~12 months
    });

    test('day 31 in February clamps to 28/29', () {
      // Force a February date
      final result = getNextBillDueDate(31, 'monthly', '2026-01-31');
      expect(result, isNotNull);
      expect(result!.day, lessThanOrEqualTo(29)); // Feb can't have day 31
    });
  });

  group('getCurrentContributionPeriod', () {
    test('returns YYYY-MM format', () {
      final period = getCurrentContributionPeriod();
      expect(period, matches(RegExp(r'^\d{4}-\d{2}$')));
    });
  });
}
