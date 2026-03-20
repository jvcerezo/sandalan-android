import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/guide/guide_data.dart';

class ChecklistDetailScreen extends StatefulWidget {
  final String stageSlug;
  final String itemId;
  const ChecklistDetailScreen({super.key, required this.stageSlug, required this.itemId});

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends State<ChecklistDetailScreen> {
  bool _isDone = false;
  bool _isSkipped = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDone = (prefs.getStringList('checklist_done') ?? []).contains(widget.itemId);
      _isSkipped = (prefs.getStringList('checklist_skipped') ?? []).contains(widget.itemId);
    });
  }

  Future<void> _markDone() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getStringList('checklist_done') ?? [];
    final skipped = prefs.getStringList('checklist_skipped') ?? [];
    done.add(widget.itemId);
    skipped.remove(widget.itemId);
    await prefs.setStringList('checklist_done', done);
    await prefs.setStringList('checklist_skipped', skipped);
    setState(() { _isDone = true; _isSkipped = false; });
  }

  Future<void> _markSkipped() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getStringList('checklist_done') ?? [];
    final skipped = prefs.getStringList('checklist_skipped') ?? [];
    skipped.add(widget.itemId);
    done.remove(widget.itemId);
    await prefs.setStringList('checklist_done', done);
    await prefs.setStringList('checklist_skipped', skipped);
    setState(() { _isDone = false; _isSkipped = true; });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stage = kLifeStages.firstWhere((s) => s.slug == widget.stageSlug);
    final item = stage.checklist.firstWhere((c) => c.id == widget.itemId);

    final priorityColor = item.priority == 'high' ? Colors.red
        : item.priority == 'medium' ? Colors.orange : cs.onSurfaceVariant;
    final priorityLabel = item.priority == 'high' ? 'Must Do'
        : item.priority == 'medium' ? 'Important' : 'Good to Have';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        // ← Back
        GestureDetector(
          onTap: () => context.go('/guide/${widget.stageSlug}'),
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.arrowLeft, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(stage.title, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ]),
          ),
        ),

        // Status badge
        if (_isDone || _isSkipped)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isDone ? stage.color.withValues(alpha: 0.1) : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_isDone ? LucideIcons.checkCircle2 : LucideIcons.skipForward,
                      size: 14, color: _isDone ? stage.color : cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(_isDone ? 'Completed' : 'Skipped',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: _isDone ? stage.color : cs.onSurfaceVariant)),
                ]),
              ),
            ]),
          ),

        // Title + priority
        Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(priorityLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: priorityColor)),
          ),
          if (item.fee != null) ...[
            const SizedBox(width: 8),
            Row(children: [
              Icon(LucideIcons.coins, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(item.fee!, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ]),
          ],
          if (item.processingTime != null) ...[
            const SizedBox(width: 8),
            Row(children: [
              Icon(LucideIcons.clock, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(item.processingTime!, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ]),
          ],
        ]),
        const SizedBox(height: 14),

        // Description
        Text(item.description, style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.5)),
        const SizedBox(height: 20),

        // Steps
        if (item.steps.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(LucideIcons.listChecks, size: 16, color: stage.color),
                const SizedBox(width: 8),
                const Text('How to do it', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 12),
              ...item.steps.asMap().entries.map((entry) {
                final i = entry.key;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 22, height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: stage.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text('${i + 1}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: stage.color))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(step, style: TextStyle(fontSize: 13, color: cs.onSurface, height: 1.4))),
                  ]),
                );
              }),
            ]),
          ),
          const SizedBox(height: 20),
        ],

        // Action buttons
        if (!_isDone)
          FilledButton.icon(
            onPressed: _markDone,
            icon: const Icon(LucideIcons.checkCircle2, size: 16),
            label: const Text('Mark as Done'),
            style: FilledButton.styleFrom(
              backgroundColor: stage.color,
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        if (!_isDone) const SizedBox(height: 8),
        if (!_isSkipped)
          OutlinedButton.icon(
            onPressed: _markSkipped,
            icon: Icon(LucideIcons.skipForward, size: 14, color: cs.onSurfaceVariant),
            label: Text('Skip for Now', style: TextStyle(color: cs.onSurfaceVariant)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

        if (_isDone) ...[
          OutlinedButton.icon(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final done = prefs.getStringList('checklist_done') ?? [];
              done.remove(widget.itemId);
              await prefs.setStringList('checklist_done', done);
              setState(() => _isDone = false);
            },
            icon: Icon(LucideIcons.undo2, size: 14, color: cs.onSurfaceVariant),
            label: Text('Undo Completion', style: TextStyle(color: cs.onSurfaceVariant)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ],
    );
  }
}
