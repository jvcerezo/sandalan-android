import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account.dart';

class AccountRepository {
  final SupabaseClient _client;

  AccountRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Get active accounts.
  Future<List<Account>> getAccounts() async {
    final data = await _client
        .from('accounts')
        .select()
        .eq('user_id', _userId)
        .eq('is_archived', false)
        .order('name');
    return data.map((e) => Account.fromJson(e)).toList();
  }

  /// Get archived accounts.
  Future<List<Account>> getArchivedAccounts() async {
    final data = await _client
        .from('accounts')
        .select()
        .eq('user_id', _userId)
        .eq('is_archived', true)
        .order('name');
    return data.map((e) => Account.fromJson(e)).toList();
  }

  /// Create a new account.
  Future<Account> createAccount({
    required String name,
    required String type,
    String currency = 'PHP',
    double balance = 0,
  }) async {
    final data = await _client.from('accounts').insert({
      'user_id': _userId,
      'name': name,
      'type': type,
      'currency': currency,
      'balance': balance,
    }).select().single();
    return Account.fromJson(data);
  }

  /// Update an account.
  Future<void> updateAccount(String id, {
    String? name,
    String? type,
    String? currency,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (type != null) updates['type'] = type;
    if (currency != null) updates['currency'] = currency;
    if (updates.isNotEmpty) {
      await _client.from('accounts').update(updates).eq('id', id);
    }
  }

  /// Delete an account.
  Future<void> deleteAccount(String id) async {
    await _client.from('accounts').delete().eq('id', id);
  }

  /// Toggle archive status.
  Future<void> toggleArchive(String id, bool archived) async {
    await _client
        .from('accounts')
        .update({'is_archived': archived})
        .eq('id', id);
  }
}
