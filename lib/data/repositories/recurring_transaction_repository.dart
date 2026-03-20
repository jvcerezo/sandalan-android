import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recurring_transaction.dart';

class RecurringTransactionRepository {
  final SupabaseClient _client;

  RecurringTransactionRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    final data = await _client
        .from('recurring_transactions')
        .select()
        .eq('user_id', _userId)
        .order('next_run_date');
    return data.map((e) => RecurringTransaction.fromJson(e)).toList();
  }

  Future<int> getDueCount() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final data = await _client
        .from('recurring_transactions')
        .select('id')
        .eq('user_id', _userId)
        .eq('is_active', true)
        .lte('next_run_date', today);
    return data.length;
  }

  Future<RecurringTransaction> createRecurring(Map<String, dynamic> data) async {
    data['user_id'] = _userId;
    final result = await _client.from('recurring_transactions').insert(data).select().single();
    return RecurringTransaction.fromJson(result);
  }

  Future<void> updateRecurring(String id, Map<String, dynamic> updates) async {
    await _client.from('recurring_transactions').update(updates).eq('id', id);
  }

  Future<void> deleteRecurring(String id) async {
    await _client.from('recurring_transactions').delete().eq('id', id);
  }

  /// Process all due recurring transactions via RPC.
  Future<void> processDue() async {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
    await _client.rpc('process_due_recurring_transactions', params: {
      'p_current_time': timeStr,
    });
  }
}
