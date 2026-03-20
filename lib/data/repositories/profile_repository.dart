import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/guest_mode_service.dart';
import '../models/profile.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  /// Get the current user's profile.
  /// Returns a guest profile when in guest mode.
  Future<Profile?> getProfile() async {
    if (GuestModeService.isGuestSync()) {
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

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromJson(data);
  }

  /// Update profile fields.
  Future<void> updateProfile({
    String? fullName,
    String? primaryCurrency,
    String? avatarUrl,
  }) async {
    if (GuestModeService.isGuestSync()) return; // No-op for guests

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (primaryCurrency != null) updates['primary_currency'] = primaryCurrency;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', userId);
    }
  }

  /// Upload avatar image and update profile.
  /// Returns empty string for guests (no-op).
  Future<String> uploadAvatar(List<int> bytes, String fileName) async {
    if (GuestModeService.isGuestSync()) return '';

    final userId = _client.auth.currentUser!.id;
    final path = '$userId/$fileName';

    await _client.storage.from('avatars').uploadBinary(
      path,
      bytes as dynamic,
      fileOptions: const FileOptions(upsert: true),
    );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    await updateProfile(avatarUrl: publicUrl);
    return publicUrl;
  }

  /// Remove avatar.
  Future<void> removeAvatar() async {
    await updateProfile(avatarUrl: '');
  }
}
