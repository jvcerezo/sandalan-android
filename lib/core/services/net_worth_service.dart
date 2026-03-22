import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../data/local/app_database.dart';

/// Records and retrieves daily net worth snapshots.
///
/// Net worth = sum of all account balances + goal savings - outstanding debts.
/// A breakdown per account is stored as JSON for drill-down later.
class NetWorthService {
  final AppDatabase _db;
  final String _userId;

  NetWorthService(this._db, this._userId);

  static int _counter = 0;
  static String _generateId() =>
      'nw-${DateTime.now().millisecondsSinceEpoch}-${_counter++}';

  /// Calculate current net worth from accounts, goals, and debts, then upsert
  /// today's snapshot. Safe to call multiple times per day (upserts on date).
  Future<void> recordSnapshot() async {
    try {
      final accounts = await _db.getAccounts(_userId);
      final goals = await _db.getGoals(_userId);
      final debts = await _db.getDebts(_userId);

      // Build per-account breakdown
      final breakdown = <String, dynamic>{};
      double accountsTotal = 0;
      for (final a in accounts) {
        final balance = (a['balance'] as num).toDouble();
        accountsTotal += balance;
        breakdown[a['name'] as String] = {
          'type': a['type'],
          'balance': balance,
        };
      }

      // Add goal savings
      double goalSavings = 0;
      for (final g in goals) {
        final current = (g['current_amount'] as num).toDouble();
        goalSavings += current;
      }
      if (goalSavings > 0) {
        breakdown['Goal Savings'] = {
          'type': 'goals',
          'balance': goalSavings,
        };
      }

      // Subtract outstanding debts
      double totalDebt = 0;
      for (final d in debts) {
        if ((d['is_paid_off'] as int) == 1) continue;
        final balance = (d['current_balance'] as num).toDouble();
        totalDebt += balance;
      }
      if (totalDebt > 0) {
        breakdown['Outstanding Debts'] = {
          'type': 'debts',
          'balance': -totalDebt,
        };
      }

      final total = accountsTotal + goalSavings - totalDebt;

      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await _db.upsertNetWorthSnapshot({
        'id': _generateId(),
        'user_id': _userId,
        'date': dateStr,
        'total': total,
        'breakdown': jsonEncode(breakdown),
        'created_at': AppDatabase.now(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('NetWorthService: recordSnapshot failed: $e');
    }
  }

  /// Returns net worth snapshots for the last [months] months, ordered by date
  /// descending.
  Future<List<Map<String, dynamic>>> getHistory({int months = 6}) async {
    return _db.getNetWorthSnapshots(_userId, months: months);
  }
}
