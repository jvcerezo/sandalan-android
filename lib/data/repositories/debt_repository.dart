import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../models/debt.dart';

class DebtSummary {
  final double totalDebt;
  final double totalMinMonthly;
  final double highestRate;
  final int activeCount;

  const DebtSummary({
    required this.totalDebt,
    required this.totalMinMonthly,
    required this.highestRate,
    required this.activeCount,
  });
}

class DebtRepository {
  final SupabaseClient _client;

  DebtRepository(this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  Future<List<Debt>> getDebts() async {
    final data = await _client
        .from('debts')
        .select()
        .eq('user_id', _userId)
        .order('is_paid_off')
        .order('current_balance', ascending: false);
    return data.map((e) => Debt.fromJson(e)).toList();
  }

  Future<DebtSummary> getDebtSummary() async {
    final debts = await getDebts();
    final active = debts.where((d) => !d.isPaidOff).toList();
    return DebtSummary(
      totalDebt: active.fold(0, (s, d) => s + d.currentBalance),
      totalMinMonthly: active.fold(0, (s, d) => s + d.minimumPayment),
      highestRate: active.isEmpty ? 0 : active.map((d) => d.interestRate).reduce((a, b) => a > b ? a : b),
      activeCount: active.length,
    );
  }

  Future<Debt> createDebt({
    required String name,
    required String type,
    required double currentBalance,
    required double originalAmount,
    required double interestRate,
    required double minimumPayment,
    String? lender,
    int? dueDay,
    String? notes,
    String? accountId,
  }) async {
    final data = await _client.from('debts').insert({
      'user_id': _userId,
      'name': name,
      'type': type,
      'current_balance': currentBalance,
      'original_amount': originalAmount,
      'interest_rate': interestRate,
      'minimum_payment': minimumPayment,
      'lender': lender,
      'due_day': dueDay,
      'notes': notes,
      'account_id': accountId,
    }).select().single();
    return Debt.fromJson(data);
  }

  Future<void> updateDebt(String id, Map<String, dynamic> updates) async {
    await _client.from('debts').update(updates).eq('id', id);
  }

  Future<void> deleteDebt(String id) async {
    await _client.from('debts').delete().eq('id', id);
  }
}
