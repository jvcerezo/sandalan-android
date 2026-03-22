import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _scrollProgress = ValueNotifier<double>(0.0);
  final _scrollController = ScrollController();

  static const _secureChannel = MethodChannel('com.jvcerezo.sandalan/secure');

  @override
  void initState() {
    super.initState();
    _loadReadStatus();
    _scrollController.addListener(_onScroll);
    // Prevent screenshots on guide content
    _secureChannel.invokeMethod('enableSecure').catchError((_) {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final max = pos.maxScrollExtent;
    if (max <= 0) return;
    _scrollProgress.value = (pos.pixels / max).clamp(0.0, 1.0);
  }

  Future<void> _loadReadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final readList = prefs.getStringList('guides_read') ?? [];
    setState(() => _isRead = readList.contains(widget.guideSlug));
  }

  @override
  void dispose() {
    // Re-allow screenshots when leaving guide content
    _secureChannel.invokeMethod('disableSecure').catchError((_) {});
    _scrollController.dispose();
    _scrollProgress.dispose();
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

    return Scaffold(body: SafeArea(child: Column(children: [
      // Reading progress bar
      ValueListenableBuilder<double>(
        valueListenable: _scrollProgress,
        builder: (context, progress, _) => LinearProgressIndicator(
          value: progress,
          minHeight: 3,
          backgroundColor: Colors.transparent,
          color: stage.color,
        ),
      ),
      Expanded(child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        // ← Back
        GestureDetector(
          onTap: () { if (Navigator.canPop(context)) Navigator.pop(context); else context.go('/guide/${widget.stageSlug}'); },
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
            Text(section.heading, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
            if (section.calloutType != null && section.calloutText != null) ...[
              const SizedBox(height: 10),
              _CalloutBox(type: section.calloutType!, text: section.calloutText!),
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
            onTap: () => context.go(tool.href),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(LucideIcons.wrench, size: 12, color: cs.primary),
                const SizedBox(width: 4),
                Text(tool.label, style: TextStyle(fontSize: 12, color: cs.primary)),
              ]),
            ),
          )).toList()),
          const SizedBox(height: 16),
        ],

        // Mark as read button
        // Mark as complete
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
        const SizedBox(height: 16),

        // Prev/Next navigation
        _buildPrevNext(stage, guide, cs),
        const SizedBox(height: 16),

        // View Stage Progress
        OutlinedButton.icon(
          onPressed: () => context.go('/guide/${widget.stageSlug}'),
          icon: Icon(LucideIcons.wrench, size: 14, color: cs.primary),
          label: Text('View Stage Progress', style: TextStyle(color: cs.primary)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    )),
    ])));
  }

  Widget _buildPrevNext(LifeStage stage, Guide currentGuide, ColorScheme cs) {
    final idx = stage.guides.indexWhere((g) => g.slug == currentGuide.slug);
    final prev = idx > 0 ? stage.guides[idx - 1] : null;
    final next = idx < stage.guides.length - 1 ? stage.guides[idx + 1] : null;

    if (prev == null && next == null) return const SizedBox.shrink();

    return Row(children: [
      if (prev != null)
        Expanded(
          child: GestureDetector(
            onTap: () => context.go('/guide/${widget.stageSlug}/${prev.slug}'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(LucideIcons.arrowLeft, size: 12, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('Previous', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                ]),
                const SizedBox(height: 4),
                Text(prev.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
        ),
      if (prev != null && next != null) const SizedBox(width: 8),
      if (next != null)
        Expanded(
          child: GestureDetector(
            onTap: () => context.go('/guide/${widget.stageSlug}/${next.slug}'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Next', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.arrowRight, size: 12, color: cs.onSurfaceVariant),
                ]),
                const SizedBox(height: 4),
                Text(next.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
              ]),
            ),
          ),
        ),
    ]);
  }
}

// ─── Callout Box ──────────────────────────────────────────────────────────────

class _CalloutBox extends StatelessWidget {
  final CalloutType type;
  final String text;
  const _CalloutBox({required this.type, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color borderColor;
    Color bgColor;
    Color iconColor;
    IconData icon;
    String label;

    switch (type) {
      case CalloutType.tip:
        borderColor = Colors.green;
        bgColor = isDark ? Colors.green.withValues(alpha: 0.08) : Colors.green.shade50;
        iconColor = isDark ? Colors.green.shade300 : Colors.green.shade600;
        icon = LucideIcons.lightbulb;
        label = 'TIP';
      case CalloutType.warning:
        borderColor = Colors.amber;
        bgColor = isDark ? Colors.amber.withValues(alpha: 0.08) : Colors.amber.shade50;
        iconColor = isDark ? Colors.amber.shade300 : Colors.amber.shade700;
        icon = LucideIcons.alertTriangle;
        label = 'WARNING';
      case CalloutType.info:
        borderColor = Colors.blueGrey;
        bgColor = isDark ? Colors.blueGrey.withValues(alpha: 0.08) : Colors.blueGrey.shade50;
        iconColor = isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600;
        icon = LucideIcons.info;
        label = 'NOTE';
      case CalloutType.phLaw:
        borderColor = Colors.blue;
        bgColor = isDark ? Colors.blue.withValues(alpha: 0.08) : Colors.blue.shade50;
        iconColor = isDark ? Colors.blue.shade300 : Colors.blue.shade600;
        icon = LucideIcons.scale;
        label = 'PHILIPPINE LAW';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: iconColor)),
        ]),
        const SizedBox(height: 6),
        Text(text, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85), height: 1.5)),
      ]),
    );
  }
}
