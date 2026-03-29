import 'package:flutter/material.dart';

/// Shows a themed snackbar with guaranteed contrast.
/// Use [isError] for red error messages, otherwise shows dark background with white text.
void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: Duration(seconds: isError ? 4 : 2),
    ),
  );
}

/// Shows a success snackbar (green).
void showSuccessSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ),
  );
}
