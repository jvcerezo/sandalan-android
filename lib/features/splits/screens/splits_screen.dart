import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/bill_split.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../shared/utils/snackbar_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/new_split_dialog.dart';

class SplitsScreen extends StatefulWidget {
  const SplitsScreen({super.key});

  @override
  State<SplitsScreen> createState() => _SplitsScreenState();
}

class _SplitsScreenState extends State<SplitsScreen> {
  List<BillSplit> _activeSplits = [];
  List<BillSplit> _settledSplits = [];
  bool _loading = true;

  String get _userId {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) return user.id;
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  @override
  void initState() {
    super.initState();
    _loadSplits();
  }

  Future<void> _loadSplits() async {
    try {
      final db = AppDatabase.instance;
      final rows = await db.getBillSplits(_userId);
      final splits = rows.map((r) => BillSplit.fromMap(r)).toList();
      if (mounted) {
        setState(() {
          _activeSplits = splits.where((s) => !s.isSettled).toList();
          _settledSplits = splits.where((s) => s.isSettled).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePaid(BillSplit split, int participantIndex) async {
    final p = split.participants[participantIndex];
    final updated = List<SplitParticipant>.from(split.participants);
    updated[participantIndex] = p.copyWith(isPaid: !p.isPaid);
    final newSplit = split.copyWith(
      participants: updated,
      isSettled: updated.every((p) => p.isPaid || p.name == 'You'),
    );
    await AppDatabase.instance.upsertBillSplit(newSplit.toMap());
    await _loadSplits();
  }

  Widget _buildSummaryCard(ColorScheme cs) {
    final totalOwed = _activeSplits.fold<double>(0, (sum, s) => sum + s.amountOwed);
    final totalPending = _activeSplits.where((s) => s.amountOwed > 0).length;

    if (totalOwed <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            cs.primary.withOpacity(0.08),
            cs.primary.withOpacity(0.03),
          ]),
          border: Border.all(color: cs.primary.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.banknote, size: 22, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('You\'re owed', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            Text(formatCurrency(totalOwed),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.primary)),
          ])),
          Column(children: [
            Text('$totalPending', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
            Text('pending', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ]),
        ]),
      ),
    );
  }

  Future<void> _scheduleReminder(BillSplit split) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final target = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);
    await NotificationService.instance.scheduleNotification(
      id: split.id.hashCode + 50000,
      title: 'Split Bill Reminder',
      body: '${split.description}: ${formatCurrency(split.amountOwed)} still pending',
      scheduledDate: target,
    );
    if (mounted) showSuccessSnackBar(context, 'Reminder set for tomorrow 10 AM');
  }

  Future<void> _deleteSplit(BillSplit split) async {
    await AppDatabase.instance.deleteBillSplit(split.id);
    await _loadSplits();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: RefreshIndicator(
              onRefresh: _loadSplits,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  const Text('Split Bills', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(_activeSplits.isEmpty && _settledSplits.isEmpty
                      ? 'Split expenses with friends'
                      : '${_activeSplits.length} active · ${_settledSplits.length} settled',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 16),

                  // Summary card
                  if (_activeSplits.isNotEmpty)
                    _buildSummaryCard(colorScheme),

                  // Active splits
                  if (_activeSplits.isNotEmpty) ...[
                    _SectionLabel('ACTIVE SPLITS (${_activeSplits.length})'),
                    const SizedBox(height: 8),
                    for (final split in _activeSplits)
                      _SplitCard(
                        split: split,
                        onNudge: () => Share.share(split.nudgeText()),
                        onReminder: split.amountOwed > 0 ? () => _scheduleReminder(split) : null,
                        onTogglePaid: (i) => _togglePaid(split, i),
                        onDelete: () => _deleteSplit(split),
                      ),
                  ],

                  if (_activeSplits.isEmpty && _settledSplits.isEmpty) ...[
                    const SizedBox(height: 60),
                    Center(child: Column(children: [
                      Icon(LucideIcons.users, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text('No splits yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('Tap + to split a bill with friends', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                    ])),
                  ],

                  // Settled splits
                  if (_settledSplits.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionLabel('HISTORY (${_settledSplits.length})'),
                    const SizedBox(height: 8),
                    for (final split in _settledSplits)
                      _SplitCard(
                        split: split,
                        onNudge: null,
                        onTogglePaid: (i) => _togglePaid(split, i),
                        onDelete: () => _deleteSplit(split),
                      ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showNewSplitDialog(context, _userId);
          if (result != null) {
            await AppDatabase.instance.upsertBillSplit(result.toMap());
            await _loadSplits();
          }
        },
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
      ));
}

class _SplitCard extends StatelessWidget {
  final BillSplit split;
  final VoidCallback? onNudge;
  final VoidCallback? onReminder;
  final void Function(int index) onTogglePaid;
  final VoidCallback onDelete;

  const _SplitCard({
    required this.split,
    required this.onNudge,
    this.onReminder,
    required this.onTogglePaid,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final owed = split.amountOwed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(split.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                '\u20b1${split.totalAmount.toStringAsFixed(0)} · ${split.participants.length} people · ${split.paidCount} paid',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ])),
            if (owed > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Owed \u20b1${owed.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning)),
              ),
            if (split.isSettled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Settled',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
              ),
          ]),
        ),

        // Participants
        for (var i = 0; i < split.participants.length; i++)
          InkWell(
            onTap: () => onTogglePaid(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(children: [
                Icon(
                  split.participants[i].isPaid || split.participants[i].name == 'You'
                      ? LucideIcons.checkCircle2
                      : LucideIcons.circle,
                  size: 16,
                  color: split.participants[i].isPaid || split.participants[i].name == 'You'
                      ? AppColors.success
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(split.participants[i].name,
                    style: TextStyle(fontSize: 13,
                        decoration: split.participants[i].isPaid ? TextDecoration.lineThrough : null))),
                Text('\u20b1${split.participants[i].share.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
              ]),
            ),
          ),

        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Row(children: [
            if (onNudge != null)
              TextButton.icon(
                onPressed: onNudge,
                icon: const Icon(LucideIcons.send, size: 14),
                label: const Text('Nudge', style: TextStyle(fontSize: 12)),
              ),
            if (onReminder != null)
              TextButton.icon(
                onPressed: onReminder,
                icon: const Icon(LucideIcons.bell, size: 14),
                label: const Text('Remind', style: TextStyle(fontSize: 12)),
              ),
            const Spacer(),
            IconButton(
              icon: Icon(LucideIcons.trash2, size: 16, color: colorScheme.onSurfaceVariant),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete split?', style: TextStyle(fontSize: 16)),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () { Navigator.of(ctx).pop(); onDelete(); },
                        style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ]),
        ),
      ]),
    );
  }
}
