import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wraps a full-screen pushed route with a PopScope that prevents
/// the app from closing when the user presses the system back button.
/// Instead, navigates to [fallbackRoute].
class SafeBackWrapper extends StatelessWidget {
  final Widget child;
  final String fallbackRoute;

  const SafeBackWrapper({
    super.key,
    required this.child,
    required this.fallbackRoute,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallbackRoute);
        }
      },
      child: child,
    );
  }
}
