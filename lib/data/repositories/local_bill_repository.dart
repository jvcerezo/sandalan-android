import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../local/app_database.dart';
import '../models/bill.dart';
import 'bill_repository.dart';

/// Local-first bill repository.
class LocalBillRepository {
  final AppDatabase _db;
  final SupabaseClient _client;

  LocalBillRepository(this._db, this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  // ─── Reads ──────────────────────────────────────────────────────────────

  Future<List<Bill>> getBills() async {
    final rows = await _db.getBills(_userId);
    return rows.map(_rowToBill).toList();
  }

  Future<BillsSummary> getBillsSummary() async {
    final bills = await getBills();
    final active = bills.where((b) => b.isActive).toList();

    double monthlyTotal = 0;
    for (final b in active) {
      switch (b.billingCycle) {
        case 'monthly': monthlyTotal += b.amount; break;
        case 'quarterly': monthlyTotal += b.amount / 3; break;
        case 'semi_annual': monthlyTotal += b.amount / 6; break;
        case 'annual': monthlyTotal += b.amount / 12; break;
      }
    }

    final now = DateTime.now();
    final dueSoon = active.where((b) {
      if (b.dueDay == null) return false;
      final diff = b.dueDay! - now.day;
      return diff >= 0 && diff <= 7;
    }).length;

    return BillsSummary(
      monthlyTotal: monthlyTotal,
      annualTotal: monthlyTotal * 12,
      dueSoonCount: dueSoon,
    );
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

  Future<Bill> createBill(Map<String, dynamic> data) async {
    final id = _generateId();
    final now = AppDatabase.now();
    data['id'] = id;
    data['user_id'] = _userId;
    data['sync_status'] = 'pending';
    data['created_at'] = now;
    data['updated_at'] = now;
    if (data['is_active'] is bool) data['is_active'] = (data['is_active'] as bool) ? 1 : 0;
    if (!data.containsKey('is_active')) data['is_active'] = 1;
    await _db.upsertBill(data);
    return _rowToBill(data);
  }

  Future<void> updateBill(String id, Map<String, dynamic> updates) async {
    final existing = await _db.getRowById('local_bills', id);
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
    await _db.upsertBill(updated);
  }

  Future<void> deleteBill(String id) async {
    await _db.deleteBill(id);
  }

  /// Mark bill as paid: update last_paid_date.
  /// The caller (UI) is responsible for confirming the pending transaction
  /// and deducting from the chosen account via LocalTransactionRepository.
  Future<void> markPaid(String id) async {
    final existing = await _db.getRowById('local_bills', id);
    if (existing == null) return;

    final updated = Map<String, dynamic>.from(existing);
    updated['last_paid_date'] = DateTime.now().toIso8601String().substring(0, 10);
    updated['sync_status'] = 'pending';
    updated['updated_at'] = AppDatabase.now();
    await _db.upsertBill(updated);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Bill _rowToBill(Map<String, dynamic> row) {
    return Bill(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      createdAt: row['created_at'] as String,
      name: row['name'] as String,
      category: row['category'] as String,
      amount: (row['amount'] as num).toDouble(),
      billingCycle: row['billing_cycle'] as String? ?? 'monthly',
      dueDay: row['due_day'] as int?,
      provider: row['provider'] as String?,
      lastPaidDate: row['last_paid_date'] as String?,
      isActive: row['is_active'] == 1 || row['is_active'] == true,
      notes: row['notes'] as String?,
      accountId: row['account_id'] as String?,
    );
  }

  String _generateId() =>
      'local-bill-${DateTime.now().millisecondsSinceEpoch}-${_counter++}';
  static int _counter = 0;
}
