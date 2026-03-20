import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../local/app_database.dart';
import '../models/pending_payment.dart';

/// Local-first pending payment repository.
class PendingPaymentRepository {
  final AppDatabase _db;
  final SupabaseClient _client;

  PendingPaymentRepository(this._db, this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  // ─── Reads ──────────────────────────────────────────────────────────────

  Future<List<PendingPayment>> getAll({String? sourceType, String? period, String? status}) async {
    final rows = await _db.getPendingPayments(
      _userId,
      sourceType: sourceType,
      period: period,
      status: status,
    );
    return rows.map((r) => PendingPayment.fromMap(r)).toList();
  }

  Future<List<PendingPayment>> getPending({String? sourceType}) async {
    return getAll(sourceType: sourceType, status: 'pending');
  }

  /// Check whether a pending payment already exists for a given source in a period.
  Future<bool> exists(String sourceType, String sourceId, String period) async {
    final rows = await _db.getPendingPayments(
      _userId,
      sourceType: sourceType,
      period: period,
    );
    return rows.any((r) => r['source_id'] == sourceId);
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

  Future<PendingPayment> create({
    required String sourceType,
    required String sourceId,
    required String name,
    required String period,
    required double defaultAmount,
    String? accountId,
    String? notes,
  }) async {
    final id = 'pending-${DateTime.now().millisecondsSinceEpoch}-${_counter++}';
    final now = AppDatabase.now();
    final row = <String, dynamic>{
      'id': id,
      'user_id': _userId,
      'source_type': sourceType,
      'source_id': sourceId,
      'name': name,
      'period': period,
      'default_amount': defaultAmount,
      'status': 'pending',
      'account_id': accountId,
      'notes': notes,
      'created_at': now,
      'updated_at': now,
    };
    await _db.upsertPendingPayment(row);
    return PendingPayment.fromMap(row);
  }

  Future<void> markConfirmed(String id) async {
    final existing = await _db.getRowById('local_pending_payments', id);
    if (existing == null) return;

    final updated = Map<String, dynamic>.from(existing);
    updated['status'] = 'confirmed';
    updated['updated_at'] = AppDatabase.now();
    await _db.upsertPendingPayment(updated);
  }

  Future<void> delete(String id) async {
    await _db.deletePendingPayment(id);
  }

  static int _counter = 0;
}
