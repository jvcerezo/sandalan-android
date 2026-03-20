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
    });
  }

  Future<void> _toggleItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_completedItems.contains(id)) {
        _completedItems.remove(id);
      } else {
        _completedItems.add(id);
        _skippedItems.remove(id);
      }
    });
    await prefs.setStringList('checklist_done', _completedItems.toList());
    await prefs.setStringList('checklist_skipped', _skippedItems.toList());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stage = kLifeStages.firstWhere((s) => s.slug == widget.stageSlug);
    final completedCount = stage.checklist.where((c) => _completedItems.contains(c.id)).length;
    final totalItems = stage.guides.length + stage.checklist.length;
    final progress = totalItems > 0 ? completedCount / stage.checklist.length : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        // ← Guide
        GestureDetector(
          onTap: () => context.go('/guide'),
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.arrowLeft, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Guide', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ]),
          ),
        ),

        // Stage banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: stage.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: stage.color, borderRadius: BorderRadius.circular(14)),
              child: Icon(stage.icon, size: 28, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(stage.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('${stage.subtitle} · Ages ${stage.ageRange}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              Text(stage.description,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, height: 1.3)),
            ])),
          ]),
        ),
        const SizedBox(height: 12),

        // Progress
        if (stage.checklist.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$completedCount of ${stage.checklist.length} completed',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ])),
              SizedBox(width: 100, child: AnimatedProgressBar(
                  value: progress.clamp(0, 1), minHeight: 6, color: stage.color)),
            ]),
          ),
        const SizedBox(height: 20),

        // Guides section
        if (stage.guides.isNotEmpty) ...[
          Text('GUIDES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.8, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          ...stage.guides.map((guide) => _GuideItem(guide: guide, stageSlug: stage.slug, color: stage.color)),
          const SizedBox(height: 20),
        ],

        // Checklist section
        if (stage.checklist.isNotEmpty) ...[
          Row(children: [
            Text('CHECKLIST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 0.8, color: cs.onSurfaceVariant)),
            const Spacer(),
            Text('$completedCount/${stage.checklist.length}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: stage.color)),
          ]),
          const SizedBox(height: 8),
          ...stage.checklist.map((item) => _ChecklistRow(
            item: item,
            isDone: _completedItems.contains(item.id),
            isSkipped: _skippedItems.contains(item.id),
            color: stage.color,
            onTap: () async {
              await context.push('/guide/${widget.stageSlug}/checklist/${item.id}');
              _loadProgress(); // Reload after returning
            },
          )),
        ],
      ],
    );
  }
}

class _GuideItem extends StatelessWidget {
  final Guide guide;
  final String stageSlug;
  final Color color;
  const _GuideItem({required this.guide, required this.stageSlug, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.go('/guide/$stageSlug/${guide.slug}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(LucideIcons.bookOpen, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(guide.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${guide.readMinutes} min read', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ])),
          Icon(LucideIcons.chevronRight, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
        ]),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final ChecklistItem item;
  final bool isDone;
  final bool isSkipped;
  final Color color;
  final VoidCallback onTap;
  const _ChecklistRow({required this.item, required this.isDone, required this.isSkipped,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDone ? color.withValues(alpha: 0.04) : null,
          border: Border.all(color: isDone ? color.withValues(alpha: 0.2) : cs.outline.withValues(alpha: 0.10)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Container(
            width: 22, height: 22,
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? cs.onSurfaceVariant : cs.onSurface)),
            if (item.fees != null || item.processingTime != null)
              Text([
                if (item.fees != null) item.fees!,
                if (item.processingTime != null) item.processingTime!,
              ].join(' · '), style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
          ])),
          if (item.priority == 'critical')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4)),
              child: const Text('!', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red)),
            ),
          Icon(LucideIcons.chevronRight, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
        ]),
      ),
    );
  }
}
