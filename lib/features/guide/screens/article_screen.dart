import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/milestone_service.dart';
import '../../../core/services/progress_sync_service.dart';
import '../../../shared/widgets/milestone_celebration.dart';
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

  @override
  void didUpdateWidget(covariant ArticleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.guideSlug != widget.guideSlug || oldWidget.stageSlug != widget.stageSlug) {
      // Reset scroll position and progress when navigating to a different article
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      _scrollProgress.value = 0.0;
      _loadReadStatus();
    }
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
    ProgressSyncService.instance.pushAfterChange();
    // Check guide milestones when marking as read (not when unmarking)
    if (_isRead) {
      _checkGuideMilestones(readList.length);
    }
  }

  Future<void> _checkGuideMilestones(int readCount) async {
    try {
      final totalGuides = kLifeStages.fold<int>(0, (sum, s) => sum + s.guides.length);
      final thresholds = <int, String>{
        1: 'first_guide_read',
        5: 'guides_5',
        10: 'guides_10',
      };
      for (final entry in thresholds.entries) {
        if (readCount >= entry.key) {
          final milestone = await MilestoneService.checkAndTrigger(entry.value);
          if (milestone != null && mounted) {
            showMilestoneCelebration(context, milestone);
            return;
          }
        }
      }
      if (totalGuides > 0 && readCount >= totalGuides) {
        final milestone = await MilestoneService.checkAndTrigger('guides_all');
        if (milestone != null && mounted) {
          showMilestoneCelebration(context, milestone);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stage = kLifeStages.firstWhere((s) => s.slug == widget.stageSlug);
    final guide = stage.guides.firstWhere((g) => g.slug == widget.guideSlug);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/guide/${widget.stageSlug}');
        }
      },
      child: Scaffold(body: SafeArea(child: Column(children: [
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
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/guide/${widget.stageSlug}');
            }
          },
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
        const SizedBox(height: 16),

        // Quick Summary (TL;DR)
        if (guide.summary.isNotEmpty)
          _QuickSummaryCard(summary: guide.summary, stageColor: stage.color),

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
    ]))),  // Column children, Column, SafeArea, Scaffold
    );  // PopScope
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

// ─── Quick Summary (TL;DR) ───────────────────────────────────────────────────

class _QuickSummaryCard extends StatefulWidget {
  final List<String> summary;
  final Color stageColor;
  const _QuickSummaryCard({required this.summary, required this.stageColor});

  @override
  State<_QuickSummaryCard> createState() => _QuickSummaryCardState();
}

class _QuickSummaryCardState extends State<_QuickSummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: widget.stageColor, width: 3)),
        color: widget.stageColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        // Header — always visible, tappable
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(children: [
              Icon(LucideIcons.clipboardList, size: 14, color: widget.stageColor),
              const SizedBox(width: 8),
              Text('QUICK SUMMARY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 0.5, color: widget.stageColor)),
              const Spacer(),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(LucideIcons.chevronDown, size: 16, color: cs.onSurfaceVariant),
              ),
            ]),
          ),
        ),

        // Content — collapsible
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ...widget.summary.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(LucideIcons.checkCircle2, size: 14, color: widget.stageColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(point,
                      style: TextStyle(fontSize: 12, color: cs.onSurface, height: 1.4))),
                ]),
              )),
              const SizedBox(height: 4),
              Text('Read full article below ↓',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
            ]),
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ]),
    );
  }
}
