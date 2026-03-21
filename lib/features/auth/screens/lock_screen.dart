import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/app_lock_service.dart';
import '../../../shared/widgets/brand_mark.dart';

/// Full-screen lock overlay shown when app resumes with app lock enabled.
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  int _failedAttempts = 0;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  String? _error;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final available = await AppLockService.instance.isBiometricAvailable();
    final enabled = await AppLockService.instance.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
      if (available && enabled) {
        _authenticateBiometric();
      }
    }
  }

  Future<void> _authenticateBiometric() async {
    final success = await AppLockService.instance.authenticateWithBiometric();
    if (success) {
      widget.onUnlocked();
    }
  }

  void _onDigit(String digit) {
    if (_cooldownSeconds > 0) return;
    if (_pin.length >= 6) return;

    HapticFeedback.lightImpact();
    setState(() {
      _pin += digit;
      _error = null;
    });

    if (_pin.length >= 4) {
      _verifyPin();
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _verifyPin() async {
    final ok = await AppLockService.instance.verifyPin(_pin);
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _failedAttempts++;
        _pin = '';
        if (_failedAttempts >= 5) {
          _cooldownSeconds = 30;
          _error = 'Too many attempts. Wait 30 seconds.';
          _startCooldown();
        } else {
          _error = 'Incorrect PIN. ${5 - _failedAttempts} attempts left.';
        }
      });
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _cooldownSeconds--;
          if (_cooldownSeconds <= 0) {
            _cooldownTimer?.cancel();
            _failedAttempts = 0;
            _error = null;
          } else {
            _error = 'Too many attempts. Wait $_cooldownSeconds seconds.';
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Logo
            const BrandMark(size: 48),
            const SizedBox(height: 12),
            Text('Sandalan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 24),
            // PIN dots
            Text('Enter your PIN', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _pin.length;
                return Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? cs.primary : Colors.transparent,
                    border: Border.all(color: cs.primary, width: 2),
                  ),
                );
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(fontSize: 12, color: cs.error)),
            ],
            const Spacer(),
            // Number pad
            _buildNumPad(cs),
            const SizedBox(height: 16),
            // Biometric button
            if (_biometricAvailable && _biometricEnabled)
              TextButton.icon(
                onPressed: _authenticateBiometric,
                icon: const Icon(LucideIcons.fingerprint, size: 18),
                label: const Text('Use Fingerprint'),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumPad(ColorScheme cs) {
    const digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Column(
      children: digits.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 80, height: 64);
            if (key == 'del') {
              return SizedBox(
                width: 80,
                height: 64,
                child: IconButton(
                  onPressed: _onDelete,
                  icon: Icon(LucideIcons.delete, size: 22, color: cs.onSurfaceVariant),
                ),
              );
            }
            return SizedBox(
              width: 80,
              height: 64,
              child: InkWell(
                onTap: () => _onDigit(key),
                borderRadius: BorderRadius.circular(32),
                child: Center(
                  child: Text(key,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: cs.onSurface)),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
