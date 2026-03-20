import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/app_database.dart';

/// Service for managing guest mode (use app without an account).
/// Guest data is stored locally. When the user later creates an account,
/// all local rows are migrated from the guest ID to the real user ID.
class GuestModeService {
  static const _keyIsGuest = 'is_guest_mode';
  static const _keyGuestId = 'guest_user_id';

  // ─── In-memory cache (set on startup / enable / disable) ────────────
  static bool _isGuest = false;
  static String? _guestId;
  static bool _initialized = false;

  /// Must be called once at app startup (after SharedPreferences is available).
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool(_keyIsGuest) ?? false;
    _guestId = prefs.getString(_keyGuestId);
    _initialized = true;
  }

  /// Synchronous check — safe only after [init] has completed.
  static bool isGuestSync() {
    assert(_initialized, 'GuestModeService.init() must be called first');
    return _isGuest;
  }

  /// Synchronous guest ID — returns null when not in guest mode.
  static String? getGuestIdSync() {
    assert(_initialized, 'GuestModeService.init() must be called first');
    return _isGuest ? _guestId : null;
  }

  /// Enable guest mode: generates a UUID-like guest ID and persists it.
  static Future<void> enableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    final guestId = _generateGuestId();
    await prefs.setBool(_keyIsGuest, true);
    await prefs.setString(_keyGuestId, guestId);
    _isGuest = true;
    _guestId = guestId;
  }

  /// Disable guest mode (called after migration or manual logout).
  static Future<void> disableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsGuest, false);
    // Keep _keyGuestId around so migration can reference it if needed.
    _isGuest = false;
  }

  /// Migrate all local DB rows from the guest user ID to [realUserId].
  /// Call this after a guest successfully signs up / logs in.
  static Future<void> migrateToAccount(String realUserId) async {
    final oldId = _guestId;
    if (oldId == null) return;

    final db = AppDatabase.instance;
    // Update user_id in every local table and mark rows pending for sync.
    for (final table in _localTables) {
      await db.updateUserId(table, oldId, realUserId);
    }

    await disableGuestMode();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  static const _localTables = [
    'local_transactions',
    'local_accounts',
    'local_budgets',
    'local_goals',
    'local_contributions',
    'local_bills',
    'local_debts',
    'local_insurance',
  ];

  /// Simple pseudo-UUID v4 generator (no external package needed).
  static String _generateGuestId() {
    final rng = Random.secure();
    String hex(int bytes) =>
        List.generate(bytes, (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    return '${hex(4)}-${hex(2)}-4${hex(1)}${rng.nextInt(16).toRadixString(16)}-'
        '${(8 + rng.nextInt(4)).toRadixString(16)}${hex(1)}${rng.nextInt(256).toRadixString(16).padLeft(2, '0')}-${hex(6)}';
  }
}
