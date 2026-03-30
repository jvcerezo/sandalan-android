import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/billing_service.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/utils/snackbar_helper.dart';

/// Full-screen paywall for Sandalan Premium.
///
/// Shows two plan options (monthly PHP 79, yearly PHP 649),
/// a feature list, streak reward info, and handles purchase flow.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _selectedLifetime = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    BillingService.instance.onPremiumStatusChanged = () {
      if (mounted) {
        setState(() {});
        showSuccessSnackBar(context, 'Welcome to Sandalan Premium!');
        Navigator.of(context).pop(true);
      }
    };
  }

  @override
  void dispose() {
    BillingService.instance.onPremiumStatusChanged = null;
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    setState(() => _purchasing = true);
    try {
      final billing = BillingService.instance;
      final success = _selectedLifetime
          ? await billing.purchaseLifetime()
          : await billing.purchaseMonthly();

      if (!success && mounted) {
        showAppSnackBar(context, 'Could not start purchase. Please try again.', isError: true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Purchase failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _purchasing = true);
    try {
      await BillingService.instance.restorePurchases();
      if (mounted) {
        if (PremiumService.instance.isPremium) {
          showSuccessSnackBar(context, 'Purchase restored!');
          Navigator.of(context).pop(true);
        } else {
          showAppSnackBar(context, 'No previous purchase found.');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Could not restore purchases.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final billing = BillingService.instance;
    final premium = PremiumService.instance;

    // Use store prices if loaded, otherwise show default
    final monthlyPrice = billing.monthlyProduct?.price ?? '₱79';
    final lifetimePrice = billing.lifetimeProduct?.price ?? '₱649';

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(LucideIcons.x, size: 20, color: cs.onSurfaceVariant),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                // Crown icon
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(LucideIcons.crown, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text('Sandalan Premium',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Unlock all features. No ads, ever.',
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                const SizedBox(height: 24),

                // Feature list
                ..._features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(LucideIcons.check, size: 14, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f.$1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(f.$2, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      ]),
                    ),
                  ]),
                )),
                const SizedBox(height: 20),

                // Plan selector
                Row(children: [
                  // Monthly
                  Expanded(child: _PlanCard(
                    title: 'Monthly',
                    price: monthlyPrice,
                    period: '/month',
                    selected: !_selectedLifetime,
                    onTap: () => setState(() => _selectedLifetime = false),
                  )),
                  const SizedBox(width: 10),
                  // Lifetime
                  Expanded(child: _PlanCard(
                    title: 'Lifetime',
                    price: lifetimePrice,
                    period: 'one-time',
                    badge: 'Best Value',
                    selected: _selectedLifetime,
                    onTap: () => setState(() => _selectedLifetime = true),
                  )),
                ]),
                const SizedBox(height: 8),

                if (_selectedLifetime)
                  Text('Pay once, own forever. Less than 12 months of monthly.',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(height: 20),

                // Streak reward callout
                if (!premium.isPremium || premium.isBetaPeriod)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.toolAmber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.toolAmber.withOpacity(0.2)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(LucideIcons.flame, size: 16, color: AppColors.toolAmber),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'Free alternative: maintain a 90-day streak to unlock 1 month of Premium for free!',
                        style: TextStyle(fontSize: 12, color: cs.onSurface, height: 1.4),
                      )),
                    ]),
                  ),

                // Beta callout
                if (premium.isBetaPeriod) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(LucideIcons.sparkles, size: 16, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'All premium features are free during the beta period. '
                        'Subscribe now to lock in the launch price!',
                        style: TextStyle(fontSize: 12, color: cs.onSurface, height: 1.4),
                      )),
                    ]),
                  ),
                ],
              ]),
            ),
          ),

          // Bottom action area
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outline.withOpacity(0.08))),
            ),
            child: SafeArea(
              top: false,
              child: Column(children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _purchasing ? null : _handlePurchase,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _purchasing
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            _selectedLifetime ? 'Unlock Forever — $lifetimePrice' : 'Subscribe Monthly — $monthlyPrice',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _purchasing ? null : _handleRestore,
                  child: Text('Restore Purchase',
                      style: TextStyle(fontSize: 13, color: cs.primary, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 4),
                Text(_selectedLifetime
                    ? 'One-time payment charged to your Google Play account.'
                    : 'Payment will be charged to your Google Play account. '
                      'Subscription auto-renews unless cancelled at least 24 hours before the end of the current period.',
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, height: 1.3),
                    textAlign: TextAlign.center),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  static const _features = [
    ('Bills, Debts & Insurance', 'Due dates, payoff strategies, renewal alerts'),
    ('Advanced Dashboard', 'Health score, spending trends, AI insights'),
    ('Reports & Analytics', 'Monthly charts and category deep-dives'),
    ('Investments Portfolio', 'Track MP2, UITF, stocks, bonds, time deposits'),
    ('All Calculators & Tools', 'Retirement, tax, rent vs buy, FIRE, and more'),
    ('AI Chat + Receipt Scanner', 'Taglish assistant and auto-log from photos'),
    ('CSV Import & Currency', 'Import bank statements, live exchange rates'),
    ('Unlimited Everything', 'No limits on accounts, budgets, or goals'),
    ('Document Vault', 'Encrypted storage for IDs and contracts'),
    ('Split Bills & Salary Allocation', 'Share expenses, budget by paycheck %'),
  ];
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6366F1).withOpacity(0.06) : Colors.transparent,
          border: Border.all(
            color: selected ? const Color(0xFF6366F1) : cs.outline.withOpacity(0.15),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          if (badge != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF6366F1) : cs.onSurface)),
          const SizedBox(height: 4),
          Text(price, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
              color: selected ? const Color(0xFF6366F1) : cs.onSurface)),
          Text(period, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ]),
      ),
    );
  }
}
