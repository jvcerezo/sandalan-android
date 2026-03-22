import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import 'guest_mode_service.dart';

/// Syncs checklist/guide progress between SharedPreferences and Supabase.
///
/// - On startup: merges cloud + local (union) so no progress is ever lost.
/// - After local changes: debounces 2s then pushes merged set to cloud.
/// - Guest users: no-op (SharedPreferences only).
class ProgressSyncService {
  static ProgressSyncService? _instance;
  static ProgressSyncService get instance {
    _instance ??= ProgressSyncService._();
    return _instance!;
  }

  ProgressSyncService._();

  Timer? _debounceTimer;
  static const _debounceDuration = Duration(seconds: 2);

  /// Pull progress from Supabase profile and merge with local SharedPreferences.
  /// Call this once on app startup for authenticated users.
  Future<void> pullAndMerge() async {
    if (GuestModeService.isGuestSync()) return;

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await client
          .from('profiles')
          .select('checklist_done, checklist_skipped, guides_read')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return;

      final cloudDone = _toStringList(data['checklist_done']);
      final cloudSkipped = _toStringList(data['checklist_skipped']);
      final cloudRead = _toStringList(data['guides_read']);

      final prefs = await SharedPreferences.getInstance();
      final localDone = (prefs.getStringList('checklist_done') ?? []).toSet();
      final localSkipped = (prefs.getStringList('checklist_skipped') ?? []).toSet();
      final localRead = (prefs.getStringList('guides_read') ?? []).toSet();

      // Union merge — never lose progress from either side
      final mergedDone = localDone.union(cloudDone.toSet()).toList();
      final mergedSkipped = localSkipped.union(cloudSkipped.toSet()).toList();
      final mergedRead = localRead.union(cloudRead.toSet()).toList();

      // Save merged data locally
      await prefs.setStringList('checklist_done', mergedDone);
      await prefs.setStringList('checklist_skipped', mergedSkipped);
      await prefs.setStringList('guides_read', mergedRead);

      // Push merged data back to cloud (in case local had items cloud didn't)
      final authRepo = AuthRepository(client);
      await authRepo.updateProgress(
        checklistDone: mergedDone,
        checklistSkipped: mergedSkipped,
        guidesRead: mergedRead,
      );
    } catch (e) {
      debugPrint('ProgressSyncService.pullAndMerge error: $e');
    }
  }

  /// Debounced push of current local progress to Supabase.
  /// Call this after any local SharedPreferences change.
  void pushAfterChange() {
    if (GuestModeService.isGuestSync()) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () async {
      await _pushNow();
    });
  }

  /// Immediately push current local progress to Supabase.
  Future<void> _pushNow() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getStringList('checklist_done') ?? [];
      final skipped = prefs.getStringList('checklist_skipped') ?? [];
      final read = prefs.getStringList('guides_read') ?? [];

      final authRepo = AuthRepository(client);
      await authRepo.updateProgress(
        checklistDone: done,
        checklistSkipped: skipped,
        guidesRead: read,
      );
    } catch (e) {
      debugPrint('ProgressSyncService.pushNow error: $e');
    }
  }

  /// Parse a dynamic value (could be List or null) into List<String>.
  List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  /// Cancel any pending debounce timer.
  void dispose() {
    _debounceTimer?.cancel();
  }
}
