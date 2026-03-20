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
