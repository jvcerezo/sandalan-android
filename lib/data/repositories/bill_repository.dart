import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bill.dart';

class BillsSummary {
  final double monthlyTotal;
  final double annualTotal;
  final int dueSoonCount;

  const BillsSummary({
    required this.monthlyTotal,
    required this.annualTotal,
    required this.dueSoonCount,
  });
}

class BillRepository {
  final SupabaseClient _client;

  BillRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Bill>> getBills() async {
    final data = await _client
        .from('bills')
        .select()
        .eq('user_id', _userId)
        .order('is_active', ascending: false)
        .order('category');
    return data.map((e) => Bill.fromJson(e)).toList();
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

  Future<Bill> createBill(Map<String, dynamic> data) async {
    data['user_id'] = _userId;
    final result = await _client.from('bills').insert(data).select().single();
    return Bill.fromJson(result);
  }

  Future<void> updateBill(String id, Map<String, dynamic> updates) async {
    await _client.from('bills').update(updates).eq('id', id);
  }

  Future<void> deleteBill(String id) async {
    await _client.from('bills').delete().eq('id', id);
  }

  Future<void> markPaid(String id) async {
    await _client.from('bills').update({
      'last_paid_date': DateTime.now().toIso8601String().substring(0, 10),
    }).eq('id', id);
  }
}
