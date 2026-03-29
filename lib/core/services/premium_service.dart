import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Premium feature identifiers.
enum PremiumFeature {
  aiChat,            // AI chat assistant
  receiptScanner,    // Receipt scanner (OCR)
  advancedReports,   // Monthly/yearly reports with charts
  unlimitedAccounts, // More than 3 accounts
  documentVault,     // Document vault storage
  csvImport,         // Import from bank CSV
  exchangeRates,     // Live exchange rates
  sharedGoals,       // Shared savings goals
}

/// Manages premium feature access.
///
/// Current model: everything free during beta.
/// When ready to monetize, flip [_isBetaPeriod] to false
/// and features gate behind [isPremium].
class PremiumService {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  static const _premiumKey = 'is_premium_user';
  static const _purchaseDateKey = 'premium_purchase_date';
  static const _streakRewardExpiryKey = 'streak_reward_expiry';
  static const _streakRewardClaimedKey = 'streak_reward_claimed_count';
  static const _lastServerTimeKey = 'last_verified_server_time';

  /// Streak days required to unlock 1 month of free premium.
  static const streakRewardThreshold = 90;

  /// Set to false when ready to enforce premium gates.
  static const _isBetaPeriod = false;

  bool _isPremium = false;
  bool _loaded = false;
  DateTime? _streakRewardExpiry;

  /// Initialize premium state from SharedPreferences.
  Future<void> init() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumKey) ?? false;

    // Check streak reward expiry
    final expiryStr = prefs.getString(_streakRewardExpiryKey);
    if (expiryStr != null) {
      _streakRewardExpiry = DateTime.tryParse(expiryStr);
    }

    _loaded = true;
  }

  /// Check if the user has access to a premium feature.
  /// During beta, all features are unlocked.
  bool hasAccess(PremiumFeature feature) {
    if (_isBetaPeriod) return true;
    if (_isPremium) return true;
    if (hasActiveStreakReward) return true;

    // Free tier features (always available):
    switch (feature) {
      case PremiumFeature.aiChat:
      case PremiumFeature.receiptScanner:
      case PremiumFeature.advancedReports:
      case PremiumFeature.documentVault:
      case PremiumFeature.csvImport:
      case PremiumFeature.exchangeRates:
      case PremiumFeature.sharedGoals:
        return false;
      case PremiumFeature.unlimitedAccounts:
        return false; // Free tier: 3 accounts max
    }
  }

  /// Whether the app is currently in free beta mode.
  bool get isBetaPeriod => _isBetaPeriod;

  /// Whether the user has an active premium subscription.
  bool get isPremium => _isPremium || _isBetaPeriod || hasActiveStreakReward;

  /// Whether the user has an active streak reward (free premium from 90-day streak).
  bool get hasActiveStreakReward {
    if (_streakRewardExpiry == null) return false;
    return DateTime.now().isBefore(_streakRewardExpiry!);
  }

  /// Days remaining on streak reward, or 0 if expired/none.
  int get streakRewardDaysLeft {
    if (_streakRewardExpiry == null) return 0;
    final diff = _streakRewardExpiry!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  /// How many times the user has claimed the streak reward.
  Future<int> getStreakRewardClaimCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakRewardClaimedKey) ?? 0;
  }

  /// Set premium status (called after successful purchase verification).
  Future<void> setPremium(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
    if (value) {
      await prefs.setString(_purchaseDateKey, DateTime.now().toIso8601String());
    }
  }

  // ─── Streak Reward ────────────────────────────────────────────────────────

  /// Claim the 90-day streak reward: 1 month of free premium.
  ///
  /// Uses server time from worldtimeapi.org to prevent device clock manipulation.
  /// Returns true if successfully claimed, false if validation failed.
  Future<bool> claimStreakReward(int currentStreak) async {
    if (currentStreak < streakRewardThreshold) return false;
    if (hasActiveStreakReward) return false; // Already have an active reward

    // Verify with server time — prevents claiming by changing device date
    final serverTime = await getServerTime();
    if (serverTime == null) return false; // Can't verify, reject

    // Anti-tamper: check device time isn't more than 24h ahead of server
    final deviceTime = DateTime.now();
    final drift = deviceTime.difference(serverTime).inHours.abs();
    if (drift > 24) return false; // Clock is manipulated

    // Anti-tamper: check that time hasn't gone backwards since last verification
    final prefs = await SharedPreferences.getInstance();
    final lastServerStr = prefs.getString(_lastServerTimeKey);
    if (lastServerStr != null) {
      final lastServer = DateTime.tryParse(lastServerStr);
      if (lastServer != null && serverTime.isBefore(lastServer)) {
        return false; // Time went backwards — tampered
      }
    }

    // All checks passed — grant reward
    _streakRewardExpiry = serverTime.add(const Duration(days: 30));
    await prefs.setString(_streakRewardExpiryKey, _streakRewardExpiry!.toIso8601String());
    await prefs.setString(_lastServerTimeKey, serverTime.toIso8601String());
    final claimCount = prefs.getInt(_streakRewardClaimedKey) ?? 0;
    await prefs.setInt(_streakRewardClaimedKey, claimCount + 1);

    return true;
  }

  /// Fetch current time from a trusted server.
  /// Uses worldtimeapi.org (free, no key needed).
  /// Returns null if unavailable (no internet, API down).
  static Future<DateTime?> getServerTime() async {
    try {
      final response = await http.get(
        Uri.parse('https://worldtimeapi.org/api/timezone/Asia/Manila'),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        // Response contains "datetime": "2026-03-28T14:30:00.123456+08:00"
        final body = response.body;
        final match = RegExp(r'"datetime"\s*:\s*"([^"]+)"').firstMatch(body);
        if (match != null) {
          return DateTime.tryParse(match.group(1)!);
        }
      }
    } catch (_) {}

    // Fallback: try HTTP Date header from any reliable server
    try {
      final response = await http.head(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 5));
      final dateHeader = response.headers['date'];
      if (dateHeader != null) {
        return HttpDate.parse(dateHeader);
      }
    } catch (_) {}

    return null;
  }

  /// Get the list of premium features for display.
  static List<PremiumFeatureInfo> get featureList => [
    const PremiumFeatureInfo(
      feature: PremiumFeature.aiChat,
      title: 'AI Chat Assistant',
      description: 'Ask questions about your finances in Taglish',
      icon: LucideIcons.messageCircle,
    ),
    const PremiumFeatureInfo(
      feature: PremiumFeature.receiptScanner,
      title: 'Receipt Scanner',
      description: 'Scan receipts to auto-log expenses',
      icon: LucideIcons.scanLine,
    ),
    const PremiumFeatureInfo(
      feature: PremiumFeature.advancedReports,
      title: 'Advanced Reports',
      description: 'Detailed monthly reports with charts and insights',
      icon: LucideIcons.pieChart,
    ),
    const PremiumFeatureInfo(
      feature: PremiumFeature.unlimitedAccounts,
      title: 'Unlimited Accounts',
      description: 'Track all your bank accounts, e-wallets, and cash',
      icon: LucideIcons.landmark,
    ),
    const PremiumFeatureInfo(
      feature: PremiumFeature.documentVault,
      title: 'Document Vault',
      description: 'Securely store IDs, contracts, and important files',
      icon: LucideIcons.folderLock,
    ),
    const PremiumFeatureInfo(
      feature: PremiumFeature.csvImport,
      title: 'Bank Import',
      description: 'Import from GCash, Maya, BDO, BPI, Metrobank',
      icon: LucideIcons.upload,
    ),
  ];
}

class PremiumFeatureInfo {
  final PremiumFeature feature;
  final String title;
  final String description;
  final IconData icon;

  const PremiumFeatureInfo({
    required this.feature,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Shows a premium upsell bottom sheet when a gated feature is accessed.
/// [onUpgradeTap] is called when the user taps "See Plans & Pricing".
/// The caller should navigate to the paywall screen.
void showPremiumGate(BuildContext context, PremiumFeature feature, {VoidCallback? onUpgradeTap}) {
  final info = PremiumService.featureList.where((f) => f.feature == feature).firstOrNull;
  final cs = Theme.of(context).colorScheme;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(info?.icon ?? LucideIcons.crown, size: 32, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text('Upgrade to Premium', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 8),
        Text(info != null ? '${info.title} is a premium feature.' : 'This is a premium feature.',
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant), textAlign: TextAlign.center),
        const SizedBox(height: 20),

        // Feature list
        ...PremiumService.featureList.take(4).map((f) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(LucideIcons.check, size: 16, color: const Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(f.title, style: const TextStyle(fontSize: 13)),
          ]),
        )),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onUpgradeTap?.call();
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('See Plans & Pricing'),
          ),
        ),
        if (PremiumService.instance.isBetaPeriod) ...[
          const SizedBox(height: 8),
          Text('All premium features are free during the beta period.',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ]),
    ),
  );
}

/// Helper: show the premium gate and navigate to the paywall on upgrade tap.
/// Use this from anywhere — it handles the Navigator.push internally.
void showPremiumGateWithPaywall(BuildContext context, PremiumFeature feature) {
  showPremiumGate(context, feature, onUpgradeTap: () {
    openPaywall(context);
  });
}

/// Open the paywall screen as a full-screen push.
void openPaywall(BuildContext context) {
  if (_paywallBuilder == null) {
    debugPrint('[PremiumService] Paywall builder not registered');
    return;
  }
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (_) => _paywallBuilder!()),
  );
}

/// Registry for the paywall screen builder.
/// Set this in main.dart after imports are resolved.
Widget Function()? _paywallBuilder;

/// Register the paywall screen builder. Call once during app init.
void registerPaywallBuilder(Widget Function() builder) {
  _paywallBuilder = builder;
}
