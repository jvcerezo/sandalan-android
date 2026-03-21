import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/constants/legal.dart';
import '../../../core/services/data_export_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'settings_shared.dart';

class PrivacySection extends ConsumerStatefulWidget {
  final Widget back;
  const PrivacySection({super.key, required this.back});

  @override
  ConsumerState<PrivacySection> createState() => _PrivacySectionState();
}

class _PrivacySectionState extends ConsumerState<PrivacySection> {
  final _deleteCtl = TextEditingController();
  bool _exporting = false;

  @override
  void dispose() {
    _deleteCtl.dispose();
    super.dispose();
  }

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    final path = await DataExportService.exportData(ref, context);
    if (!mounted) return;
    setState(() => _exporting = false);
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Data exported to:\n$path', style: const TextStyle(fontSize: 12)),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Export failed. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ));
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
          color: AppColors.expense.withValues(alpha: 0.03),
          border: Border.all(color: AppColors.expense.withValues(alpha: 0.2)),
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
                color: AppColors.expense.withValues(alpha: 0.04),
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
              FilledButton(
                  onPressed: _deleteCtl.text == 'DELETE'
                      ? () async {
                          await ref.read(authRepositoryProvider).deleteAccount();
                          if (context.mounted) context.go('/login');
                        }
                      : null,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.expense,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 0)),
                  child: const Text('Delete My Account Permanently')),
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
