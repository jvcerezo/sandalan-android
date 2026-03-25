import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/bill_split.dart';
import '../../../core/services/guest_mode_service.dart';
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
                  const SizedBox(height: 20),

                  // Active splits
                  if (_activeSplits.isNotEmpty) ...[
                    _SectionLabel('ACTIVE SPLITS (${_activeSplits.length})'),
                    const SizedBox(height: 8),
                    for (final split in _activeSplits)
                      _SplitCard(
                        split: split,
                        onNudge: () => Share.share(split.nudgeText()),
                        onTogglePaid: (i) => _togglePaid(split, i),
                        onDelete: () => _deleteSplit(split),
                      ),
                  ],

                  if (_activeSplits.isEmpty && _settledSplits.isEmpty) ...[
                    const SizedBox(height: 60),
                    Center(child: Column(children: [
                      Icon(LucideIcons.users, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
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
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ));
}

class _SplitCard extends StatelessWidget {
  final BillSplit split;
  final VoidCallback? onNudge;
  final void Function(int index) onTogglePaid;
  final VoidCallback onDelete;

  const _SplitCard({
    required this.split,
    required this.onNudge,
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
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Owed \u20b1${owed.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning)),
              ),
            if (split.isSettled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
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
