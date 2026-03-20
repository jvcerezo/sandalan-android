/// Input sanitization utility to guard against injection attacks.
/// Apply to all user-entered text before persisting.
class InputSanitizer {
  /// Strip HTML tags, control chars, trim whitespace, enforce maxLength.
  static String sanitize(String input, {int maxLength = 500}) {
    var result = input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
        .trim();
    if (result.length > maxLength) {
      result = result.substring(0, maxLength);
    }
    return result;
  }
}
