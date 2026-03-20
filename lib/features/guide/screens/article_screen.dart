import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/guide/guide_data.dart';

class ArticleScreen extends StatefulWidget {
  final String stageSlug;
  final String guideSlug;
  const ArticleScreen({super.key, required this.stageSlug, required this.guideSlug});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  bool _isRead = false;
  double _scrollProgress = 0;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadReadStatus();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    setState(() => _scrollProgress = (_scrollController.offset / max).clamp(0, 1));
  }

  Future<void> _loadReadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final readList = prefs.getStringList('guides_read') ?? [];
    setState(() => _isRead = readList.contains(widget.guideSlug));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleRead() async {
    final prefs = await SharedPreferences.getInstance();
    final readList = prefs.getStringList('guides_read') ?? [];
    setState(() {
      if (_isRead) {
        readList.remove(widget.guideSlug);
        _isRead = false;
      } else {
        readList.add(widget.guideSlug);
        _isRead = true;
      }
    });
    await prefs.setStringList('guides_read', readList);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stage = kLifeStages.firstWhere((s) => s.slug == widget.stageSlug);
    final guide = stage.guides.firstWhere((g) => g.slug == widget.guideSlug);

    return Column(children: [
      // Reading progress bar
      LinearProgressIndicator(
        value: _scrollProgress,
        minHeight: 3,
        backgroundColor: Colors.transparent,
        color: stage.color,
      ),
      Expanded(child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        // ← Back
        GestureDetector(
          onTap: () => context.go('/guide/${widget.stageSlug}'),
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.arrowLeft, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(stage.title, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ]),
          ),
        ),

        // Title
        Text(guide.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
        const SizedBox(height: 4),
        Row(children: [
          Icon(LucideIcons.clock, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('${guide.readMinutes} min read', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: stage.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4)),
            child: Text(guide.category, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: stage.color)),
          ),
        ]),
        const SizedBox(height: 20),

        // Sections
        ...guide.sections.map((section) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(section.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(section.content, style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.6)),
            if (section.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...section.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('•  ', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                  Expanded(child: Text(item, style: TextStyle(fontSize: 13, color: cs.onSurface, height: 1.5))),
                ]),
              )),
            ],
            if (section.callout != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: stage.color.withValues(alpha: 0.06),
                  border: Border(left: BorderSide(color: stage.color, width: 3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(LucideIcons.info, size: 14, color: stage.color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(section.callout!,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.4))),
                ]),
              ),
            ],
          ]),
        )),

        // Tool links
        if (guide.toolLinks.isNotEmpty) ...[
          const Divider(),
          const SizedBox(height: 12),
          Text('RELATED TOOLS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.8, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: guide.toolLinks.map((tool) => GestureDetector(
            onTap: () => context.go('/tools/$tool'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(LucideIcons.wrench, size: 12, color: cs.primary),
                const SizedBox(width: 4),
                Text(tool, style: TextStyle(fontSize: 12, color: cs.primary)),
              ]),
            ),
          )).toList()),
          const SizedBox(height: 16),
        ],

        // Mark as read button
        FilledButton.icon(
          onPressed: _toggleRead,
          icon: Icon(_isRead ? LucideIcons.checkCircle2 : LucideIcons.circle, size: 16),
          label: Text(_isRead ? 'Marked as Read' : 'Mark as Complete'),
          style: FilledButton.styleFrom(
            backgroundColor: _isRead ? cs.surfaceContainerHighest : cs.primary,
            foregroundColor: _isRead ? cs.onSurfaceVariant : cs.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    )),
    ]);
  }
}
