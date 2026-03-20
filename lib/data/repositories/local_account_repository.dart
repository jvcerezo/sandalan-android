import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../local/app_database.dart';
import '../models/account.dart';

/// Local-first account repository. All reads from SQLite, writes go local first.
class LocalAccountRepository {
  final AppDatabase _db;
  final SupabaseClient _client;

  LocalAccountRepository(this._db, this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  // ─── Reads ──────────────────────────────────────────────────────────────

  Future<List<Account>> getAccounts() async {
    final rows = await _db.getAccounts(_userId, archived: false);
    return rows.map(_rowToAccount).toList();
  }

  Future<List<Account>> getArchivedAccounts() async {
    final rows = await _db.getAccounts(_userId, archived: true);
    return rows.map(_rowToAccount).toList();
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

  Future<Account> createAccount({
    required String name,
    required String type,
    String currency = 'PHP',
    double balance = 0,
  }) async {
    final id = _generateId();
    final now = AppDatabase.now();
    final row = <String, dynamic>{
      'id': id,
      'user_id': _userId,
      'name': name,
      'type': type,
      'currency': currency,
      'balance': balance,
      'is_archived': 0,
      'sync_status': 'pending',
      'created_at': now,
      'updated_at': now,
    };
    await _db.upsertAccount(row);
    return _rowToAccount(row);
  }

  Future<void> updateAccount(String id, {
    String? name,
    String? type,
    String? currency,
  }) async {
    final existing = await _db.getRowById('local_accounts', id);
    if (existing == null) return;

    final updated = Map<String, dynamic>.from(existing);
    if (name != null) updated['name'] = name;
    if (type != null) updated['type'] = type;
    if (currency != null) updated['currency'] = currency;
    updated['sync_status'] = 'pending';
    updated['updated_at'] = AppDatabase.now();
    await _db.upsertAccount(updated);
  }

  Future<void> deleteAccount(String id) async {
    await _db.deleteAccount(id);
  }

  Future<void> toggleArchive(String id, bool archived) async {
    final existing = await _db.getRowById('local_accounts', id);
    if (existing == null) return;

    final updated = Map<String, dynamic>.from(existing);
    updated['is_archived'] = archived ? 1 : 0;
    updated['sync_status'] = 'pending';
    updated['updated_at'] = AppDatabase.now();
    await _db.upsertAccount(updated);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Account _rowToAccount(Map<String, dynamic> row) {
    return Account(
      id: row['id'] as String,
      createdAt: row['created_at'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      type: row['type'] as String,
      currency: row['currency'] as String? ?? 'PHP',
      balance: (row['balance'] as num).toDouble(),
      isArchived: row['is_archived'] == 1 || row['is_archived'] == true,
    );
  }

  String _generateId() =>
      'local-acct-${DateTime.now().millisecondsSinceEpoch}-${_counter++}';
  static int _counter = 0;
}
