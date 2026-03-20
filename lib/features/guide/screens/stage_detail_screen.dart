import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/guide/guide_data.dart';
import '../../../shared/widgets/animated_counter.dart';

class StageDetailScreen extends StatefulWidget {
  final String stageSlug;
  const StageDetailScreen({super.key, required this.stageSlug});

  @override
  State<StageDetailScreen> createState() => _StageDetailScreenState();
}

class _StageDetailScreenState extends State<StageDetailScreen> {
  final Set<String> _completedItems = {};
  final Set<String> _skippedItems = {};
  final Set<String> _readGuides = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _completedItems.addAll(prefs.getStringList('checklist_done') ?? []);
      _skippedItems.addAll(prefs.getStringList('checklist_skipped') ?? []);
      _readGuides.addAll(prefs.getStringList('guides_read') ?? []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stage = kLifeStages.firstWhere((s) => s.slug == widget.stageSlug);
    final completedChecklist = stage.checklist.where((c) => _completedItems.contains(c.id)).length;
    final readGuideCount = stage.guides.where((g) => _readGuides.contains(g.slug)).length;
    final totalProgress = stage.guides.length + stage.checklist.length;
    final completedTotal = readGuideCount + completedChecklist;
    final progressPct = totalProgress > 0 ? (completedTotal / totalProgress * 100).round() : 0;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ← Back to Journey
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: GestureDetector(
            onTap: () => context.go('/guide'),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.arrowLeft, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Back to Journey', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ]),
          ),
        ),
        const SizedBox(height: 8),

        // ─── Banner with photo + gradient overlay ────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 200,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(fit: StackFit.expand, children: [
            // Photo
            Image.asset(
              stage.coverImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [stage.color.withValues(alpha: 0.3), stage.color.withValues(alpha: 0.05)],
                  ),
                ),
                child: Center(child: Icon(stage.icon, size: 64, color: stage.color.withValues(alpha: 0.3))),
              ),
            ),
            // Dark gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Content
            Positioned(
              left: 16, bottom: 16, right: 16,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(stage.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(stage.subtitle, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(stage.description, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.8), height: 1.5)),
        ),
        const SizedBox(height: 16),

        // ─── Progress bar ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Text('Progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const Spacer(),
            Text('$progressPct%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: stage.color)),
          ]),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedProgressBar(value: completedTotal / (totalProgress > 0 ? totalProgress : 1), minHeight: 6, color: stage.color),
        ),
        const SizedBox(height: 24),

        // ─── Guides section ─────────────────────────────────────
        if (stage.guides.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('GUIDES (${stage.guides.length})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  letterSpacing: 0.8, color: cs.onSurfaceVariant)),
            ]),
          ),
          const SizedBox(height: 10),
          ...stage.guides.map((guide) {
            final isRead = _readGuides.contains(guide.slug);
            return _GuideItem(
              guide: guide,
              stageSlug: stage.slug,
              color: stage.color,
              isRead: isRead,
              onReturn: _loadProgress,
            );
          }),
          const SizedBox(height: 24),
        ],

        // ─── Checklist section ──────────────────────────────────
        if (stage.checklist.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('CHECKLIST (${completedChecklist}/${stage.checklist.length})',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 0.8, color: cs.onSurfaceVariant)),
            ]),
          ),
          const SizedBox(height: 10),
          ...stage.checklist.map((item) {
            final isDone = _completedItems.contains(item.id);
            final isSkipped = _skippedItems.contains(item.id);
            return _ChecklistRow(
              item: item,
              isDone: isDone,
              isSkipped: isSkipped,
              color: stage.color,
              onTap: () async {
                await context.push('/guide/${widget.stageSlug}/checklist/${item.id}');
                _loadProgress();
              },
            );
          }),
          const SizedBox(height: 80),
        ],
      ],
    );
  }
}

// ─── Guide Item ───────────────────────────────────────────────────────────────

class _GuideItem extends StatelessWidget {
  final Guide guide;
  final String stageSlug;
  final Color color;
  final bool isRead;
  final VoidCallback onReturn;

  const _GuideItem({
    required this.guide,
    required this.stageSlug,
    required this.color,
    required this.isRead,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        context.go('/guide/$stageSlug/${guide.slug}');
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isRead ? color.withValues(alpha: 0.03) : null,
          border: Border.all(color: isRead ? color.withValues(alpha: 0.15) : cs.outline.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isRead ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isRead ? LucideIcons.checkCircle2 : LucideIcons.bookOpen,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(guide.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isRead ? cs.onSurface.withValues(alpha: 0.6) : cs.onSurface,
                  decoration: isRead ? TextDecoration.lineThrough : null,
                )),
            const SizedBox(height: 2),
            Text(guide.description,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, height: 1.3),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.clock, size: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(width: 3),
              Text('${guide.readMinutes}m', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
            ]),
            const SizedBox(height: 4),
            Icon(LucideIcons.chevronRight, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          ]),
        ]),
      ),
    );
  }
}

// ─── Checklist Row ────────────────────────────────────────────────────────────

class _ChecklistRow extends StatelessWidget {
  final ChecklistItem item;
  final bool isDone;
  final bool isSkipped;
  final Color color;
  final VoidCallback onTap;

  const _ChecklistRow({
    required this.item,
    required this.isDone,
    required this.isSkipped,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final priorityColor = item.priority == 'critical' ? Colors.red
        : item.priority == 'important' ? Colors.orange : cs.onSurfaceVariant;
    final priorityLabel = item.priority == 'critical' ? 'MUST DO'
        : item.priority == 'important' ? 'SHOULD DO' : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDone ? color.withValues(alpha: 0.04) : null,
          border: Border.all(color: isDone ? color.withValues(alpha: 0.2) : cs.outline.withValues(alpha: 0.10)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          // Circle checkbox
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: isDone ? color : Colors.transparent,
              border: Border.all(color: isDone ? color : cs.outline.withValues(alpha: 0.25), width: 1.5),
              shape: BoxShape.circle,
            ),
            child: isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? cs.onSurfaceVariant : cs.onSurface,
                )),
            const SizedBox(height: 2),
            Text(item.description,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, height: 1.3),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 6),
          if (priorityLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(priorityLabel, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: priorityColor, letterSpacing: 0.3)),
            ),
          Icon(LucideIcons.chevronRight, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
        ]),
      ),
    );
  }
}
