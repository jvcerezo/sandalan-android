import 'package:flutter/material.dart';
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

  /// Set to false when ready to enforce premium gates.
  static const _isBetaPeriod = true;

  bool _isPremium = false;
  bool _loaded = false;

  /// Initialize premium state from SharedPreferences.
  Future<void> init() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumKey) ?? false;
    _loaded = true;
  }

  /// Check if the user has access to a premium feature.
  /// During beta, all features are unlocked.
  bool hasAccess(PremiumFeature feature) {
    if (_isBetaPeriod) return true;
    if (_isPremium) return true;

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
  bool get isPremium => _isPremium || _isBetaPeriod;

  /// Set premium status (called after successful purchase verification).
  Future<void> setPremium(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
    if (value) {
      await prefs.setString(_purchaseDateKey, DateTime.now().toIso8601String());
    }
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
void showPremiumGate(BuildContext context, PremiumFeature feature) {
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
              // TODO: Launch Google Play billing flow
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('Coming Soon — Free During Beta!'),
          ),
        ),
        const SizedBox(height: 8),
        Text('All premium features are free during the beta period.',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}
