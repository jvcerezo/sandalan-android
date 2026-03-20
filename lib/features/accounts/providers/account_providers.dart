import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/local_account_repository.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/models/account.dart';
import '../../auth/providers/auth_provider.dart';

final accountRepositoryProvider = Provider<LocalAccountRepository>((ref) {
  return LocalAccountRepository(
    AppDatabase.instance,
    ref.watch(supabaseClientProvider),
  );
});

/// Keep the Supabase repository available for sync service usage.
final remoteAccountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(supabaseClientProvider));
});

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  return ref.read(accountRepositoryProvider).getAccounts();
});

final archivedAccountsProvider = FutureProvider<List<Account>>((ref) async {
  return ref.read(accountRepositoryProvider).getArchivedAccounts();
});

final totalBalanceProvider = Provider<double>((ref) {
  final accounts = ref.watch(accountsProvider);
  return accounts.valueOrNull?.fold<double>(0.0, (sum, a) => sum + a.balance) ?? 0;
});
