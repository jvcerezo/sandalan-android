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
  bool _selectedYearly = true;
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
      final success = _selectedYearly
          ? await billing.purchaseYearly()
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
    final yearlyPrice = billing.yearlyProduct?.price ?? '₱649';

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
                Text('Try free for 1 month. Cancel anytime.',
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                const SizedBox(height: 24),

                // Free vs Premium comparison table
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outline.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(children: [
                        const Expanded(flex: 3, child: Text('Feature',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        Expanded(flex: 2, child: Text('Free',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
                            textAlign: TextAlign.center)),
                        const Expanded(flex: 2, child: Text('Premium',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6366F1)),
                            textAlign: TextAlign.center)),
                      ]),
                    ),
                    // Rows
                    ..._comparisonRows.map((row) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: cs.outline.withOpacity(0.08))),
                      ),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text(row.$1,
                            style: const TextStyle(fontSize: 12))),
                        Expanded(flex: 2, child: _ComparisonCell(value: row.$2)),
                        Expanded(flex: 2, child: _ComparisonCell(value: row.$3, isPremium: true)),
                      ]),
                    )),
                  ]),
                ),
                const SizedBox(height: 20),

                // Plan selector
                Row(children: [
                  // Monthly
                  Expanded(child: _PlanCard(
                    title: 'Monthly',
                    price: monthlyPrice,
                    period: '/month',
                    selected: !_selectedYearly,
                    onTap: () => setState(() => _selectedYearly = false),
                  )),
                  const SizedBox(width: 10),
                  // Yearly
                  Expanded(child: _PlanCard(
                    title: 'Yearly',
                    price: yearlyPrice,
                    period: '/year',
                    badge: 'Save 32%',
                    selected: _selectedYearly,
                    onTap: () => setState(() => _selectedYearly = true),
                  )),
                ]),
                const SizedBox(height: 8),

                if (_selectedYearly)
                  Text('Just ~₱54/month, less than one milk tea',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(height: 20),

                // Free trial callout
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(LucideIcons.gift, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'First month is free. You won\'t be charged until your trial ends. Cancel anytime.',
                      style: TextStyle(fontSize: 12, color: cs.onSurface, height: 1.4),
                    )),
                  ]),
                ),
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
                            _selectedYearly ? 'Start Free Trial — then $yearlyPrice/yr' : 'Start Free Trial — then $monthlyPrice/mo',
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
                Text('Payment will be charged to your Google Play account. '
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

  // (Feature, Free value, Premium value)
  // Values: '✓' = included, '✗' = not included, or a specific limit string
  static const _comparisonRows = [
    ('Transactions', '✓', '✓'),
    ('Accounts', '2', 'Unlimited'),
    ('Budgets', '3 monthly', 'Unlimited'),
    ('Goals', '2', 'Unlimited'),
    ('Adulting Guide', '✓', '✓'),
    ('Streak & Achievements', '✓', '✓'),
    ('Bills & Debts', '✗', '✓'),
    ('Insurance Tracker', '✗', '✓'),
    ('Investments', '✗', '✓'),
    ('Dashboard Analytics', 'Basic', 'Full'),
    ('Reports', '✗', '✓'),
    ('AI Chat', '✗', '✓'),
    ('Receipt Scanner', '✗', '✓'),
    ('CSV Import', '✗', '✓'),
    ('Calculators & Tools', '✗', '✓'),
    ('Document Vault', '✗', '✓'),
    ('Currency Converter', '✗', '✓'),
    ('Split Bills', '✗', '✓'),
    ('Salary Allocation', '✗', '✓'),
    ('Panganay Mode', '✗', '✓'),
  ];
}

class _ComparisonCell extends StatelessWidget {
  final String value;
  final bool isPremium;
  const _ComparisonCell({required this.value, this.isPremium = false});

  @override
  Widget build(BuildContext context) {
    if (value == '✓') {
      return Icon(LucideIcons.check, size: 16,
          color: isPremium ? const Color(0xFF6366F1) : const Color(0xFF10B981));
    }
    if (value == '✗') {
      return Icon(LucideIcons.x, size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3));
    }
    return Text(value,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: isPremium ? const Color(0xFF6366F1) : Theme.of(context).colorScheme.onSurfaceVariant),
        textAlign: TextAlign.center);
  }
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
