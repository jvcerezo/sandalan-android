import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../data/local/app_database.dart';
import '../../../core/utils/email_validator.dart';
import '../../../core/utils/input_validator.dart';
import '../../../core/constants/legal.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../../core/services/premium_service.dart';
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
    final fullName = InputValidator.name(_fullNameController.text);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() => _error = null);

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    final emailError = EmailValidator.validate(email);
    if (emailError != null) {
      setState(() => _error = emailError);
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
        // Activate 30-day free premium trial for new signups
        await PremiumService.instance.activateSignupTrial();

        // If was previously a guest, migrate local data to the new account
        if (_wasGuest) {
          final newUserId = response.session!.user.id;
          await GuestModeService.migrateToAccount(newUserId);
          // Migrate guest preferences to Supabase profile
          await _migrateGuestPreferences();
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

  /// Migrate guest-mode SharedPreferences (life_stage, user_type, focus_areas)
  /// to the new Supabase profile so they persist after account creation.
  Future<void> _migrateGuestPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lifeStage = prefs.getString('life_stage');
      final userType = prefs.getString('user_type');
      final focusAreas = prefs.getStringList('focus_areas');
      if (lifeStage != null || userType != null || focusAreas != null) {
        await ref.read(authRepositoryProvider).updateProfile(
          lifeStage: lifeStage,
          userType: userType,
          focusAreas: focusAreas,
        );
      }
    } catch (_) {
      // Non-critical — user can re-set in settings
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (response.session != null && mounted) {
        if (_wasGuest) {
          final newUserId = response.session!.user.id;
          await GuestModeService.migrateToAccount(newUserId);
          await _migrateGuestPreferences();
          final syncService = SyncService(Supabase.instance.client, AppDatabase.instance);
          syncService.fullSync();
          syncService.startDailySync();
        }
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        setState(() {
          _isLoading = false;
          _error = msg.contains('cancelled') || msg.contains('canceled')
              ? null
              : 'Google sign-up failed. Please try again.';
        });
      }
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
                    color: Colors.green.withOpacity(0.05),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
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
                    color: colorScheme.error.withOpacity(0.05),
                    border: Border.all(color: colorScheme.error.withOpacity(0.2)),
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
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, height: 1.4),
                      children: [
                        const TextSpan(text: 'I have read and agree to the '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => _LegalScreen(title: 'Privacy Policy', content: kPrivacyPolicy),
                            )),
                            child: Text('Privacy Policy',
                                style: TextStyle(fontSize: 11, color: colorScheme.primary,
                                    fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => _LegalScreen(title: 'Terms of Service', content: kTermsOfService),
                            )),
                            child: Text('Terms of Service',
                                style: TextStyle(fontSize: 11, color: colorScheme.primary,
                                    fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                          ),
                        ),
                        const TextSpan(text: '. I consent to Sandalan collecting and processing my personal data as described.'),
                      ],
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

              // Hide sign-in link for guests — they must create an account, not sign into an existing one
              if (!_wasGuest)
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

              const SizedBox(height: 24),

              // Divider
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or continue with',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 16),

              // Google sign-up
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignUp,
                icon: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: const Text('G', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: Color(0xFF4285F4), height: 1,
                  )),
                ),
                label: const Text('Sign up with Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalScreen extends StatelessWidget {
  final String title;
  final String content;
  const _LegalScreen({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SelectableText(content, style: const TextStyle(fontSize: 13, height: 1.6)),
      ),
    );
  }
}
