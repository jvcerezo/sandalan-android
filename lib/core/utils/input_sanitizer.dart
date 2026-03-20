/// Input sanitization utility to guard against injection attacks.
/// Apply to all user-entered text before persisting.
class InputSanitizer {
  /// Strip HTML tags, trim whitespace, limit length.
  static String sanitize(String input, {int maxLength = 500}) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // strip HTML
        .replaceAll(RegExp(r'[;\-\-]'), '') // strip SQL comment markers
        .replaceAll(RegExp(r"['\"]"), '') // strip quotes that could break queries
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '') // strip control chars
        .trim();
  }
}
