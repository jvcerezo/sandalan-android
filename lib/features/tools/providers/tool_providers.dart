import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/local_contribution_repository.dart';
import '../../../data/repositories/local_bill_repository.dart';
import '../../../data/repositories/local_debt_repository.dart';
import '../../../data/repositories/local_insurance_repository.dart';
import '../../../data/repositories/debt_repository.dart';
import '../../../data/repositories/contribution_repository.dart';
import '../../../data/repositories/tax_repository.dart';
import '../../../data/repositories/bill_repository.dart';
import '../../../data/repositories/insurance_repository.dart';
import '../../../data/repositories/recurring_transaction_repository.dart';
import '../../../data/models/debt.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/contribution.dart';
import '../../../data/models/tax_record.dart';
import '../../../data/models/bill.dart';
import '../../../data/models/insurance_policy.dart';
import '../../../data/models/recurring_transaction.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transaction_providers.dart';

// ─── Local-first Repositories ────────────────────────────────────────────────

final debtRepositoryProvider = Provider<LocalDebtRepository>((ref) {
  return LocalDebtRepository(
    AppDatabase.instance,
    ref.watch(supabaseClientProvider),
  );
});

final contributionRepositoryProvider = Provider<LocalContributionRepository>((ref) {
  return LocalContributionRepository(
    AppDatabase.instance,
    ref.watch(supabaseClientProvider),
  );
});

final billRepositoryProvider = Provider<LocalBillRepository>((ref) {
  return LocalBillRepository(
    AppDatabase.instance,
    ref.watch(supabaseClientProvider),
  );
});

final insuranceRepositoryProvider = Provider<LocalInsuranceRepository>((ref) {
  return LocalInsuranceRepository(
    AppDatabase.instance,
    ref.watch(supabaseClientProvider),
  );
});

// ─── Remote repositories (still used by sync + features not yet migrated) ────

final remoteDebtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepository(ref.watch(supabaseClientProvider));
});

final remoteContributionRepositoryProvider = Provider<ContributionRepository>((ref) {
  return ContributionRepository(ref.watch(supabaseClientProvider));
});

final remoteBillRepositoryProvider = Provider<BillRepository>((ref) {
  return BillRepository(ref.watch(supabaseClientProvider));
});

final remoteInsuranceRepositoryProvider = Provider<InsuranceRepository>((ref) {
  return InsuranceRepository(ref.watch(supabaseClientProvider));
});

final taxRepositoryProvider = Provider<TaxRepository>((ref) {
  return TaxRepository(ref.watch(supabaseClientProvider));
});

final recurringTransactionRepositoryProvider = Provider<RecurringTransactionRepository>((ref) {
  return RecurringTransactionRepository(ref.watch(supabaseClientProvider));
});

// ─── Data Providers ───────────────────────────────────────────────────────────

final debtsProvider = FutureProvider<List<Debt>>((ref) async {
  return ref.read(debtRepositoryProvider).getDebts();
});

final debtSummaryProvider = FutureProvider<DebtSummary>((ref) async {
  return ref.read(debtRepositoryProvider).getDebtSummary();
});

final contributionsProvider = FutureProvider<List<Contribution>>((ref) async {
  return ref.read(contributionRepositoryProvider).getContributions();
});

final contributionSummaryProvider = FutureProvider<ContributionSummary>((ref) async {
  return ref.read(contributionRepositoryProvider).getContributionSummary();
});

final taxRecordsProvider = FutureProvider<List<TaxRecord>>((ref) async {
  return ref.read(taxRepositoryProvider).getTaxRecords();
});

final taxSummaryProvider = FutureProvider<TaxSummary>((ref) async {
  return ref.read(taxRepositoryProvider).getTaxSummary();
});

final billsProvider = FutureProvider<List<Bill>>((ref) async {
  return ref.read(billRepositoryProvider).getBills();
});

final billsSummaryProvider = FutureProvider<BillsSummary>((ref) async {
  return ref.read(billRepositoryProvider).getBillsSummary();
});

final insurancePoliciesProvider = FutureProvider<List<InsurancePolicy>>((ref) async {
  return ref.read(insuranceRepositoryProvider).getPolicies();
});

final insuranceSummaryProvider = FutureProvider<InsuranceSummary>((ref) async {
  return ref.read(insuranceRepositoryProvider).getInsuranceSummary();
});

final recurringTransactionsProvider = FutureProvider<List<RecurringTransaction>>((ref) async {
  return ref.read(recurringTransactionRepositoryProvider).getRecurringTransactions();
});

final dueRecurringCountProvider = FutureProvider<int>((ref) async {
  return ref.read(recurringTransactionRepositoryProvider).getDueCount();
});

// ─── Pending Transaction Providers ──────────────────────────────────────────

final pendingTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final txnRepo = ref.read(transactionRepositoryProvider);
  return txnRepo.getPendingTransactions();
});

final pendingBillTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final all = await ref.watch(pendingTransactionsProvider.future);
  return all.where((t) => t.tags != null && t.tags!.contains('bill')).toList();
});

final pendingDebtTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final all = await ref.watch(pendingTransactionsProvider.future);
  return all.where((t) => t.tags != null && t.tags!.contains('debt')).toList();
});

final pendingInsuranceTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final all = await ref.watch(pendingTransactionsProvider.future);
  return all.where((t) => t.tags != null && t.tags!.contains('insurance')).toList();
});
