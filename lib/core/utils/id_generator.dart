import 'package:uuid/uuid.dart';

/// Centralized ID generator for local-first entities.
/// Produces standard v4 UUIDs compatible with Supabase's uuid column type.
class IdGenerator {
  static const _uuid = Uuid();

  /// Generate a unique UUID v4.
  static String generate() => _uuid.v4();

  // Convenience methods for each entity type
  static String transaction() => generate();
  static String account() => generate();
  static String budget() => generate();
  static String goal() => generate();
  static String bill() => generate();
  static String debt() => generate();
  static String insurance() => generate();
  static String contribution() => generate();
  static String netWorth() => generate();

  /// Check if a string is a valid UUID format.
  static bool isValidUuid(String id) {
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(id);
  }
}
