/// Validates email format and checks against commonly used providers.
class EmailValidator {
  /// Allowed email domains (most commonly used in the Philippines).
  static const _allowedDomains = [
    'gmail.com',
    'yahoo.com',
    'yahoo.com.ph',
    'outlook.com',
    'hotmail.com',
    'live.com',
    'icloud.com',
    'me.com',
    'mac.com',
    'protonmail.com',
    'proton.me',
    'zoho.com',
    'aol.com',
    'mail.com',
    'ymail.com',
    'rocketmail.com',
    'pm.me',
  ];

  /// Allowed TLD patterns (educational, government, corporate).
  static const _allowedTldPatterns = [
    '.edu.ph',
    '.gov.ph',
    '.com.ph',
    '.org.ph',
    '.edu',
    '.org',
    '.co',
  ];

  /// Basic email format check.
  static bool isValidFormat(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// Check if domain is in the allowed list or matches an allowed pattern.
  static bool isAllowedDomain(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return false;
    final domain = parts[1].toLowerCase();

    // Check exact domain match
    if (_allowedDomains.contains(domain)) return true;

    // Check TLD patterns (for .edu.ph, .gov.ph, etc.)
    for (final pattern in _allowedTldPatterns) {
      if (domain.endsWith(pattern)) return true;
    }

    return false;
  }

  /// Full validation: format + domain.
  static String? validate(String email) {
    if (email.isEmpty) return 'Email is required.';
    if (!isValidFormat(email)) return 'Please enter a valid email address.';
    if (!isAllowedDomain(email)) {
      return 'Please use a common email provider (Gmail, Yahoo, Outlook, etc.)';
    }
    return null; // valid
  }
}
