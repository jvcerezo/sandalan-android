import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../router/app_router.dart';
import '../../features/transactions/widgets/add_transaction_dialog.dart';
import '../../features/transactions/screens/receipt_scanner_screen.dart';
import 'premium_service.dart';

class DeepLinkService {
  DeepLinkService._();
  static final instance = DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  /// Call once after the app has built its first frame.
  Future<void> init() async {
    // Handle the initial link (cold start from shortcut).
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri);
    }

    // Listen for subsequent links (warm start).
    _sub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void dispose() {
    _sub?.cancel();
  }

  void _handleUri(Uri uri) {
    final path = uri.toString();

    if (path.contains('quick-add/expense')) {
      appRouter.go('/home');
      Future.delayed(const Duration(milliseconds: 400), () {
        _showModal(const AddTransactionDialog(isIncome: false));
      });
    } else if (path.contains('quick-add/income')) {
      appRouter.go('/home');
      Future.delayed(const Duration(milliseconds: 400), () {
        _showModal(const AddTransactionDialog(isIncome: true));
      });
    } else if (path.contains('scan-receipt')) {
      if (PremiumService.instance.hasAccess(PremiumFeature.receiptScanner)) {
        appRouter.go('/home');
        Future.delayed(const Duration(milliseconds: 400), () {
          _showModal(const ReceiptScannerScreen());
        });
      } else {
        appRouter.go('/more');
      }
    } else if (path.contains('chat')) {
      appRouter.go('/chat'); // Router redirect handles premium gate
    }
  }

  void _showModal(Widget sheet) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }
}
