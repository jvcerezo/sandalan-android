import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contribution.dart';

class ContributionSummary {
  final double totalPaid;
  final double totalUnpaid;
  final double sssPaid;
  final double philhealthPaid;
  final double pagibigPaid;

  const ContributionSummary({
    required this.totalPaid,
    required this.totalUnpaid,
    required this.sssPaid,
    required this.philhealthPaid,
    required this.pagibigPaid,
  });
}

class ContributionRepository {
  final SupabaseClient _client;

  ContributionRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Contribution>> getContributions({String? period}) async {
    var query = _client.from('contributions').select().eq('user_id', _userId);
    if (period != null) query = query.eq('period', period);
    final data = await query.order('period', ascending: false);
    return data.map((e) => Contribution.fromJson(e)).toList();
  }

  Future<ContributionSummary> getContributionSummary() async {
    final all = await getContributions();
    return ContributionSummary(
      totalPaid: all.where((c) => c.isPaid).fold(0, (s, c) => s + c.totalContribution),
      totalUnpaid: all.where((c) => !c.isPaid).fold(0, (s, c) => s + c.totalContribution),
      sssPaid: all.where((c) => c.isPaid && c.type == 'sss').fold(0, (s, c) => s + c.totalContribution),
      philhealthPaid: all.where((c) => c.isPaid && c.type == 'philhealth').fold(0, (s, c) => s + c.totalContribution),
      pagibigPaid: all.where((c) => c.isPaid && c.type == 'pagibig').fold(0, (s, c) => s + c.totalContribution),
    );
  }

  Future<Contribution> createContribution({
    required String type,
    required String period,
    required double monthlySalary,
    required double employeeShare,
    double? employerShare,
    required double totalContribution,
    String employmentType = 'employed',
    String? notes,
  }) async {
    final data = await _client.from('contributions').upsert({
      'user_id': _userId,
      'type': type,
      'period': period,
      'monthly_salary': monthlySalary,
      'employee_share': employeeShare,
      'employer_share': employerShare,
      'total_contribution': totalContribution,
      'employment_type': employmentType,
      'notes': notes,
    }, onConflict: 'user_id,type,period').select().single();
    return Contribution.fromJson(data);
  }

  Future<void> markPaid(String id) async {
    await _client.from('contributions').update({'is_paid': true}).eq('id', id);
  }

  Future<void> deleteContribution(String id) async {
    await _client.from('contributions').delete().eq('id', id);
  }
}
