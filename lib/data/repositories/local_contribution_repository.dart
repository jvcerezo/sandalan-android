import 'package:supabase_flutter/supabase_flutter.dart';
import '../local/app_database.dart';
import '../models/contribution.dart';
import 'contribution_repository.dart';

/// Local-first contribution repository.
class LocalContributionRepository {
  final AppDatabase _db;
  final SupabaseClient _client;

  LocalContributionRepository(this._db, this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ─── Reads ──────────────────────────────────────────────────────────────

  Future<List<Contribution>> getContributions({String? period}) async {
    final rows = await _db.getContributions(_userId, period: period);
    return rows.map(_rowToContribution).toList();
  }

  Future<ContributionSummary> getContributionSummary() async {
    final all = await getContributions();
    return ContributionSummary(
      totalPaid: all.where((c) => c.isPaid).fold(0, (s, c) => s + c.totalContribution),
      totalUnpaid: all.where((c) => !c.isPaid).fold(0, (s, c) => s + c.totalContribution),
      sssPaid: all.where((c) => c.isPaid && c.type == 'sss').fold(0.0, (s, c) => s + c.employeeShare),
      sssEmployerPaid: all.where((c) => c.isPaid && c.type == 'sss').fold(0.0, (s, c) => s + (c.employerShare ?? 0)),
      philhealthPaid: all.where((c) => c.isPaid && c.type == 'philhealth').fold(0.0, (s, c) => s + c.employeeShare),
      philhealthEmployerPaid: all.where((c) => c.isPaid && c.type == 'philhealth').fold(0.0, (s, c) => s + (c.employerShare ?? 0)),
      pagibigPaid: all.where((c) => c.isPaid && c.type == 'pagibig').fold(0.0, (s, c) => s + c.employeeShare),
      pagibigEmployerPaid: all.where((c) => c.isPaid && c.type == 'pagibig').fold(0.0, (s, c) => s + (c.employerShare ?? 0)),
    );
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

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
    final id = _generateId();
    final now = AppDatabase.now();
    final row = <String, dynamic>{
      'id': id,
      'user_id': _userId,
      'type': type,
      'period': period,
      'monthly_salary': monthlySalary,
      'employee_share': employeeShare,
      'employer_share': employerShare,
      'total_contribution': totalContribution,
      'is_paid': 0,
      'employment_type': employmentType,
      'notes': notes,
      'sync_status': 'pending',
      'created_at': now,
      'updated_at': now,
    };
    await _db.upsertContribution(row);
    return _rowToContribution(row);
  }

  Future<void> markPaid(String id) async {
    final existing = await _db.getRowById('local_contributions', id);
    if (existing == null) return;

    final updated = Map<String, dynamic>.from(existing);
    updated['is_paid'] = 1;
    updated['sync_status'] = 'pending';
    updated['updated_at'] = AppDatabase.now();
    await _db.upsertContribution(updated);
  }

  Future<void> deleteContribution(String id) async {
    await _db.deleteContribution(id);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Contribution _rowToContribution(Map<String, dynamic> row) {
    return Contribution(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      createdAt: row['created_at'] as String,
      type: row['type'] as String,
      period: row['period'] as String,
      monthlySalary: (row['monthly_salary'] as num).toDouble(),
      employeeShare: (row['employee_share'] as num).toDouble(),
      employerShare: (row['employer_share'] as num?)?.toDouble(),
      totalContribution: (row['total_contribution'] as num).toDouble(),
      isPaid: row['is_paid'] == 1 || row['is_paid'] == true,
      employmentType: row['employment_type'] as String? ?? 'employed',
      notes: row['notes'] as String?,
    );
  }

  String _generateId() =>
      'local-contrib-${DateTime.now().millisecondsSinceEpoch}-${_counter++}';
  static int _counter = 0;
}
