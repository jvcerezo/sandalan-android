import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../local/app_database.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  /// Current user or null.
  User? get currentUser => _client.auth.currentUser;

  /// Whether the user is authenticated.
  bool get isAuthenticated => currentUser != null;

  /// Stream of auth state changes.
  Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  /// Sign in with email and password.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email, password, and full name.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  /// Sign out — clears local data and user-specific preferences
  /// to prevent cross-user data leakage.
  Future<void> signOut() async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      await AppDatabase.instance.clearAllData(userId);
    }
    // Clear user-specific SharedPreferences
    await _clearUserPreferences();
    await _client.auth.signOut();
  }

  /// Keys that hold user-specific data and must be cleared on logout.
  static const _userPrefKeys = [
    'ai_personality',
    'ai_assistant_name',
    'ai_setup_complete',
    'life_stage',
    'user_type',
    'focus_areas',
    'hide_balances',
    'checklist_done',
    'checklist_skipped',
    'guides_read',
    'last_sync_date',
    'sandalan_tour_completed',
    'sandalan_tour_pending',
  ];

  Future<void> _clearUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _userPrefKeys) {
      await prefs.remove(key);
    }
  }

  /// Sign in with Google via native Google Sign-In (v7) + Supabase ID token.
  /// Requires a web client ID from Google Cloud Console configured in
  /// Supabase Dashboard > Auth > Providers > Google.
  Future<AuthResponse> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;

    // Initialize with the web client ID (server client ID for Supabase).
    // On Android, the native client ID comes from google-services.json.
    // The serverClientId must be the Web type OAuth client ID.
    const webClientId = String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue: '',
    );

    await googleSignIn.initialize(
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
    );

    final account = await googleSignIn.authenticate();
    final idToken = account.authentication.idToken;

    if (idToken == null) {
      throw Exception('No ID token from Google');
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  /// Send a password reset email via Supabase.
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Complete onboarding via RPC.
  Future<void> completeOnboarding() async {
    await _client.rpc('complete_onboarding');
  }

  /// Update profile fields (life_stage, user_type, focus_areas).
  Future<void> updateProfile({
    String? lifeStage,
    String? userType,
    List<String>? focusAreas,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    final updates = <String, dynamic>{};
    if (lifeStage != null) updates['life_stage'] = lifeStage;
    if (userType != null) updates['user_type'] = userType;
    if (focusAreas != null) updates['focus_areas'] = focusAreas;
    if (updates.isEmpty) return;
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  /// Update checklist/guide progress to Supabase profile.
  Future<void> updateProgress({
    required List<String> checklistDone,
    required List<String> checklistSkipped,
    required List<String> guidesRead,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await _client.from('profiles').update({
      'checklist_done': checklistDone,
      'checklist_skipped': checklistSkipped,
      'guides_read': guidesRead,
    }).eq('id', userId);
  }

  /// Delete account (signs out first, then deletes via edge function or RPC).
  Future<void> deleteAccount() async {
    await _client.auth.signOut();
    // Note: actual user deletion requires admin client or edge function
    // This will be handled server-side
  }
}
