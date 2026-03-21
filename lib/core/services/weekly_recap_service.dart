import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/local_transaction_repository.dart';
import '../../data/repositories/transaction_repository.dart';

/// Weekly financial recap data.
class WeeklyRecap {
  final double spent;
  final double saved;
  final String topCategory;
  final double topCategoryAmount;
  final double vsLastWeekPercent; // negative = spent more, positive = spent less
  final DateTime weekStart;
  final DateTime weekEnd;

  const WeeklyRecap({
    required this.spent,
    required this.saved,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.vsLastWeekPercent,
    required this.weekStart,
    required this.weekEnd,
  });
}

/// Service to compute and manage weekly financial recaps.
class WeeklyRecapService {
  WeeklyRecapService._();
  static final WeeklyRecapService instance = WeeklyRecapService._();

  /// Compute recap for the most recent complete Mon-Sun week.
  Future<WeeklyRecap?> getWeeklyRecap() async {
    try {
      final db = AppDatabase.instance;
      final client = Supabase.instance.client;
      final repo = LocalTransactionRepository(db, client);

      final now = DateTime.now();
      // Find the most recent Monday (start of current or last week)
      // If today is Sun/Mon/Tue we show LAST week's recap
      final daysSinceMonday = (now.weekday - 1) % 7;
      final thisWeekMonday = DateTime(now.year, now.month, now.day - daysSinceMonday);

      // Use last week for the recap
      final weekStart = thisWeekMonday.subtract(const Duration(days: 7));
      final weekEnd = thisWeekMonday.subtract(const Duration(days: 1));

      final thisWeekTxns = await repo.getTransactions(TransactionFilters(
        startDate: weekStart,
        endDate: weekEnd,
        pageSize: 100000,
      ));

      final confirmed = thisWeekTxns.where((t) => t.isConfirmed && t.transferId == null).toList();

      double spent = 0;
      double income = 0;
      final categorySpend = <String, double>{};

      for (final t in confirmed) {
        if (t.amount < 0) {
          final absAmt = t.amount.abs();
          spent += absAmt;
          final cat = t.category;
          if (cat.toLowerCase() != 'transfer' && cat.toLowerCase() != 'goal funding') {
            categorySpend[cat] = (categorySpend[cat] ?? 0) + absAmt;
          }
        } else {
          income += t.amount;
        }
      }

      final saved = income - spent;

      String topCategory = 'None';
      double topCategoryAmount = 0;
      if (categorySpend.isNotEmpty) {
        final sorted = categorySpend.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        topCategory = sorted.first.key;
        topCategoryAmount = sorted.first.value;
      }

      // Previous week for comparison
      final prevWeekStart = weekStart.subtract(const Duration(days: 7));
      final prevWeekEnd = weekStart.subtract(const Duration(days: 1));

      final prevTxns = await repo.getTransactions(TransactionFilters(
        startDate: prevWeekStart,
        endDate: prevWeekEnd,
        pageSize: 100000,
      ));

      final prevConfirmed = prevTxns.where((t) => t.isConfirmed && t.transferId == null).toList();
      double prevSpent = 0;
      for (final t in prevConfirmed) {
        if (t.amount < 0) prevSpent += t.amount.abs();
      }

      double vsLastWeekPercent = 0;
      if (prevSpent > 0) {
        vsLastWeekPercent = ((prevSpent - spent) / prevSpent) * 100;
      }

      return WeeklyRecap(
        spent: spent,
        saved: saved,
        topCategory: topCategory,
        topCategoryAmount: topCategoryAmount,
        vsLastWeekPercent: vsLastWeekPercent,
        weekStart: weekStart,
        weekEnd: weekEnd,
      );
    } catch (_) {
      return null;
    }
  }

  /// Recap is visible Sun-Tue and not dismissed for this week.
  Future<bool> isRecapVisible() async {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Mon, 7=Sun
    if (weekday != 7 && weekday != 1 && weekday != 2) return false;

    final prefs = await SharedPreferences.getInstance();
    final weekKey = _weekKey(now);
    return !(prefs.getBool('dismissed_recap_week_$weekKey') ?? false);
  }

  /// Dismiss recap for the current week.
  Future<void> dismissRecap() async {
    final prefs = await SharedPreferences.getInstance();
    final weekKey = _weekKey(DateTime.now());
    await prefs.setBool('dismissed_recap_week_$weekKey', true);
  }

  String _weekKey(DateTime d) {
    // ISO week number
    final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays;
    final weekNumber = ((dayOfYear - d.weekday + 10) / 7).floor();
    return '${d.year}-${weekNumber.toString().padLeft(2, '0')}';
  }
}
