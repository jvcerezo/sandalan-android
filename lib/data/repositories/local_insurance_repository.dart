import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../../core/utils/id_generator.dart';
import '../local/app_database.dart';
import '../models/insurance_policy.dart';
import 'insurance_repository.dart';

/// Local-first insurance repository.
class LocalInsuranceRepository {
  final AppDatabase _db;
  final SupabaseClient _client;

  LocalInsuranceRepository(this._db, this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  // ─── Reads ──────────────────────────────────────────────────────────────

  Future<List<InsurancePolicy>> getPolicies() async {
    final rows = await _db.getInsurancePolicies(_userId);
    return rows.map(_rowToPolicy).toList();
  }

  Future<InsuranceSummary> getInsuranceSummary() async {
    final policies = await getPolicies();
    final active = policies.where((p) => p.isActive).toList();

    double annualPremium = 0;
    for (final p in active) {
      switch (p.premiumFrequency) {
        case 'monthly': annualPremium += p.premiumAmount * 12; break;
        case 'quarterly': annualPremium += p.premiumAmount * 4; break;
        case 'semi_annual': annualPremium += p.premiumAmount * 2; break;
        case 'annual': annualPremium += p.premiumAmount; break;
        default: annualPremium += p.premiumAmount * 12; break; // Treat unknown as monthly
      }
    }

    final now = DateTime.now();
    final renewalSoon = active.where((p) {
      if (p.renewalDate == null) return false;
      final parsed = DateTime.tryParse(p.renewalDate!);
      if (parsed == null) return false;
      final diff = parsed.difference(now).inDays;
      return diff >= 0 && diff <= 30;
    }).length;

    return InsuranceSummary(
      annualPremium: annualPremium,
      totalCoverage: active.fold(0, (s, p) => s + (p.coverageAmount ?? 0)),
      renewalSoonCount: renewalSoon,
    );
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

  Future<InsurancePolicy> createPolicy(Map<String, dynamic> data) async {
    final id = IdGenerator.insurance();
    final now = AppDatabase.now();
    data['id'] = id;
    data['user_id'] = _userId;
    data['sync_status'] = 'pending';
    data['created_at'] = now;
    data['updated_at'] = now;
    if (data['is_active'] is bool) data['is_active'] = (data['is_active'] as bool) ? 1 : 0;
    if (!data.containsKey('is_active')) data['is_active'] = 1;
    await _db.upsertInsurance(data);
    return _rowToPolicy(data);
  }

  Future<void> updatePolicy(String id, Map<String, dynamic> updates) async {
    final existing = await _db.getRowById('local_insurance', id);
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
    await _db.upsertInsurance(updated);
  }

  Future<void> deletePolicy(String id) async {
    await _db.deleteInsurance(id);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  InsurancePolicy _rowToPolicy(Map<String, dynamic> row) {
    return InsurancePolicy(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      createdAt: row['created_at'] as String,
      name: row['name'] as String,
      type: row['type'] as String,
      provider: row['provider'] as String?,
      policyNumber: row['policy_number'] as String?,
      premiumAmount: (row['premium_amount'] as num).toDouble(),
      premiumFrequency: row['premium_frequency'] as String? ?? 'monthly',
      coverageAmount: (row['coverage_amount'] as num?)?.toDouble(),
      renewalDate: row['renewal_date'] as String?,
      isActive: row['is_active'] == 1 || row['is_active'] == true,
      notes: row['notes'] as String?,
      accountId: row['account_id'] as String?,
    );
  }

}
