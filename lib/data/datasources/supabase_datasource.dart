/// Supabase client initialization and singleton access.
/// TODO: Replace placeholder values with actual Supabase credentials.

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDatasource {
  static const _supabaseUrl = 'YOUR_SUPABASE_URL';
  static const _supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  /// Get current user ID or null.
  static String? get currentUserId => auth.currentUser?.id;

  /// Check if user is authenticated.
  static bool get isAuthenticated => auth.currentUser != null;
}
