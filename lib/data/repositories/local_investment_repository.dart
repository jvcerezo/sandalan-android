import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../local/app_database.dart';
import '../models/investment.dart';

class LocalInvestmentRepository {
  final AppDatabase _db;
  final SupabaseClient _client;

  LocalInvestmentRepository(this._db, this._client);

  String get _userId =>
      _client.auth.currentUser?.id ?? GuestModeService.getGuestIdSync() ?? 'guest';

  Future<List<Investment>> getInvestments() async {
    final rows = await _db.getInvestments(_userId);
    return rows.map((r) => Investment.fromJson(r)).toList();
  }

  Future<void> createInvestment(Investment inv) async {
    await _db.upsertInvestment(inv.toJson());
  }

  Future<void> updateValue(String id, double currentValue, {String? navpu, double? units}) async {
    final existing = await _db.getRowById('local_investments', id);
    if (existing == null) return;
    final updated = Map<String, dynamic>.from(existing);
    updated['current_value'] = currentValue;
    updated['updated_at'] = DateTime.now().toIso8601String();
    updated['sync_status'] = 'pending';
    if (navpu != null) updated['navpu'] = navpu;
    if (units != null) updated['units'] = units;
    await _db.upsertInvestment(updated);
  }

  Future<void> deleteInvestment(String id) async {
    await _db.deleteInvestment(id);
  }

  Future<double> getTotalInvested() async {
    final rows = await _db.getInvestments(_userId);
    double total = 0;
    for (final r in rows) { total += (r['amount_invested'] as num?)?.toDouble() ?? 0; }
    return total;
  }

  Future<double> getTotalCurrentValue() async {
    final rows = await _db.getInvestments(_userId);
    double total = 0;
    for (final r in rows) { total += (r['current_value'] as num?)?.toDouble() ?? 0; }
    return total;
  }
}
