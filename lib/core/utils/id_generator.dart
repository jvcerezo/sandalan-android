/// Centralized ID generator for local-first entities.
/// Produces collision-resistant IDs in the format: `{prefix}-{timestamp}-{counter}`.
class IdGenerator {
  static int _counter = 0;

  /// Generate a unique local ID with the given prefix.
  /// Example: `local-txn-1711234567890-0`
  static String generate(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${_counter++}';

  // Convenience methods for each entity type
  static String transaction() => generate('local-txn');
  static String account() => generate('local-acct');
  static String budget() => generate('local-bgt');
  static String goal() => generate('local-goal');
  static String bill() => generate('local-bill');
  static String debt() => generate('local-debt');
  static String insurance() => generate('local-ins');
  static String contribution() => generate('local-contrib');
  static String netWorth() => generate('local-nw');
}
