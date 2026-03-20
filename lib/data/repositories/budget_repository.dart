import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../models/budget.dart';

class BudgetSummaryItem {
  final String category;
  final double budgeted;
  final double spent;
  final double rollover;
  final bool hasRollover;

  const BudgetSummaryItem({
    required this.category,
    required this.budgeted,
    required this.spent,
    this.rollover = 0,
    this.hasRollover = false,
  });

  double get remaining => budgeted + rollover - spent;
  double get percentUsed => budgeted > 0 ? (spent / (budgeted + rollover)).clamp(0, 2) : 0;
}

class BudgetRepository {
  final SupabaseClient _client;

  BudgetRepository(this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  /// Get budgets for a specific period.
  Future<List<Budget>> getBudgets(DateTime month, String period) async {
    final data = await _client
        .from('budgets')
        .select()
        .eq('user_id', _userId)
        .eq('month', month.toIso8601String().substring(0, 10))
        .eq('period', period)
        .order('category');
    return data.map((e) => Budget.fromJson(e)).toList();
  }

  /// Create a budget.
  Future<Budget> createBudget({
    required String category,
    required double amount,
    required DateTime month,
    String period = 'monthly',
    bool rollover = false,
  }) async {
    final data = await _client.from('budgets').insert({
      'user_id': _userId,
      'category': category.toLowerCase(),
      'amount': amount,
      'month': month.toIso8601String().substring(0, 10),
      'period': period,
      'rollover': rollover,
    }).select().single();
    return Budget.fromJson(data);
  }

  /// Update a budget.
  Future<void> updateBudget(String id, {
    String? category,
    double? amount,
    bool? rollover,
  }) async {
    final updates = <String, dynamic>{};
    if (category != null) updates['category'] = category.toLowerCase();
    if (amount != null) updates['amount'] = amount;
    if (rollover != null) updates['rollover'] = rollover;
    if (updates.isNotEmpty) {
      await _client.from('budgets').update(updates).eq('id', id);
    }
  }

  /// Delete a budget.
  Future<void> deleteBudget(String id) async {
    await _client.from('budgets').delete().eq('id', id);
  }

  /// Copy budgets from a previous month.
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
}
