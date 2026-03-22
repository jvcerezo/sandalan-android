import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../local/app_database.dart';
import '../models/budget.dart';

/// Local-first budget repository.
class LocalBudgetRepository {
  final AppDatabase _db;
  final SupabaseClient _client;

  LocalBudgetRepository(this._db, this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  // ─── Reads ──────────────────────────────────────────────────────────────

  Future<List<Budget>> getBudgets(DateTime month, String period) async {
    final monthStr = month.toIso8601String().substring(0, 10);
    final rows = await _db.getBudgets(_userId, monthStr, period);
    return rows.map(_rowToBudget).toList();
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

  Future<Budget> createBudget({
    required String category,
    required double amount,
    required DateTime month,
    String period = 'monthly',
    bool rollover = false,
  }) async {
    final id = _generateId();
    final now = AppDatabase.now();
    final row = <String, dynamic>{
      'id': id,
      'user_id': _userId,
      'category': category.toLowerCase(),
      'amount': amount,
      'month': month.toIso8601String().substring(0, 10),
      'period': period,
      'rollover': rollover ? 1 : 0,
      'sync_status': 'pending',
      'created_at': now,
      'updated_at': now,
    };
    await _db.upsertBudget(row);
    return _rowToBudget(row);
  }

  Future<void> updateBudget(String id, {
    String? category,
    double? amount,
    bool? rollover,
  }) async {
    final existing = await _db.getRowById('local_budgets', id);
    if (existing == null) return;

    final updated = Map<String, dynamic>.from(existing);
    if (category != null) updated['category'] = category.toLowerCase();
    if (amount != null) updated['amount'] = amount;
    if (rollover != null) updated['rollover'] = rollover ? 1 : 0;
    updated['sync_status'] = 'pending';
    updated['updated_at'] = AppDatabase.now();
    await _db.upsertBudget(updated);
  }

  Future<void> deleteBudget(String id) async {
    await _db.deleteBudget(id);
  }

  Future<void> copyBudgetsFromMonth(DateTime fromMonth, DateTime toMonth, String period) async {
    final existing = await getBudgets(fromMonth, period);
    final current = await getBudgets(toMonth, period);
    final currentCategories = current.map((b) => b.category).toSet();

    for (final budget in existing) {
      if (!currentCategories.contains(budget.category)) {
        await createBudget(
          category: budget.category,
          amount: budget.amount,
          month: toMonth,
          period: period,
          rollover: budget.rollover,
        );
      }
    }
  }

  /// Roll over budgets from [fromMonth] to [toMonth], carrying unused amounts forward.
  /// [spentByCategory] maps lowercase category names to total spent (positive values).
  /// New limit = original limit + (original limit - spent). Minimum is the original limit.
  Future<int> rolloverBudgets({
    required DateTime fromMonth,
    required DateTime toMonth,
    required Map<String, double> spentByCategory,
    String period = 'monthly',
  }) async {
    final existing = await getBudgets(fromMonth, period);
    final current = await getBudgets(toMonth, period);
    final currentCategories = current.map((b) => b.category).toSet();

    int created = 0;
    for (final budget in existing) {
      if (currentCategories.contains(budget.category)) continue;

      final spent = spentByCategory[budget.category] ?? 0;
      final unused = (budget.amount - spent).clamp(0, double.infinity);
      final newAmount = budget.amount + unused;

      await createBudget(
        category: budget.category,
        amount: newAmount,
        month: toMonth,
        period: period,
        rollover: true,
      );
      created++;
    }
    return created;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Budget _rowToBudget(Map<String, dynamic> row) {
    return Budget(
      id: row['id'] as String,
      createdAt: row['created_at'] as String,
      userId: row['user_id'] as String,
      category: row['category'] as String,
      amount: (row['amount'] as num).toDouble(),
      month: row['month'] as String,
      period: row['period'] as String? ?? 'monthly',
      rollover: row['rollover'] == 1 || row['rollover'] == true,
    );
  }

  String _generateId() =>
      'local-bgt-${DateTime.now().millisecondsSinceEpoch}-${_counter++}';
  static int _counter = 0;
}
