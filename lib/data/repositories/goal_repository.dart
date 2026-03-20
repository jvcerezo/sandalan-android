import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../models/goal.dart';

class GoalsSummary {
  final int total;
  final int completed;
  final int active;
  final double totalTarget;
  final double totalSaved;

  const GoalsSummary({
    required this.total,
    required this.completed,
    required this.active,
    required this.totalTarget,
    required this.totalSaved,
  });

  double get overallProgress =>
      totalTarget > 0 ? (totalSaved / totalTarget).clamp(0, 1) : 0;
}

class GoalRepository {
  final SupabaseClient _client;

  GoalRepository(this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  /// Get all goals.
  Future<List<Goal>> getGoals() async {
    final data = await _client
        .from('goals')
        .select()
        .eq('user_id', _userId)
        .order('is_completed')
        .order('created_at', ascending: false);
    return data.map((e) => Goal.fromJson(e)).toList();
  }

  /// Get goals summary.
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

  /// Create a goal.
  Future<Goal> createGoal({
    required String name,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? deadline,
    String category = 'Savings',
  }) async {
    final data = await _client.from('goals').insert({
      'user_id': _userId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String().substring(0, 10),
      'category': category,
    }).select().single();
    return Goal.fromJson(data);
  }

  /// Update a goal.
  Future<void> updateGoal(String id, {
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? category,
    bool? isCompleted,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (targetAmount != null) updates['target_amount'] = targetAmount;
    if (currentAmount != null) updates['current_amount'] = currentAmount;
    if (deadline != null) updates['deadline'] = deadline.toIso8601String().substring(0, 10);
    if (category != null) updates['category'] = category;
    if (isCompleted != null) updates['is_completed'] = isCompleted;
    if (updates.isNotEmpty) {
      await _client.from('goals').update(updates).eq('id', id);
    }
  }

  /// Add funds to a goal via RPC (atomic).
  Future<void> addFunds({
    required String goalId,
    required String accountId,
    required double amount,
    String? note,
    DateTime? fundingDate,
  }) async {
    await _client.rpc('add_funds_to_goal', params: {
      'p_goal_id': goalId,
      'p_account_id': accountId,
      'p_amount': amount,
      'p_note': note ?? 'Goal funding',
      'p_funding_date': (fundingDate ?? DateTime.now()).toIso8601String().substring(0, 10),
    });
  }

  /// Delete a goal.
  Future<void> deleteGoal(String id) async {
    await _client.from('goals').delete().eq('id', id);
  }
}
