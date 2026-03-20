import 'package:supabase_flutter/supabase_flutter.dart';
import '../local/app_database.dart';
import '../models/goal.dart';
import 'goal_repository.dart';

/// Local-first goal repository.
class LocalGoalRepository {
  final AppDatabase _db;
  final SupabaseClient _client;

  LocalGoalRepository(this._db, this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ─── Reads ──────────────────────────────────────────────────────────────

  Future<List<Goal>> getGoals() async {
    final rows = await _db.getGoals(_userId);
    return rows.map(_rowToGoal).toList();
  }

  Future<GoalsSummary> getGoalsSummary() async {
    final goals = await getGoals();
    return GoalsSummary(
      total: goals.length,
      completed: goals.where((g) => g.isCompleted).length,
      active: goals.where((g) => !g.isCompleted).length,
      totalTarget: goals.fold(0, (sum, g) => sum + g.targetAmount),
      totalSaved: goals.fold(0, (sum, g) => sum + g.currentAmount),
    );
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

  Future<Goal> createGoal({
    required String name,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? deadline,
    String category = 'Savings',
  }) async {
    final id = _generateId();
    final now = AppDatabase.now();
    final row = <String, dynamic>{
      'id': id,
      'user_id': _userId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String().substring(0, 10),
      'category': category,
      'is_completed': 0,
      'sync_status': 'pending',
      'created_at': now,
      'updated_at': now,
    };
    await _db.upsertGoal(row);
    return _rowToGoal(row);
  }

  Future<void> updateGoal(String id, {
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? category,
    bool? isCompleted,
  }) async {
    final existing = await _db.getRowById('local_goals', id);
    if (existing == null) return;

    final updated = Map<String, dynamic>.from(existing);
    if (name != null) updated['name'] = name;
    if (targetAmount != null) updated['target_amount'] = targetAmount;
    if (currentAmount != null) updated['current_amount'] = currentAmount;
    if (deadline != null) updated['deadline'] = deadline.toIso8601String().substring(0, 10);
    if (category != null) updated['category'] = category;
    if (isCompleted != null) updated['is_completed'] = isCompleted ? 1 : 0;
    updated['sync_status'] = 'pending';
    updated['updated_at'] = AppDatabase.now();
    await _db.upsertGoal(updated);
  }

  Future<void> addFunds({
    required String goalId,
    required String accountId,
    required double amount,
    String? note,
    DateTime? fundingDate,
  }) async {
    // Update goal amount
    final goal = await _db.getRowById('local_goals', goalId);
    if (goal != null) {
      final updated = Map<String, dynamic>.from(goal);
      updated['current_amount'] = (goal['current_amount'] as num).toDouble() + amount;
      updated['sync_status'] = 'pending';
      updated['updated_at'] = AppDatabase.now();
      await _db.upsertGoal(updated);
    }

    // Deduct from account
    final account = await _db.getRowById('local_accounts', accountId);
    if (account != null) {
      final updated = Map<String, dynamic>.from(account);
      updated['balance'] = (account['balance'] as num).toDouble() - amount;
      updated['sync_status'] = 'pending';
      updated['updated_at'] = AppDatabase.now();
      await _db.upsertAccount(updated);
    }

    // Create a transaction record
    final now = AppDatabase.now();
    final dateStr = (fundingDate ?? DateTime.now()).toIso8601String().substring(0, 10);
    await _db.upsertTransaction({
      'id': 'local-fund-${DateTime.now().millisecondsSinceEpoch}',
      'user_id': _userId,
      'amount': -amount,
      'category': 'Goal Funding',
      'description': note ?? 'Goal funding',
      'date': dateStr,
      'currency': 'PHP',
      'account_id': accountId,
      'sync_status': 'pending',
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> deleteGoal(String id) async {
    await _db.deleteGoal(id);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Goal _rowToGoal(Map<String, dynamic> row) {
    return Goal(
      id: row['id'] as String,
      createdAt: row['created_at'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      targetAmount: (row['target_amount'] as num).toDouble(),
      currentAmount: (row['current_amount'] as num).toDouble(),
      deadline: row['deadline'] as String?,
      category: row['category'] as String? ?? 'Savings',
      isCompleted: row['is_completed'] == 1 || row['is_completed'] == true,
    );
  }

  String _generateId() =>
      'local-goal-${DateTime.now().millisecondsSinceEpoch}-${_counter++}';
  static int _counter = 0;
}
