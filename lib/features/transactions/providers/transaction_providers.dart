import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/local_transaction_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/models/transaction.dart';
import '../../auth/providers/auth_provider.dart';

final transactionRepositoryProvider = Provider<LocalTransactionRepository>((ref) {
  return LocalTransactionRepository(
    AppDatabase.instance,
    ref.watch(supabaseClientProvider),
  );
});

/// Keep the Supabase repository available for sync service usage.
final remoteTransactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(supabaseClientProvider));
});

final recentTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  return ref.read(transactionRepositoryProvider).getRecentTransactions();
});

final transactionFiltersProvider = StateProvider<TransactionFilters>((ref) {
  return const TransactionFilters();
});

final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final filters = ref.watch(transactionFiltersProvider);
  return ref.read(transactionRepositoryProvider).getTransactions(filters);
});

final transactionsCountProvider = FutureProvider<int>((ref) async {
  final filters = ref.watch(transactionFiltersProvider);
  return ref.read(transactionRepositoryProvider).getTransactionsCount(filters);
});

final transactionsSummaryProvider = FutureProvider<TransactionsSummary>((ref) async {
  return ref.read(transactionRepositoryProvider).getTransactionsSummary();
});

/// All confirmed transactions for the current month (no pagination).
/// Used by dashboard charts and insights instead of the paginated transactionsProvider.
final currentMonthTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  return ref.read(transactionRepositoryProvider).getCurrentMonthTransactions();
});

/// All confirmed transactions for the last 6 months (no pagination).
/// Used by monthly trend and compare views.
final last6MonthsTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  return ref.read(transactionRepositoryProvider).getTransactionsForLastMonths(6);
});

// ─── Aggregate providers (SQL-level, no full row loading) ──────────────

/// Category spending totals for the current month via SQL GROUP BY.
/// Returns List<Map> with {category: String, total: double}.
final categoryTotalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(transactionRepositoryProvider).getCategoryTotals();
});

/// Monthly income/expense totals for the last 6 months via SQL GROUP BY.
/// Returns List<Map> with {month: String, income: double, expenses: double}.
final monthlyTotalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(transactionRepositoryProvider).getMonthlyTotals(6);
});

/// Monthly net totals for the last 6 months (for net worth view).
/// Returns List<Map> with {month: String, net: double}.
final monthlyNetTotalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(transactionRepositoryProvider).getMonthlyNetTotals(6);
});

/// Per-category expense totals for this month vs last month (compare view).
/// Returns List<Map> with {category: String, month: String, total: double}.
final compareCategoryTotalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final now = DateTime.now();
  final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final lastMonth = DateTime(now.year, now.month - 1);
  final lastMonthStr = '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';
  return ref.read(transactionRepositoryProvider).getCategoryTotalsForMonths(thisMonth, lastMonthStr);
});
