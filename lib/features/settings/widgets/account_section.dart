import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../data/local/app_database.dart';
import '../../../shared/widgets/tour_overlay.dart';
import '../../auth/providers/auth_provider.dart';
import 'settings_shared.dart';

class AccountSection extends ConsumerStatefulWidget {
  final Widget back;
  const AccountSection({super.key, required this.back});

  @override
  ConsumerState<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<AccountSection> {
  Map<String, int> _counts = {'pending': 0, 'failed': 0, 'synced': 0};
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final counts = await AppDatabase.instance.getSyncStatusCounts(userId);
    if (mounted) setState(() => _counts = counts);
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      final client = Supabase.instance.client;
      await SyncService(client, AppDatabase.instance).fullSync(forceFullPull: true);
    } finally {
      await _loadCounts();
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _clearQueue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear failed items?'),
        content: const Text(
            'This will permanently delete all failed offline changes. '
            'They will not be synced to the server.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed != true) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await AppDatabase.instance.clearFailedRows(userId);
    await _loadCounts();
  }

  String _statusText() {
    final pending = _counts['pending'] ?? 0;
    final failed = _counts['failed'] ?? 0;
    final total = pending + failed;
    if (total == 0) return 'All changes synced.';
    final parts = <String>[];
    if (pending > 0) parts.add('$pending pending');
    if (failed > 0) parts.add('$failed failed');
    return '${parts.join(', ')} ${total == 1 ? 'change' : 'changes'} queued.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isGuest = GuestModeService.isGuestSync();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), children: [
      widget.back,

      // Guest banner
      if (isGuest) ...[
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.08),
            border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(LucideIcons.userPlus, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text('You\'re in Guest Mode',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: cs.primary)),
            ]),
            const SizedBox(height: 6),
            Text(
                'Your data is stored only on this device. Create an account to back up your data and sync across devices.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/signup'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: const Text('Create Account'),
            ),
          ]),
        ),
      ],

      // Offline Outbox (hide for guests)
      if (!isGuest) ...[
        SettingsCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(LucideIcons.wifi, size: 16, color: cs.onSurface),
            const SizedBox(width: 8),
            const Text('Offline Outbox',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          Text(
              'Review queued offline mutations, retry failed items, or clear stale entries.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            _StatusChip('Pending: ${_counts['pending'] ?? 0}'),
            _StatusChip('Failed: ${_counts['failed'] ?? 0}'),
            _StatusChip('Synced: ${_counts['synced'] ?? 0}'),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            FilledButton.icon(
                onPressed: _isSyncing ? null : _syncNow,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(LucideIcons.refreshCw, size: 14),
                label: Text(_isSyncing ? 'Syncing...' : 'Sync now'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8))),
            const SizedBox(width: 8),
            OutlinedButton.icon(
                onPressed: (_counts['failed'] ?? 0) == 0 ? null : _clearQueue,
                icon: const Icon(LucideIcons.trash2, size: 14),
                label: const Text('Clear queue'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8))),
          ]),
          const SizedBox(height: 6),
          Text(_statusText(),
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ])),
        const SizedBox(height: 12),

        // Conflict Center
        SettingsCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, size: 16, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('Conflict Center',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          Text(
              'Review sync conflicts and retry or dismiss items after investigation.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          Row(children: [
            _StatusChip('Total conflicts: 0'),
            const SizedBox(width: 8),
            OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.trash2, size: 12),
                label: const Text('Clear conflicts'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    textStyle: const TextStyle(fontSize: 11))),
          ]),
          const SizedBox(height: 6),
          Text('No conflicts detected.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ])),
        const SizedBox(height: 12),
      ],

      // Account actions
      SettingsCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('Manage your account settings',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: () {
              TourController.of(context).start();
            },
            icon: const Icon(LucideIcons.compass, size: 16),
            label: const Text('Take a Tour'),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0))),
        if (!isGuest) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
              onPressed: () async {
                // Stop sync before clearing data
                SyncService(Supabase.instance.client, AppDatabase.instance).stopSync();
                try {
                  await ref.read(authRepositoryProvider).signOut();
                } catch (_) {}
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(LucideIcons.logOut, size: 16, color: AppColors.expense),
              label:
                  const Text('Sign Out', style: TextStyle(color: AppColors.expense)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.expense),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 0))),
        ],
      ])),
    ]);
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)));
}
