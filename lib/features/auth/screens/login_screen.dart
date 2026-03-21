import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../data/local/app_database.dart';
import '../../../core/utils/email_validator.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../../shared/widgets/tour_overlay.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;
  bool _wasGuest = false;

  @override
  void initState() {
    super.initState();
    _wasGuest = GuestModeService.isGuestSync();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Migrate guest data after successful authentication.
  Future<void> _migrateGuestDataIfNeeded() async {
    if (!_wasGuest) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await GuestModeService.migrateToAccount(userId);
    final syncService = SyncService(Supabase.instance.client, AppDatabase.instance);
    syncService.fullSync();
    syncService.startDailySync();
  }

  Future<void> _handleEmailSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    final emailError = EmailValidator.validate(email);
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithEmail(
        email: email,
        password: password,
      );
      await _migrateGuestDataIfNeeded();
      // Always pull fresh data from Supabase after login
      final syncService = SyncService(Supabase.instance.client, AppDatabase.instance);
      await syncService.fullSync();
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = _parseAuthError(e);
      });
    }
  }

  String _parseAuthError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid') || msg.contains('400')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('429') || msg.contains('rate')) {
      return 'Too many attempts. Please try again later.';
    }
    return 'Sign in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Center(child: BrandMark(size: 48)),
              const SizedBox(height: 32),

              const Text('Welcome back',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('Sign in to continue your financial journey',
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),

              // Quick login for previously authenticated users (offline with cached identity)
              Builder(builder: (context) {
                final session = Supabase.instance.client.auth.currentSession;
                final cachedUser = Supabase.instance.client.auth.currentUser;
                // Only show quick login if there's a cached user but NO active session
                // (means they were previously logged in but are now offline or session expired)
                if (cachedUser == null || session != null) return const SizedBox.shrink();

                final name = cachedUser.userMetadata?['full_name'] as String? ?? '';
                final email = cachedUser.email ?? '';
                final avatarUrl = cachedUser.userMetadata?['avatar_url'] as String?;

                return Column(children: [
                  GestureDetector(
                    onTap: () {
                      // User has cached identity — go straight to home (offline mode)
                      context.go('/home');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                        color: colorScheme.primary.withValues(alpha: 0.05),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                                      color: colorScheme.primary))
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.isNotEmpty ? name : 'Continue as',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            Text(email,
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                          ],
                        )),
                        Icon(LucideIcons.arrowRight, size: 18, color: colorScheme.primary),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or sign in with a different account',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),
                ]);
              }),

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
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleEmailSignIn(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit
              FilledButton(
                onPressed: _isLoading ? null : _handleEmailSignIn,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Sign In'),
              ),
              const SizedBox(height: 16),

              // Sign up link
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Don't have an account? ",
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                GestureDetector(
                  onTap: () => context.go('/signup'),
                  child: Text('Create one',
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
                  child: Text('or',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 16),

              // Guest mode
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        await GuestModeService.enableGuestMode();
                        await scheduleTour();
                        if (mounted) context.go('/home');
                      },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Column(
                  children: [
                    Text('Continue without an account',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text('Your data stays on this device',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
