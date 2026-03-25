import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../../core/utils/id_generator.dart';
import '../../core/utils/input_validator.dart';
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

  Future<Account?> getAccountById(String id) async {
    final row = await _db.getRowById('local_accounts', id);
    if (row == null) return null;
    return _rowToAccount(row);
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

  static const _accountTypes = ['bank', 'e-wallet', 'cash', 'credit-card', 'savings', 'investment'];

  Future<Account> createAccount({
    required String name,
    required String type,
    String currency = 'PHP',
    double balance = 0,
  }) async {
    final sName = InputValidator.requireName(name, 'Account name');
    final sType = InputValidator.requireEnum(type, _accountTypes, 'Account type');
    final sCurrency = InputValidator.currency(currency);
    final sBalance = InputValidator.amount(balance);

    final id = IdGenerator.account();
    final now = AppDatabase.now();
    final row = <String, dynamic>{
      'id': id,
      'user_id': _userId,
      'name': sName,
      'type': sType,
      'currency': sCurrency,
      'balance': sBalance,
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
    if (name != null) updated['name'] = InputValidator.requireName(name, 'Account name');
    if (type != null) updated['type'] = InputValidator.requireEnum(type, _accountTypes, 'Account type');
    if (currency != null) updated['currency'] = InputValidator.currency(currency);
    updated['sync_status'] = 'pending';
    updated['updated_at'] = AppDatabase.now();
    await _db.upsertAccount(updated);
  }

  /// Permanently delete an account and ALL its associated transactions.
  Future<void> deleteAccount(String id) async {
    // Delete all transactions linked to this account first
    await _db.deleteTransactionsByAccountId(id);
    // Then delete the account itself
    await _db.deleteAccount(id);
  }

  /// Count transactions associated with this account.
  Future<int> countTransactions(String id) async {
    return _db.countTransactionsByAccountId(id);
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

  /// Reconciliation check: compares each account's stored balance against
  /// the sum of its transactions. Logs a warning for any mismatch.
  Future<void> reconcileBalances() async {
    final accounts = await getAccounts();
    for (final account in accounts) {
      final txSum = await _db.sumTransactionsByAccountId(account.id);
      final diff = (account.balance - txSum).abs();
      if (diff > 0.01) {
        debugPrint(
          'RECONCILE WARNING: Account "${account.name}" (${account.id}) '
          'balance=${account.balance} but transaction sum=$txSum '
          '(diff=${account.balance - txSum})',
        );
      }
    }
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

}
