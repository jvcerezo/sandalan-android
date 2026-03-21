import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/monthly_report_service.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/monthly_report.dart';

/// Provider for the monthly report service.
final monthlyReportServiceProvider = Provider<MonthlyReportService>((ref) {
  return MonthlyReportService(AppDatabase.instance);
});

/// Provider for a specific month's report (generates if not cached).
final monthlyReportProvider =
    FutureProvider.family<MonthlyReport, ({int year, int month})>(
  (ref, params) async {
    final service = ref.read(monthlyReportServiceProvider);
    final report = await service.generateReport(params.year, params.month);
    // Invalidate the all-reports list so it picks up the new/cached report
    ref.invalidate(allReportsProvider);
    return report;
  },
);

/// Provider for all cached reports.
final allReportsProvider = FutureProvider<List<MonthlyReport>>((ref) async {
  final service = ref.read(monthlyReportServiceProvider);
  return service.getAllReports();
});
