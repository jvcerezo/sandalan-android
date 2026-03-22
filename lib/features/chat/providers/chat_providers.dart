import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/chat_engine.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/chat_models.dart';
import '../../../data/repositories/chat_report_repository.dart';
import '../../../data/repositories/learned_keyword_repository.dart';
import '../../accounts/providers/account_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transaction_providers.dart';
import 'chat_notifier.dart';

String _currentUserId() {
  return Supabase.instance.client.auth.currentUser?.id
      ?? GuestModeService.getGuestIdSync()
      ?? 'anonymous';
}

final learnedKeywordRepositoryProvider = Provider<LearnedKeywordRepository>((ref) {
  return LearnedKeywordRepository(AppDatabase.instance, _currentUserId);
});

final chatReportRepositoryProvider = Provider<ChatReportRepository>((ref) {
  return ChatReportRepository(
    AppDatabase.instance,
    ref.watch(supabaseClientProvider),
  );
});

final chatEngineProvider = Provider<ChatEngine>((ref) {
  final lkRepo = ref.watch(learnedKeywordRepositoryProvider);
  final accountRepo = ref.watch(accountRepositoryProvider);
  return ChatEngine(
    lkRepo,
    () async {
      final accounts = await accountRepo.getAccounts();
      return accounts
          .map((a) => AccountInfo(id: a.id, name: a.name, type: a.type))
          .toList();
    },
  );
});

final chatStateProvider = StateNotifierProvider<ChatNotifier, ChatUiState>((ref) {
  return ChatNotifier(
    engine: ref.watch(chatEngineProvider),
    transactionRepo: ref.watch(transactionRepositoryProvider),
    accountRepo: ref.watch(accountRepositoryProvider),
    learnedRepo: ref.watch(learnedKeywordRepositoryProvider),
    reportRepo: ref.watch(chatReportRepositoryProvider),
    invalidateProviders: () {
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(transactionsSummaryProvider);
      ref.invalidate(currentMonthTransactionsProvider);
      ref.invalidate(accountsProvider);
    },
  );
});
