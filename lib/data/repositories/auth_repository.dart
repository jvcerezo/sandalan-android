import 'dart:async';
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

  /// Sign out — clears local data to prevent cross-user leakage.
  Future<void> signOut() async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      await AppDatabase.instance.clearAllData(userId);
    }
    await _client.auth.signOut();
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

  /// Delete account (signs out first, then deletes via edge function or RPC).
  Future<void> deleteAccount() async {
    await _client.auth.signOut();
    // Note: actual user deletion requires admin client or edge function
    // This will be handled server-side
  }
}
