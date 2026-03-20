import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tax_record.dart';

class TaxSummary {
  final double totalDue;
  final double totalPaid;
  final double balance;
  final int filedCount;

  const TaxSummary({
    required this.totalDue,
    required this.totalPaid,
    required this.balance,
    required this.filedCount,
  });
}

class TaxRepository {
  final SupabaseClient _client;

  TaxRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<TaxRecord>> getTaxRecords({int? year}) async {
    var query = _client.from('tax_records').select().eq('user_id', _userId);
    if (year != null) query = query.eq('year', year);
    final data = await query.order('year', ascending: false).order('quarter', ascending: false);
    return data.map((e) => TaxRecord.fromJson(e)).toList();
  }

  Future<TaxSummary> getTaxSummary() async {
    final currentYear = DateTime.now().year;
    final records = await getTaxRecords(year: currentYear);
    return TaxSummary(
      totalDue: records.fold(0, (s, r) => s + r.taxDue),
      totalPaid: records.fold(0, (s, r) => s + r.amountPaid),
      balance: records.fold(0, (s, r) => s + (r.taxDue - r.amountPaid)),
      filedCount: records.where((r) => r.status == 'filed' || r.status == 'paid').length,
    );
  }

  Future<TaxRecord> createTaxRecord(Map<String, dynamic> data) async {
    data['user_id'] = _userId;
    final result = await _client.from('tax_records').insert(data).select().single();
    return TaxRecord.fromJson(result);
  }

  Future<void> updateTaxRecord(String id, Map<String, dynamic> updates) async {
    await _client.from('tax_records').update(updates).eq('id', id);
  }

  Future<void> deleteTaxRecord(String id) async {
    await _client.from('tax_records').delete().eq('id', id);
  }
}
