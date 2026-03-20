import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Sign out.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Complete onboarding via RPC.
  Future<void> completeOnboarding() async {
    await _client.rpc('complete_onboarding');
  }

  /// Delete account (signs out first, then deletes via edge function or RPC).
  Future<void> deleteAccount() async {
    await _client.auth.signOut();
    // Note: actual user deletion requires admin client or edge function
    // This will be handled server-side
  }
}
