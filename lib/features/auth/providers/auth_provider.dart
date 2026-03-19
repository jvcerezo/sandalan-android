import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/models/profile.dart';

/// Supabase client provider.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Auth repository provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// Profile repository provider.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

/// Auth state stream provider.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
});

/// Current user provider (derived from auth state).
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.session?.user;
});

/// Whether the user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// User profile provider (fetches from Supabase).
final profileProvider = FutureProvider<Profile?>((ref) async {
  // Re-fetch when auth state changes
  ref.watch(authStateProvider);
  return ref.read(profileRepositoryProvider).getProfile();
});

/// Whether onboarding is complete.
final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  final profile = ref.watch(profileProvider);
  return profile.valueOrNull?.hasCompletedOnboarding ?? false;
});
