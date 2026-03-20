import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../models/insurance_policy.dart';

class InsuranceSummary {
  final double annualPremium;
  final double totalCoverage;
  final int renewalSoonCount;

  const InsuranceSummary({
    required this.annualPremium,
    required this.totalCoverage,
    required this.renewalSoonCount,
  });
}

class InsuranceRepository {
  final SupabaseClient _client;

  InsuranceRepository(this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  Future<List<InsurancePolicy>> getPolicies() async {
    final data = await _client
        .from('insurance_policies')
        .select()
        .eq('user_id', _userId)
        .order('is_active', ascending: false)
        .order('type');
    return data.map((e) => InsurancePolicy.fromJson(e)).toList();
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

  Future<InsurancePolicy> createPolicy(Map<String, dynamic> data) async {
    data['user_id'] = _userId;
    final result = await _client.from('insurance_policies').insert(data).select().single();
    return InsurancePolicy.fromJson(result);
  }

  Future<void> updatePolicy(String id, Map<String, dynamic> updates) async {
    await _client.from('insurance_policies').update(updates).eq('id', id);
  }

  Future<void> deletePolicy(String id) async {
    await _client.from('insurance_policies').delete().eq('id', id);
  }
}
