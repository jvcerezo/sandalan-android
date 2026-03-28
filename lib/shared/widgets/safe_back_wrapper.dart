import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wraps a full-screen pushed route with a PopScope that navigates
/// to [fallbackRoute] on back press instead of popping (which could
/// go to an unrelated screen like Home).
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
        context.go(fallbackRoute);
      },
      child: child,
    );
  }
}
