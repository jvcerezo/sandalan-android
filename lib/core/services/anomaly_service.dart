import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/local_transaction_repository.dart';
import '../../data/repositories/transaction_repository.dart';

/// Detects unusual spending patterns by comparing current week vs
/// rolling 4-week average per category.
class AnomalyService {
  AnomalyService._();

  /// Check for anomalies in this week's spending.
  /// Returns a list of human-readable alerts, empty if nothing unusual.
  static Future<List<SpendingAnomaly>> detect() async {
    try {
      final db = AppDatabase.instance;
      final client = Supabase.instance.client;
      final repo = LocalTransactionRepository(db, client);

      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);

      // This week's expenses
      final thisWeekTxns = await repo.getTransactions(TransactionFilters(
        type: 'expense',
        startDate: weekStart,
        endDate: now,
      ));

      // Last 4 weeks' expenses (for average)
      final fourWeeksAgo = weekStart.subtract(const Duration(days: 28));
      final historicalTxns = await repo.getTransactions(TransactionFilters(
        type: 'expense',
        startDate: fourWeeksAgo,
        endDate: weekStart.subtract(const Duration(days: 1)),
      ));

      if (historicalTxns.isEmpty) return []; // Not enough data

      // Group by category
      final thisWeekByCategory = <String, double>{};
      for (final t in thisWeekTxns) {
        thisWeekByCategory[t.category] =
            (thisWeekByCategory[t.category] ?? 0) + t.amount.abs();
      }

      final historicalByCategory = <String, double>{};
      for (final t in historicalTxns) {
        historicalByCategory[t.category] =
            (historicalByCategory[t.category] ?? 0) + t.amount.abs();
      }

      // Compare: weekly average (divide by 4) vs this week
      final anomalies = <SpendingAnomaly>[];
      for (final entry in thisWeekByCategory.entries) {
        final weeklyAvg = (historicalByCategory[entry.key] ?? 0) / 4;
        if (weeklyAvg < 100) continue; // Ignore tiny categories

        final ratio = entry.value / weeklyAvg;
        if (ratio >= 2.0) {
          anomalies.add(SpendingAnomaly(
            category: entry.key,
            thisWeek: entry.value,
            weeklyAverage: weeklyAvg,
            multiplier: ratio,
          ));
        }
      }

      // Also check total spending
      final thisWeekTotal = thisWeekTxns.fold<double>(0, (sum, t) => sum + t.amount.abs());
      final historicalTotal = historicalTxns.fold<double>(0, (sum, t) => sum + t.amount.abs());
      final avgWeeklyTotal = historicalTotal / 4;

      if (avgWeeklyTotal >= 500 && thisWeekTotal / avgWeeklyTotal >= 1.5) {
        anomalies.insert(0, SpendingAnomaly(
          category: 'Overall',
          thisWeek: thisWeekTotal,
          weeklyAverage: avgWeeklyTotal,
          multiplier: thisWeekTotal / avgWeeklyTotal,
        ));
      }

      // Sort by multiplier descending
      anomalies.sort((a, b) => b.multiplier.compareTo(a.multiplier));
      return anomalies.take(3).toList(); // Max 3 alerts
    } catch (_) {
      return [];
    }
  }
}

class SpendingAnomaly {
  final String category;
  final double thisWeek;
  final double weeklyAverage;
  final double multiplier;

  const SpendingAnomaly({
    required this.category,
    required this.thisWeek,
    required this.weeklyAverage,
    required this.multiplier,
  });

  String get message {
    final mult = multiplier.toStringAsFixed(1);
    if (category == 'Overall') {
      return 'You\'ve spent ${mult}x more than usual this week';
    }
    return '${mult}x more on $category this week vs your average';
  }
}
