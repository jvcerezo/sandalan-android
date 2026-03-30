import '../services/premium_service.dart';

/// Routes that require premium access. Maps route prefix -> PremiumFeature.
const premiumRoutes = <String, PremiumFeature>{
  '/tools/bills': PremiumFeature.billsTracker,
  '/tools/debts': PremiumFeature.debtManager,
  '/tools/insurance': PremiumFeature.insuranceTracker,
  '/tools/contributions': PremiumFeature.contributionTracker,
  '/tools/taxes': PremiumFeature.taxTracker,
  '/tools/13th-month': PremiumFeature.advancedCalculators,
  '/tools/retirement': PremiumFeature.advancedCalculators,
  '/tools/rent-vs-buy': PremiumFeature.advancedCalculators,
  '/tools/panganay': PremiumFeature.panganayMode,
  '/tools/calculators': PremiumFeature.advancedCalculators,
  '/tools/currency': PremiumFeature.exchangeRates,
  '/tools': PremiumFeature.advancedCalculators,
  '/investments': PremiumFeature.investments,
  '/split-bills': PremiumFeature.splitBills,
  '/salary-allocation': PremiumFeature.salaryAllocation,
  '/vault': PremiumFeature.documentVault,
  '/chat': PremiumFeature.aiChat,
  '/reports': PremiumFeature.advancedReports,
};

/// Check if a path requires premium and the user doesn't have access.
/// Returns the PremiumFeature that's blocking, or null if allowed.
PremiumFeature? blockedByPremium(String path, PremiumService premium) {
  for (final entry in premiumRoutes.entries) {
    if (path == entry.key || path.startsWith('${entry.key}/')) {
      if (!premium.hasAccess(entry.value)) return entry.value;
      return null; // Has access
    }
  }
  return null; // Not a premium route
}
