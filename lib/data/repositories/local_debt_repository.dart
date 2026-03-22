import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../../core/utils/id_generator.dart';
import '../local/app_database.dart';
import '../models/debt.dart';
import 'debt_repository.dart';

/// Local-first debt repository.
class LocalDebtRepository {
  final AppDatabase _db;
  final SupabaseClient _client;

  LocalDebtRepository(this._db, this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  // ─── Reads ──────────────────────────────────────────────────────────────

  Future<List<Debt>> getDebts() async {
    final rows = await _db.getDebts(_userId);
    return rows.map(_rowToDebt).toList();
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

  // ─── Writes ─────────────────────────────────────────────────────────────

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
    final id = IdGenerator.debt();
    final now = AppDatabase.now();
    final row = <String, dynamic>{
      'id': id,
      'user_id': _userId,
      'name': name,
      'type': type,
      'lender': lender,
      'current_balance': currentBalance,
      'original_amount': originalAmount,
      'interest_rate': interestRate,
      'minimum_payment': minimumPayment,
      'due_day': dueDay,
      'is_paid_off': 0,
      'notes': notes,
      'account_id': accountId,
      'sync_status': 'pending',
      'created_at': now,
      'updated_at': now,
    };
    await _db.upsertDebt(row);
    return _rowToDebt(row);
  }

  Future<void> updateDebt(String id, Map<String, dynamic> updates) async {
    final existing = await _db.getRowById('local_debts', id);
    if (existing == null) return;

    final updated = Map<String, dynamic>.from(existing);
    for (final key in updates.keys) {
      if (updates[key] is bool) {
        updated[key] = (updates[key] as bool) ? 1 : 0;
      } else {
        updated[key] = updates[key];
      }
    }
    updated['sync_status'] = 'pending';
    updated['updated_at'] = AppDatabase.now();
    await _db.upsertDebt(updated);
  }

  Future<void> deleteDebt(String id) async {
    await _db.deleteDebt(id);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Debt _rowToDebt(Map<String, dynamic> row) {
    return Debt(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      createdAt: row['created_at'] as String,
      name: row['name'] as String,
      type: row['type'] as String,
      lender: row['lender'] as String?,
      currentBalance: (row['current_balance'] as num).toDouble(),
      originalAmount: (row['original_amount'] as num).toDouble(),
      interestRate: (row['interest_rate'] as num).toDouble(),
      minimumPayment: (row['minimum_payment'] as num).toDouble(),
      dueDay: row['due_day'] as int?,
      isPaidOff: row['is_paid_off'] == 1 || row['is_paid_off'] == true,
      notes: row['notes'] as String?,
      accountId: row['account_id'] as String?,
    );
  }

}
