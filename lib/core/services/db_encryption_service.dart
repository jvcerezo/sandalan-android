import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the SQLite encryption key for the local database.
///
/// The key is generated once on first run and stored in platform-secure storage
/// (Android Keystore / iOS Keychain). When `sqlcipher_flutter_libs` replaces
/// `sqlite3_flutter_libs`, pass the key returned by [getOrCreateKey] to the
/// `NativeDatabase` `setup` callback:
///
/// ```dart
/// final key = await DbEncryptionService.getOrCreateKey();
/// NativeDatabase.createInBackground(
///   file,
///   setup: (db) {
///     db.execute("PRAGMA key = '$key'");
///   },
/// );
/// ```
class DbEncryptionService {
  static const _storageKey = 'db_encryption_key';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Returns the existing encryption key, or generates and persists a new one.
  static Future<String> getOrCreateKey() async {
    var key = await _storage.read(key: _storageKey);
    if (key == null) {
      key = _generateRandomKey();
      await _storage.write(key: _storageKey, value: key);
    }
    return key;
  }

  /// Generates a cryptographically random 32-byte key, hex-encoded (64 chars).
  ///
  /// SQLCipher expects the key as a hex string prefixed with `x'...'` or as
  /// a raw passphrase. We use hex so there are no escaping issues.
  static String _generateRandomKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Checks whether an encryption key already exists in secure storage.
  static Future<bool> hasKey() async {
    final key = await _storage.read(key: _storageKey);
    return key != null;
  }

  /// Deletes the stored encryption key. Use with extreme caution — the
  /// database will become unreadable if it was encrypted with this key.
  static Future<void> deleteKey() async {
    await _storage.delete(key: _storageKey);
  }
}
