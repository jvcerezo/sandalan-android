import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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

    final priorityColor = item.priority == 'critical' ? Colors.red
        : item.priority == 'important' ? Colors.orange : cs.onSurfaceVariant;
    final priorityLabel = item.priority == 'critical' ? 'MUST DO'
        : item.priority == 'important' ? 'SHOULD DO' : 'NICE TO HAVE';

    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            // ← Back
            GestureDetector(
              onTap: () => context.go('/guide/${widget.stageSlug}'),
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(LucideIcons.arrowLeft, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('Back to ${stage.title}', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                ]),
              ),
            ),

            // Status icon + Title
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 28, height: 28,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isDone ? stage.color.withValues(alpha: 0.1) : cs.surfaceContainerHighest,
                ),
                child: Icon(
                  _isDone ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  size: 16,
                  color: _isDone ? stage.color : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
              ),
            ]),
            const SizedBox(height: 10),

            // Priority badge
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(priorityLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: priorityColor, letterSpacing: 0.5)),
              ),
            ]),
            const SizedBox(height: 14),

            // Description
            Text(item.description, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.85), height: 1.6)),
            const SizedBox(height: 20),

            // ─── Why this matters ──────────────────────────────────
            if (item.why.isNotEmpty)
              _buildCard(cs, stage.color, children: [
                Text('Why this matters', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: stage.color)),
                const SizedBox(height: 8),
                Text(item.why, style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.6)),
              ]),

            // ─── What to Prepare (requirements) ───────────────────
            if (item.requirements.isNotEmpty)
              _buildCard(cs, null, children: [
                Row(children: [
                  Icon(LucideIcons.fileText, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  const Text('What to Prepare', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                ...item.requirements.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 22, height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text('${e.key + 1}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.value, style: TextStyle(fontSize: 13, color: cs.onSurface, height: 1.5))),
                  ]),
                )),
              ]),

            // ─── Step-by-Step Process ──────────────────────────────
            if (item.steps.isNotEmpty)
              _buildCard(cs, null, children: [
                Row(children: [
                  Icon(LucideIcons.listChecks, size: 16, color: stage.color),
                  const SizedBox(width: 8),
                  const Text('Step-by-Step Process', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                ...item.steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 22, height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: stage.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text('${e.key + 1}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: stage.color))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.value, style: TextStyle(fontSize: 13, color: cs.onSurface, height: 1.5))),
                  ]),
                )),
              ]),

            // ─── Fees & Processing Time ────────────────────────────
            if (item.fees != null || item.processingTime != null)
              Row(children: [
                if (item.fees != null)
                  Expanded(child: _buildInfoChip(cs, LucideIcons.coins, 'Fees', item.fees!)),
                if (item.fees != null && item.processingTime != null)
                  const SizedBox(width: 8),
                if (item.processingTime != null)
                  Expanded(child: _buildInfoChip(cs, LucideIcons.clock, 'Processing Time', item.processingTime!)),
              ]),
            if (item.fees != null || item.processingTime != null)
              const SizedBox(height: 16),

            // ─── Tips ──────────────────────────────────────────────
            if (item.tips.isNotEmpty)
              _buildCard(cs, null, children: [
                Row(children: [
                  Icon(LucideIcons.lightbulb, size: 16, color: Colors.amber.shade600),
                  const SizedBox(width: 8),
                  const Text('Tips', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                ...item.tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('•  ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
                    Expanded(child: Text(tip, style: TextStyle(fontSize: 13, color: cs.onSurface, height: 1.5))),
                  ]),
                )),
              ]),

            // ─── App Link ──────────────────────────────────────────
            if (item.appLink != null && item.appLinkLabel != null)
              GestureDetector(
                onTap: () => context.go(item.appLink!),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.appLinkLabel!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Track your progress in-app', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    ])),
                    Icon(LucideIcons.arrowRight, size: 16, color: cs.onSurfaceVariant),
                  ]),
                ),
              ),

            // ─── Official References ───────────────────────────────
            if (item.references.isNotEmpty)
              _buildCard(cs, null, children: [
                const Text('Official References', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...item.references.map((ref) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => launchUrl(Uri.parse(ref.url), mode: LaunchMode.externalApplication),
                    child: Row(children: [
                      Icon(LucideIcons.externalLink, size: 14, color: stage.color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(ref.label, style: TextStyle(fontSize: 13, color: stage.color, decoration: TextDecoration.underline))),
                    ]),
                  ),
                )),
              ]),
          ],
        ),
      ),

      // ─── Bottom bar ──────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.08))),
        ),
        child: SafeArea(
          top: false,
          child: Row(children: [
            // Skip
            TextButton.icon(
              onPressed: _isSkipped ? null : _markSkipped,
              icon: Icon(LucideIcons.skipForward, size: 14, color: _isSkipped ? cs.onSurfaceVariant.withValues(alpha: 0.4) : cs.onSurfaceVariant),
              label: Text('Skip', style: TextStyle(color: _isSkipped ? cs.onSurfaceVariant.withValues(alpha: 0.4) : cs.onSurfaceVariant)),
            ),
            const SizedBox(width: 12),
            // Mark as Done
            Expanded(
              child: FilledButton.icon(
                onPressed: _isDone ? () async {
                  final prefs = await SharedPreferences.getInstance();
                  final done = prefs.getStringList('checklist_done') ?? [];
                  done.remove(widget.itemId);
                  await prefs.setStringList('checklist_done', done);
                  setState(() => _isDone = false);
                } : _markDone,
                icon: Icon(_isDone ? LucideIcons.undo2 : LucideIcons.circle, size: 16),
                label: Text(_isDone ? 'Undo' : 'Mark as Done'),
                style: FilledButton.styleFrom(
                  backgroundColor: _isDone ? cs.surfaceContainerHighest : stage.color,
                  foregroundColor: _isDone ? cs.onSurfaceVariant : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildCard(ColorScheme cs, Color? accentColor, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor != null ? accentColor.withValues(alpha: 0.05) : null,
        border: Border.all(color: accentColor?.withValues(alpha: 0.2) ?? cs.outline.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildInfoChip(ColorScheme cs, IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 12, color: cs.onSurface, height: 1.4)),
      ]),
    );
  }
}
