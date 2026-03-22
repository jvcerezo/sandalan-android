import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app lock (PIN / biometric) for privacy protection.
/// PIN is stored as a SHA-256 hash in flutter_secure_storage (encrypted).
class AppLockService {
  AppLockService._();
  static final AppLockService instance = AppLockService._();

  // Secure storage for PIN hash (encrypted at rest)
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _pinHashKey = 'app_lock_pin_hash';

  // SharedPreferences for non-sensitive toggles
  static const _enabledKey = 'app_lock_enabled';
  static const _biometricKey = 'app_lock_biometric';

  final _auth = LocalAuthentication();

  /// Hash a PIN using SHA-256 with a fixed app salt.
  static String _hashPin(String pin) {
    final bytes = utf8.encode('sandalan_pin_$pin');
    return sha256.convert(bytes).toString();
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    if (!value) {
      await _storage.delete(key: _pinHashKey);
      await prefs.setBool(_biometricKey, false);
    }
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinHashKey, value: _hashPin(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinHashKey);
    if (storedHash == null) return false;
    return storedHash == _hashPin(pin);
  }

  Future<bool> hasPin() async {
    final stored = await _storage.read(key: _pinHashKey);
    return stored != null;
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, value);
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Sandalan',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Migrate plaintext PIN from SharedPreferences to secure storage.
  /// Call once on app startup. Safe to call multiple times.
  Future<void> migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final oldPin = prefs.getString('app_lock_pin');
    if (oldPin != null) {
      // Hash and store securely
      await _storage.write(key: _pinHashKey, value: _hashPin(oldPin));
      // Remove plaintext
      await prefs.remove('app_lock_pin');
    }
  }
}
