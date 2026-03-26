import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/constants/legal.dart';
import '../../../core/services/app_lock_service.dart';
import '../../../core/services/data_export_service.dart';
import '../../../core/services/csv_export_service.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../data/local/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import 'settings_shared.dart';
import '../../../shared/utils/snackbar_helper.dart';

class PrivacySection extends ConsumerStatefulWidget {
  final Widget back;
  const PrivacySection({super.key, required this.back});

  @override
  ConsumerState<PrivacySection> createState() => _PrivacySectionState();
}

class _PrivacySectionState extends ConsumerState<PrivacySection> {
  final _deleteCtl = TextEditingController();
  bool _exporting = false;
  bool _exportingCsv = false;

  // App lock state
  bool _appLockEnabled = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _lockLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLockPrefs();
  }

  @override
  void dispose() {
    _deleteCtl.dispose();
    super.dispose();
  }

  Future<void> _loadLockPrefs() async {
    final service = AppLockService.instance;
    final enabled = await service.isEnabled();
    final bioEnabled = await service.isBiometricEnabled();
    final bioAvailable = await service.isBiometricAvailable();
    if (mounted) {
      setState(() {
        _appLockEnabled = enabled;
        _biometricEnabled = bioEnabled;
        _biometricAvailable = bioAvailable;
        _lockLoaded = true;
      });
    }
  }

  Future<void> _onAppLockChanged(bool value) async {
    if (value) {
      // Prompt to set a PIN
      final pin = await _showSetPinDialog();
      if (pin == null) return; // cancelled
      await AppLockService.instance.setPin(pin);
      await AppLockService.instance.setEnabled(true);
      setState(() => _appLockEnabled = true);
    } else {
      await AppLockService.instance.setEnabled(false);
      setState(() {
        _appLockEnabled = false;
        _biometricEnabled = false;
      });
    }
  }

  Future<void> _onBiometricChanged(bool value) async {
    await AppLockService.instance.setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }

  Future<String?> _showSetPinDialog() async {
    String pin = '';
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            title: const Text('Set PIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Enter a 4-digit PIN to lock your app',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: '4-digit PIN',
                  counterText: '',
                ),
                onChanged: (v) => setDialogState(() => pin = v),
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: pin.length == 4 ? () => Navigator.of(ctx).pop(pin) : null,
                child: const Text('Set PIN'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    final path = await DataExportService.exportData(ref, context);
    if (!mounted) return;
    setState(() => _exporting = false);
    if (path != null) {
      showSuccessSnackBar(context, 'Data exported to:\n$path');
    } else {
      showAppSnackBar(context, 'Export failed. Please try again.', isError: true);
    }
  }

  String get _csvUserId {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  Future<void> _exportCsv() async {
    setState(() => _exportingCsv = true);
    final path = await CsvExportService.exportTransactions(
      db: AppDatabase.instance,
      userId: _csvUserId,
    );
    if (!mounted) return;
    setState(() => _exportingCsv = false);
    if (path != null) {
      showSuccessSnackBar(context, 'CSV exported to:\n$path');
    } else {
      showAppSnackBar(context, 'CSV export failed. Please try again.', isError: true);
    }
  }

  void _openLegalDocument(String title, String content) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _LegalDocumentScreen(title: title, content: content),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      widget.back,
      // App Lock section
      if (_lockLoaded)
        SettingsCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(LucideIcons.lock, size: 18, color: cs.onSurface),
            const SizedBox(width: 8),
            const Text('App Lock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          Text('Protect your app with a PIN or biometrics',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          SettingsToggleRow(
              title: 'App Lock',
              sub: 'Require PIN to open the app',
              value: _appLockEnabled,
              onChanged: _onAppLockChanged),
          if (_appLockEnabled && _biometricAvailable)
            SettingsToggleRow(
                title: 'Use Biometrics',
                sub: 'Unlock with fingerprint or face',
                value: _biometricEnabled,
                onChanged: _onBiometricChanged),
        ])),
      const SizedBox(height: 12),
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Privacy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Your data rights and export options under the Data Privacy Act of 2012',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        const Text('Export Your Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
            'Download a full copy of all your data in JSON format \u2014 transactions, accounts, budgets, goals, debts, bills, insurance, contributions, and tax records.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
            onPressed: _exporting ? null : _exportData,
            icon: _exporting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.download, size: 14),
            label: Text(_exporting ? 'Exporting...' : 'Download My Data')),
        const SizedBox(height: 8),
        OutlinedButton.icon(
            onPressed: _exportingCsv ? null : _exportCsv,
            icon: _exportingCsv
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.fileText, size: 14),
            label: Text(_exportingCsv ? 'Exporting...' : 'Export as CSV')),
        const SizedBox(height: 16),
        const Text('Legal Documents',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        _LegalLink(
            icon: LucideIcons.fileText,
            label: 'Privacy Policy',
            onTap: () => _openLegalDocument('Privacy Policy', kPrivacyPolicy)),
        _LegalLink(
            icon: LucideIcons.fileText,
            label: 'Terms of Service',
            onTap: () => _openLegalDocument('Terms of Service', kTermsOfService)),
        const SizedBox(height: 8),
        Text(
            'For privacy-related concerns, email privacy@sandalan.com. We will respond within 15 business days.',
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
      ])),
      const SizedBox(height: 16),
      // Danger Zone
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.expense.withOpacity(0.03),
          border: Border.all(color: AppColors.expense.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, size: 16, color: AppColors.expense),
            const SizedBox(width: 6),
            const Text('Danger Zone',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.expense)),
          ]),
          Text('Permanent and irreversible actions',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.expense.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Delete Account',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.expense)),
              const SizedBox(height: 4),
              Text(
                  'Permanently deletes your account and all associated data \u2014 transactions, accounts, goals, budgets, debts, and contributions. This cannot be undone.',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              const Text('Type DELETE to confirm',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextField(
                  controller: _deleteCtl,
                  decoration: const InputDecoration(isDense: true, hintText: 'DELETE'),
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 8),
              StatefulBuilder(builder: (context, setButtonState) {
                bool deleting = false;
                return FilledButton(
                  onPressed: _deleteCtl.text == 'DELETE' && !deleting
                      ? () async {
                          setButtonState(() => deleting = true);
                          try {
                            await ref.read(authRepositoryProvider).deleteAccount();
                            if (context.mounted) context.go('/login');
                          } catch (e) {
                            setButtonState(() => deleting = false);
                            showAppSnackBar(context, '$e', isError: true);
                          }
                        }
                      : null,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.expense,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 0)),
                  child: deleting
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Delete My Account Permanently'));
              }),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

class _LegalLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LegalLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(children: [
            Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500))),
            Icon(LucideIcons.chevronRight,
                size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ])));
}

class _LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String content;
  const _LegalDocumentScreen({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SelectableText(content,
            style: TextStyle(fontSize: 13, height: 1.6, color: cs.onSurface)),
      ),
    );
  }
}
