import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../local/app_database.dart';

/// Repository for chat error reports. Queues reports locally,
/// syncs to Supabase when online. All data is scoped by user_id.
class ChatReportRepository {
  final AppDatabase _db;
  final SupabaseClient _client;

  ChatReportRepository(this._db, this._client);

  String get _userId =>
      _client.auth.currentUser?.id ?? GuestModeService.getGuestIdSync() ?? 'anonymous';

  /// Queue a correction report for later sync.
  Future<void> queueReport({
    required String userInput,
    required String parsedIntent,
    double? parsedAmount,
    String? parsedCategory,
    String? parsedDescription,
    String? parsedAccount,
    String? parsedType,
    String? categorySource,
    double? tfliteConfidence,
    required String errorType,
    String? correctedCategory,
    double? correctedAmount,
    String? correctedAccount,
    String? correctedType,
    String? correctedDescription,
    String? userComment,
  }) async {
    await _db.insertChatReport({
      'user_id': _userId,
      'user_input': userInput,
      'parsed_intent': parsedIntent,
      'parsed_amount': parsedAmount,
      'parsed_category': parsedCategory,
      'parsed_description': parsedDescription,
      'parsed_account': parsedAccount,
      'parsed_type': parsedType,
      'category_source': categorySource,
      'tflite_confidence': tfliteConfidence,
      'error_type': errorType,
      'corrected_category': correctedCategory,
      'corrected_amount': correctedAmount,
      'corrected_account': correctedAccount,
      'corrected_type': correctedType,
      'corrected_description': correctedDescription,
      'user_comment': userComment,
      'sync_status': 'pending',
      'created_at': AppDatabase.now(),
    });
  }

  /// Push all pending reports to Supabase. Called by SyncService.
  Future<void> syncPendingReports() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final pending = await _db.getPendingChatReports(userId: userId);
    for (final row in pending) {
      try {
        final remote = Map<String, dynamic>.from(row);
        remote.remove('id');
        remote.remove('sync_status');
        remote['user_id'] = userId;
        remote['app_version'] = null;
        remote['device_model'] = null;

        await _client.from('chat_reports').insert(remote);
        await _db.markChatReportSynced(row['id'] as int);
      } catch (_) {
        // Individual report failure shouldn't stop others
      }
    }
  }
}
