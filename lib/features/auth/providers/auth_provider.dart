import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/guest_mode_service.dart';
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

/// Whether the user is in guest mode.
final isGuestProvider = Provider<bool>((ref) {
  return GuestModeService.isGuestSync();
});

/// Whether the user is authenticated (real user OR guest).
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null || ref.watch(isGuestProvider);
});

/// User profile provider (fetches from Supabase, or returns guest profile).
final profileProvider = FutureProvider<Profile?>((ref) async {
  final isGuest = ref.watch(isGuestProvider);
  if (isGuest) {
    return Profile(
      id: GuestModeService.getGuestIdSync() ?? 'guest',
      fullName: 'Guest',
      email: null,
      role: 'user',
      createdAt: DateTime.now().toIso8601String(),
      primaryCurrency: 'PHP',
      hasCompletedOnboarding: true,
      avatarUrl: null,
    );
  }
  // Re-fetch when auth state changes
  ref.watch(authStateProvider);
  return ref.read(profileRepositoryProvider).getProfile();
});

/// Whether onboarding is complete.
final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  final profile = ref.watch(profileProvider);
  return profile.valueOrNull?.hasCompletedOnboarding ?? false;
});
