import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Displays a friendly error message with a retry button.
/// Use in `.when(error: ...)` handlers for main content providers.
class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorRetry({
    super.key,
    this.message = 'Something went wrong',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertTriangle, size: 36,
                color: cs.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(message,
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
