import 'package:flutter_test/flutter_test.dart';
import 'package:sandalan/core/services/sync_service.dart';
import 'package:sandalan/data/local/app_database.dart';

/// Tests for SyncService data mapping methods.
/// These are the highest-risk sync operations — wrong boolean/tags conversion
/// causes silent data corruption across devices.
void main() {
  // We can't instantiate SyncService normally (needs SupabaseClient + AppDatabase),
  // but we CAN test the static parseRetryCount, and for the instance methods
  // we need a minimal setup. For now, test the static and the mapping logic directly.

  group('parseRetryCount', () {
    test('extracts count from "retry:3 Network error: ..."', () {
      expect(SyncService.parseRetryCount('retry:3 Network error: timeout'), 3);
    });

    test('extracts count from "retry:1 ..."', () {
      expect(SyncService.parseRetryCount('retry:1 Something failed'), 1);
    });

    test('returns 0 for empty string', () {
      expect(SyncService.parseRetryCount(''), 0);
    });

    test('returns 0 for non-retry failure reason', () {
      expect(SyncService.parseRetryCount('Validation error: constraint'), 0);
    });

    test('returns 0 for malformed retry prefix', () {
      expect(SyncService.parseRetryCount('retry: no number'), 0);
    });
  });

  group('AppDatabase tags encoding/decoding', () {
    test('encodeTags converts list to JSON string', () {
      final encoded = AppDatabase.encodeTags(['receipt-scan', 'transfer']);
      expect(encoded, isA<String>());
      expect(encoded, contains('receipt-scan'));
    });

    test('decodeTags converts JSON string back to list', () {
      final encoded = AppDatabase.encodeTags(['bill', 'abc123']);
      final decoded = AppDatabase.decodeTags(encoded);
      expect(decoded, ['bill', 'abc123']);
    });

    test('decodeTags returns null for null input', () {
      expect(AppDatabase.decodeTags(null), isNull);
    });

    test('decodeTags returns null for empty string', () {
      expect(AppDatabase.decodeTags(''), isNull);
    });

    test('roundtrip preserves tags', () {
      final original = ['tag1', 'tag2', 'tag3'];
      final encoded = AppDatabase.encodeTags(original);
      final decoded = AppDatabase.decodeTags(encoded);
      expect(decoded, original);
    });
  });
}
