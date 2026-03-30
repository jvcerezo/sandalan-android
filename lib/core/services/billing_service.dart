import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'premium_service.dart';

/// Google Play product IDs — must match Play Console in-app products.
class BillingProducts {
  static const monthlyId = 'sandalan_premium_monthly';
  static const yearlyId = 'sandalan_premium_yearly';
  static const allIds = {monthlyId, yearlyId};
}

/// Wraps the Google Play billing API for Sandalan premium subscriptions.
///
/// Handles:
/// - Initializing the billing client
/// - Loading available products
/// - Launching the purchase flow
/// - Listening for purchase updates (new purchases + restored)
/// - Verifying and acknowledging purchases
/// - Persisting premium status via PremiumService
class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _available = false;
  List<ProductDetails> _products = [];
  bool _initialized = false;

  /// Whether the store is available.
  bool get isAvailable => _available;

  /// Loaded product details (monthly + lifetime).
  List<ProductDetails> get products => List.unmodifiable(_products);

  /// Get the monthly product, if loaded.
  ProductDetails? get monthlyProduct =>
      _products.where((p) => p.id == BillingProducts.monthlyId).firstOrNull;

  /// Get the yearly product, if loaded.
  ProductDetails? get yearlyProduct =>
      _products.where((p) => p.id == BillingProducts.yearlyId).firstOrNull;

  /// Callback fired when premium status changes (UI can listen to rebuild).
  VoidCallback? onPremiumStatusChanged;

  // ─── Initialization ──────────────────────────────────────────────────────

  /// Initialize billing. Safe to call multiple times (idempotent).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _available = await _iap.isAvailable();
    if (!_available) {
      debugPrint('[BillingService] Store not available');
      return;
    }

    // Listen for purchase updates (new purchases, restored, errors).
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('[BillingService] Stream error: $error'),
    );

    // Load available products.
    await _loadProducts();

    // Restore any existing purchases (e.g. reinstall, new device).
    await restorePurchases();
  }

  /// Load product details from the store.
  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(BillingProducts.allIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[BillingService] Products not found: ${response.notFoundIDs}');
    }
    if (response.error != null) {
      debugPrint('[BillingService] Query error: ${response.error}');
    }

    _products = response.productDetails;
    debugPrint('[BillingService] Loaded ${_products.length} products');
  }

  // ─── Purchase Flow ───────────────────────────────────────────────────────

  /// Launch the subscription purchase flow for a specific product.
  /// Returns false if the product isn't available.
  Future<bool> purchase(ProductDetails product) async {
    if (!_available) return false;

    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      // Subscriptions must use buyNonConsumable (the in_app_purchase plugin
      // routes subscriptions correctly on Google Play — the "non-consumable"
      // name is misleading but is the correct API for subscriptions).
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('[BillingService] Purchase error: $e');
      return false;
    }
  }

  /// Convenience: purchase monthly plan.
  Future<bool> purchaseMonthly() async {
    final product = monthlyProduct;
    if (product == null) return false;
    return purchase(product);
  }

  /// Convenience: purchase yearly plan.
  Future<bool> purchaseYearly() async {
    final product = yearlyProduct;
    if (product == null) return false;
    return purchase(product);
  }

  /// Restore previous purchases (e.g. after reinstall).
  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  // ─── Purchase Stream Handler ─────────────────────────────────────────────

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseList) async {
    for (final purchase in purchaseList) {
      debugPrint('[BillingService] Purchase update: ${purchase.productID} '
          'status=${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndDeliver(purchase);

        case PurchaseStatus.error:
          debugPrint('[BillingService] Purchase error: ${purchase.error}');
          // Complete the purchase to dismiss the system UI
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }

        case PurchaseStatus.pending:
          debugPrint('[BillingService] Purchase pending...');

        case PurchaseStatus.canceled:
          debugPrint('[BillingService] Purchase canceled');
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
      }
    }
  }

  /// Verify purchase and grant premium access.
  ///
  /// For now, verification is client-side (Google Play handles receipt
  /// integrity). For production hardening, add server-side verification
  /// via Supabase Edge Function + Google Play Developer API.
  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    // Grant premium access
    await PremiumService.instance.setPremium(true);

    // Persist purchase token for server-side verification later
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('purchase_token', purchase.purchaseID ?? '');
    await prefs.setString('purchase_product_id', purchase.productID);
    await prefs.setString(
        'purchase_date', DateTime.now().toIso8601String());

    // Acknowledge the purchase (required by Google Play)
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }

    debugPrint('[BillingService] Premium granted for ${purchase.productID}');
    onPremiumStatusChanged?.call();
  }

  // ─── Cleanup ─────────────────────────────────────────────────────────────

  void dispose() {
    _subscription?.cancel();
  }
}
