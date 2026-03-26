import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Generates and tracks invite links for sharing the app.
class InviteService {
  InviteService._();

  static const _inviteCountKey = 'invite_count';

  /// Generate a personalized invite message and share it.
  static Future<void> shareInvite({String? customMessage}) async {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['first_name'] ?? 'a friend';

    final message = customMessage ??
        'Hey! I\'ve been using Sandalan to track my finances and manage adulting stuff. '
        'It\'s a free Filipino finance app with budgets, goals, bills tracking, and even an AI assistant. '
        'Try it: https://sandalan.app/invite?ref=${user?.id ?? 'guest'}\n\n'
        '— $name';

    await Share.share(message, subject: 'Try Sandalan — Filipino adulting companion');

    // Track invite count
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_inviteCountKey) ?? 0;
    await prefs.setInt(_inviteCountKey, count + 1);
  }

  /// Get the number of invites sent.
  static Future<int> getInviteCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_inviteCountKey) ?? 0;
  }

  /// Generate a share text for a specific feature.
  static String featureShareText(String feature) {
    switch (feature) {
      case 'split':
        return 'I use Sandalan to split bills with friends. '
            'Download it so we can track who owes what: https://sandalan.app';
      case 'goal':
        return 'Join my savings goal on Sandalan! '
            'Download it to track our group savings: https://sandalan.app';
      case 'budget':
        return 'My partner and I use Sandalan to manage our shared budget. '
            'Try it: https://sandalan.app';
      default:
        return 'Check out Sandalan — a free Filipino adulting & finance app: https://sandalan.app';
    }
  }
}
