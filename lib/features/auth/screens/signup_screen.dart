import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../data/local/app_database.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../providers/auth_provider.dart';

// ─── Password strength ────────────────────────────────────────────────────────

class _PasswordCheck {
  final String label;
  final bool passed;
  const _PasswordCheck({required this.label, required this.passed});
}

class _PasswordStrength {
  final int score; // 0-5
  final String label;
  final Color color;
  final List<_PasswordCheck> checks;

  const _PasswordStrength({
    required this.score,
    required this.label,
    required this.color,
    required this.checks,
  });
}

_PasswordStrength _getPasswordStrength(String password) {
  final checks = [
    _PasswordCheck(label: 'At least 8 characters', passed: password.length >= 8),
    _PasswordCheck(label: 'Uppercase letter (A\u2013Z)', passed: RegExp(r'[A-Z]').hasMatch(password)),
    _PasswordCheck(label: 'Lowercase letter (a\u2013z)', passed: RegExp(r'[a-z]').hasMatch(password)),
    _PasswordCheck(label: 'Number (0\u20139)', passed: RegExp(r'[0-9]').hasMatch(password)),
    _PasswordCheck(
        label: 'Special character (!@#\$\u2026)',
        passed: RegExp(r'[^A-Za-z0-9]').hasMatch(password)),
  ];

  if (password.isEmpty) {
    return _PasswordStrength(score: 0, label: '', color: Colors.transparent, checks: checks);
  }

  final score = checks.where((c) => c.passed).length;

  if (score <= 1) {
    return _PasswordStrength(score: score, label: 'Weak', color: Colors.red, checks: checks);
  }
  if (score == 2) {
    return _PasswordStrength(score: score, label: 'Fair', color: Colors.orange, checks: checks);
  }
  if (score == 3) {
    return _PasswordStrength(
        score: score, label: 'Good', color: Colors.yellow.shade700, checks: checks);
  }
  return _PasswordStrength(score: score, label: 'Strong', color: Colors.green, checks: checks);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String? _error;
  String? _successEmail;
  bool _wasGuest = false;

  @override
  void initState() {
    super.initState();
    _wasGuest = GuestModeService.isGuestSync();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() => _error = null);

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _error = "Passwords don't match.");
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }

    final strength = _getPasswordStrength(password);
    if (strength.score < 3) {
      setState(() =>
          _error = 'Please use a stronger password (add uppercase, numbers, or special characters).');
      return;
    }
    if (!_agreedToTerms) {
      setState(() =>
          _error = 'You must agree to the Privacy Policy and Terms of Service.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ref.read(authRepositoryProvider).signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.session != null && mounted) {
        // If was previously a guest, migrate local data to the new account
        if (_wasGuest) {
          final newUserId = response.session!.user.id;
          await GuestModeService.migrateToAccount(newUserId);
          // Trigger a full sync to push migrated data to Supabase
          final syncService = SyncService(
            Supabase.instance.client,
            AppDatabase.instance,
          );
          syncService.fullSync();
          syncService.startDailySync();
        }
        context.go('/onboarding');
      } else {
        setState(() {
          _successEmail = email;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = _parseSignUpError(e);
      });
    }
  }

  String _parseSignUpError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('422') || msg.contains('400') || msg.contains('invalid')) {
      return 'Invalid email or password format.';
    }
    if (msg.contains('429') || msg.contains('rate')) {
      return 'Too many attempts. Please try again later.';
    }
    return 'Could not create account. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final password = _passwordController.text;
    final strength = _getPasswordStrength(password);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Center(child: BrandMark(size: 48)),
              const SizedBox(height: 24),

              const Text('Create your account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('No credit card required.',
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),

              // Success message
              if (_successEmail != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.05),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Check your inbox for a confirmation link sent to $_successEmail.',
                    style: const TextStyle(fontSize: 13, color: Colors.green),
                  ),
                ),

              // Error
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.05),
                    border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: TextStyle(fontSize: 13, color: colorScheme.error)),
                ),

              // Full Name
              TextField(
                controller: _fullNameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),

              // Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              // Strength meter
              if (password.isNotEmpty) ...[
                const SizedBox(height: 8),
                // Bars
                Row(
                  children: List.generate(4, (i) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: strength.score > i
                              ? strength.color
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Password strength',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    Text(strength.label,
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600, color: strength.color)),
                  ],
                ),
                const SizedBox(height: 6),
                // Checklist
                ...strength.checks.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: c.passed ? Colors.green : colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: c.passed
                              ? const Icon(Icons.check, size: 10, color: Colors.white)
                              : Center(
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: colorScheme.onSurfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Text(c.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: c.passed
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            )),
                      ]),
                    )),
              ],
              const SizedBox(height: 12),

              // Confirm Password
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Terms checkbox
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _agreedToTerms,
                    onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                    child: Text(
                      'I have read and agree to the Privacy Policy and Terms of Service. '
                      'I consent to Sandalan collecting and processing my personal data as described.',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, height: 1.4),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // Submit
              FilledButton(
                onPressed: (_isLoading || !_agreedToTerms) ? null : _handleSignUp,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_successEmail != null ? 'Resend / Try again' : 'Create Account'),
              ),
              const SizedBox(height: 16),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Already have an account? ',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text('Sign in',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
