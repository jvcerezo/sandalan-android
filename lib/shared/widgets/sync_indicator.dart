import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/sync_status_notifier.dart';
import '../../core/services/sync_service.dart';
import '../../data/local/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Small sync status indicator for the app header bar.
///
/// - Spinning icon while syncing
/// - Green check (auto-fades) after success
/// - Red warning icon if failed (tap to retry)
/// - Nothing when idle
class SyncIndicator extends ConsumerStatefulWidget {
  const SyncIndicator({super.key});

  @override
  ConsumerState<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends ConsumerState<SyncIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  Timer? _hideTimer;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onRetry() {
    final syncService = SyncService(
      Supabase.instance.client,
      AppDatabase.instance,
      syncStatus: ref.read(syncStatusProvider.notifier),
    );
    syncService.fullSync(forceFullPull: true);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(syncStatusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Manage spin animation
    if (status.state == SyncState.syncing) {
      _spinController.repeat();
      _showSuccess = false;
      _hideTimer?.cancel();
    } else {
      _spinController.stop();
    }

    // Auto-show then hide the success check
    if (status.state == SyncState.synced && !_showSuccess) {
      _showSuccess = true;
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          ref.read(syncStatusProvider.notifier).markIdle();
          setState(() => _showSuccess = false);
        }
      });
    }

    switch (status.state) {
      case SyncState.idle:
        return const SizedBox.shrink();

      case SyncState.syncing:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: RotationTransition(
            turns: _spinController,
            child: Icon(
              LucideIcons.refreshCw,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        );

      case SyncState.synced:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            LucideIcons.checkCircle,
            size: 18,
            color: Colors.green.shade600,
          ),
        );

      case SyncState.failed:
        return GestureDetector(
          onTap: _onRetry,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Tooltip(
              message: status.lastError ?? 'Sync failed — tap to retry',
              child: Icon(
                LucideIcons.alertTriangle,
                size: 18,
                color: colorScheme.error,
              ),
            ),
          ),
        );
    }
  }
}
