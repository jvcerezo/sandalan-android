import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/id_generator.dart';
import '../local/app_database.dart';
import '../models/goal.dart';
import 'goal_repository.dart';

/// Local-first goal repository.
class LocalGoalRepository {
  final AppDatabase _db;
  final SupabaseClient _client;

  LocalGoalRepository(this._db, this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

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
    String? accountId,
  }) async {
    final id = IdGenerator.goal();
    final now = AppDatabase.now();
    final row = <String, dynamic>{
      'id': id,
      'user_id': _userId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String().substring(0, 10),
      'category': category,
      'account_id': accountId,
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
    String? accountId,
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
    if (accountId != null) updated['account_id'] = accountId;
    if (isCompleted != null) updated['is_completed'] = isCompleted ? 1 : 0;
    updated['sync_status'] = 'pending';
    updated['updated_at'] = AppDatabase.now();
    await _db.upsertGoal(updated);
  }

  /// Add funds to a goal from the linked account.
  /// Creates a "Goal Funding" transaction NOT counted as expense.
  Future<void> addFunds({
    required String goalId,
    required String accountId,
    required double amount,
    String? note,
    DateTime? fundingDate,
  }) async {
    // Update goal amount
    final goal = await _db.getRowById('local_goals', goalId);
    if (goal == null) return;

    final goalName = goal['name'] as String;
    final newAmount = (goal['current_amount'] as num).toDouble() + amount;
    final targetAmount = (goal['target_amount'] as num).toDouble();

    final updated = Map<String, dynamic>.from(goal);
    updated['current_amount'] = newAmount;
    // Auto-complete if target reached
    if (newAmount >= targetAmount && (goal['is_completed'] == 0 || goal['is_completed'] == false)) {
      updated['is_completed'] = 1;
      // Send goal completion notification
      await NotificationService.instance.showNotification(
        id: 'goal-complete-$goalId'.hashCode,
        title: 'Congratulations!',
        body: 'You\'ve reached your $goalName goal of PHP ${targetAmount.toStringAsFixed(2)}!',
      );
    }
    updated['sync_status'] = 'pending';
    updated['updated_at'] = AppDatabase.now();
    await _db.upsertGoal(updated);

    // Deduct from account
    final account = await _db.getRowById('local_accounts', accountId);
    if (account != null) {
      final updatedAccount = Map<String, dynamic>.from(account);
      updatedAccount['balance'] = (account['balance'] as num).toDouble() - amount;
      updatedAccount['sync_status'] = 'pending';
      updatedAccount['updated_at'] = AppDatabase.now();
      await _db.upsertAccount(updatedAccount);
    }

    // Create a transaction record — category "Goal Funding", NOT an expense
    final now = AppDatabase.now();
    final dateStr = (fundingDate ?? DateTime.now()).toIso8601String().substring(0, 10);
    await _db.upsertTransaction({
      'id': 'local-fund-${DateTime.now().millisecondsSinceEpoch}',
      'user_id': _userId,
      'amount': -amount,
      'category': 'Goal Funding',
      'description': note ?? 'Transferred to $goalName',
      'date': dateStr,
      'currency': 'PHP',
      'account_id': accountId,
      'status': 'confirmed',
      'sync_status': 'pending',
      'created_at': now,
      'updated_at': now,
    });
  }

  /// Release funds from a goal back to the linked account.
  Future<void> releaseFunds({
    required String goalId,
    required String accountId,
    required double amount,
    String? note,
  }) async {
    final goal = await _db.getRowById('local_goals', goalId);
    if (goal == null) return;

    final goalName = goal['name'] as String;

    // Get account name for transaction description
    final account = await _db.getRowById('local_accounts', accountId);
    final accountName = account?['name'] as String? ?? 'account';

    // Decrease goal amount
    final updated = Map<String, dynamic>.from(goal);
    final newAmount = ((goal['current_amount'] as num).toDouble() - amount).clamp(0.0, double.infinity);
    updated['current_amount'] = newAmount;
    // Un-complete if going below target
    if (newAmount < (goal['target_amount'] as num).toDouble()) {
      updated['is_completed'] = 0;
    }
    updated['sync_status'] = 'pending';
    updated['updated_at'] = AppDatabase.now();
    await _db.upsertGoal(updated);

    // Add back to account
    if (account != null) {
      final updatedAccount = Map<String, dynamic>.from(account);
      updatedAccount['balance'] = (account['balance'] as num).toDouble() + amount;
      updatedAccount['sync_status'] = 'pending';
      updatedAccount['updated_at'] = AppDatabase.now();
      await _db.upsertAccount(updatedAccount);
    }

    // Create transaction record
    final now = AppDatabase.now();
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    await _db.upsertTransaction({
      'id': 'local-release-${DateTime.now().millisecondsSinceEpoch}',
      'user_id': _userId,
      'amount': amount,
      'category': 'Goal Funding',
      'description': note ?? 'Released from $goalName to $accountName',
      'date': dateStr,
      'currency': 'PHP',
      'account_id': accountId,
      'status': 'confirmed',
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
      accountId: row['account_id'] as String?,
      isCompleted: row['is_completed'] == 1 || row['is_completed'] == true,
    );
  }

}
