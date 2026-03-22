import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/guide/guide_data.dart';
import '../../../data/guide/guide_recommendations.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../../auth/providers/auth_provider.dart';

class StageDetailScreen extends ConsumerStatefulWidget {
  final String stageSlug;
  const StageDetailScreen({super.key, required this.stageSlug});

  @override
  ConsumerState<StageDetailScreen> createState() => _StageDetailScreenState();
}

class _StageDetailScreenState extends ConsumerState<StageDetailScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _completedItems = {};
  final Set<String> _skippedItems = {};
  final Set<String> _readGuides = {};
  late TabController _tabController;
  String _checklistFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProgress();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final completedChecklist =
        stage.checklist.where((c) => _completedItems.contains(c.id)).length;
    final readGuideCount =
        stage.guides.where((g) => _readGuides.contains(g.slug)).length;
    final totalProgress = stage.guides.length + stage.checklist.length;
    final completedTotal = readGuideCount + completedChecklist;
    final progressPct = totalProgress > 0
        ? (completedTotal / totalProgress * 100).round()
        : 0;

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button with stage icon
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go('/guide');
                    }
                  },
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(LucideIcons.arrowLeft,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('Back to Journey',
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant)),
                    const SizedBox(width: 8),
                    Icon(stage.icon, size: 14, color: stage.color),
                  ]),
                ),
              ),
              const SizedBox(height: 8),

              // Banner with photo + gradient overlay
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 200,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(
                    stage.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            stage.color.withValues(alpha: 0.3),
                            stage.color.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      child: Center(
                          child: Icon(stage.icon,
                              size: 64,
                              color: stage.color.withValues(alpha: 0.3))),
                    ),
                  ),
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
                  Positioned(
                    left: 16,
                    bottom: 16,
                    right: 16,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stage.title,
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.3)),
                          const SizedBox(height: 2),
                          Text(stage.subtitle,
                              style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Colors.white.withValues(alpha: 0.85))),
                        ]),
                  ),
                ]),
              ),
              const SizedBox(height: 12),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(stage.description,
                    style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface.withValues(alpha: 0.8),
                        height: 1.5)),
              ),
              const SizedBox(height: 16),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Text('Progress',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                  const Spacer(),
                  Text('$progressPct%',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: stage.color)),
                ]),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedProgressBar(
                    value:
                        completedTotal / (totalProgress > 0 ? totalProgress : 1),
                    minHeight: 6,
                    color: stage.color),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Pinned tab bar
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            tabController: _tabController,
            color: stage.color,
            backgroundColor: cs.surface,
          ),
        ),
      ],
      body: Builder(builder: (context) {
        final userType = ref.watch(profileProvider).valueOrNull?.userType;
        return TabBarView(
          controller: _tabController,
          children: [
            // Guides tab
            _GuidesTab(
              stage: stage,
              readGuides: _readGuides,
              onReturn: _loadProgress,
              userType: userType,
            ),
            // Checklist tab
            _ChecklistTab(
              stage: stage,
              stageSlug: widget.stageSlug,
              completedItems: _completedItems,
              skippedItems: _skippedItems,
              color: stage.color,
              filter: _checklistFilter,
              onFilterChanged: (f) => setState(() => _checklistFilter = f),
              onLoadProgress: _loadProgress,
              userType: userType,
            ),
          ],
        );
      }),
      ),
    ),
    );
  }
}

// ─── Tab Bar Delegate ─────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final Color color;
  final Color backgroundColor;

  _TabBarDelegate({
    required this.tabController,
    required this.color,
    required this.backgroundColor,
  });

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListenableBuilder(
        listenable: tabController,
        builder: (context, _) {
          return Container(
            height: 40,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildPill(context, 'Guides', 0),
                _buildPill(context, 'Checklist', 1),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPill(BuildContext context, String label, int index) {
    final cs = Theme.of(context).colorScheme;
    final isActive = tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      tabController != oldDelegate.tabController ||
      color != oldDelegate.color;
}

// ─── Guides Tab ───────────────────────────────────────────────────────────────

class _GuidesTab extends StatelessWidget {
  final LifeStage stage;
  final Set<String> readGuides;
  final VoidCallback onReturn;
  final String? userType;

  const _GuidesTab({
    required this.stage,
    required this.readGuides,
    required this.onReturn,
    this.userType,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final readCount =
        stage.guides.where((g) => readGuides.contains(g.slug)).length;

    // Sort: recommended first, then the rest
    final sorted = List<Guide>.from(stage.guides);
    if (userType != null && userType!.isNotEmpty) {
      sorted.sort((a, b) {
        final aRec = isGuideRecommended(userType, a.slug, a.category) ? 0 : 1;
        final bRec = isGuideRecommended(userType, b.slug, b.category) ? 0 : 1;
        return aRec.compareTo(bRec);
      });
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        ...sorted.map((guide) {
          final isRead = readGuides.contains(guide.slug);
          final isRec = isGuideRecommended(userType, guide.slug, guide.category);
          return _GuideItem(
            guide: guide,
            stageSlug: stage.slug,
            color: stage.color,
            isRead: isRead,
            isRecommended: isRec,
            onReturn: onReturn,
          );
        }),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '$readCount of ${stage.guides.length} guides completed',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
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
  final bool isRecommended;
  final VoidCallback onReturn;

  const _GuideItem({
    required this.guide,
    required this.stageSlug,
    required this.color,
    required this.isRead,
    this.isRecommended = false,
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? color.withValues(alpha: 0.03) : cs.surface,
          border: Border.all(
              color: isRead
                  ? color.withValues(alpha: 0.15)
                  : cs.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(children: [
              // Icon with checkmark overlay
              SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(LucideIcons.bookOpen,
                          size: 16, color: color),
                    ),
                    if (isRead)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.surface, width: 1.5),
                          ),
                          child: const Icon(Icons.check,
                              size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(guide.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        )),
                    const SizedBox(height: 2),
                    Text(guide.description,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                            height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      if (isRecommended) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(LucideIcons.sparkles, size: 9, color: color),
                            const SizedBox(width: 3),
                            Text('Recommended',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                          ]),
                        ),
                      ],
                      Icon(LucideIcons.clock,
                          size: 10,
                          color:
                              cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(width: 3),
                      Text('${guide.readMinutes} min read',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.5))),
                    ]),
                  ])),
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight,
                  size: 16,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
            ]),
            if (isRead) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Completed',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF22C55E))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Checklist Tab ────────────────────────────────────────────────────────────

class _ChecklistTab extends StatelessWidget {
  final LifeStage stage;
  final String stageSlug;
  final Set<String> completedItems;
  final Set<String> skippedItems;
  final Color color;
  final String filter;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onLoadProgress;
  final String? userType;

  const _ChecklistTab({
    required this.stage,
    required this.stageSlug,
    required this.completedItems,
    required this.skippedItems,
    required this.color,
    required this.filter,
    required this.onFilterChanged,
    required this.onLoadProgress,
    this.userType,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final checklist = stage.checklist;
    final doneCount =
        checklist.where((c) => completedItems.contains(c.id)).length;
    final skippedCount =
        checklist.where((c) => skippedItems.contains(c.id)).length;

    // Group by priority
    final groups = <String, List<ChecklistItem>>{
      'critical': [],
      'important': [],
      'good-to-have': [],
    };
    for (final item in checklist) {
      final key = groups.containsKey(item.priority) ? item.priority : 'good-to-have';
      groups[key]!.add(item);
    }

    // Sort within groups: recommended first, then incomplete, then done, then skipped
    for (final key in groups.keys) {
      groups[key]!.sort((a, b) {
        // Recommended items float to top
        final aRec = isChecklistRecommended(userType, a.id) ? 0 : 1;
        final bRec = isChecklistRecommended(userType, b.id) ? 0 : 1;
        if (aRec != bRec) return aRec.compareTo(bRec);

        int rank(ChecklistItem i) {
          if (skippedItems.contains(i.id)) return 2;
          if (completedItems.contains(i.id)) return 1;
          return 0;
        }
        return rank(a).compareTo(rank(b));
      });
    }

    // Apply filter
    bool passesFilter(ChecklistItem item) {
      if (filter == 'All') return true;
      if (filter == 'Todo') {
        return !completedItems.contains(item.id) &&
            !skippedItems.contains(item.id);
      }
      if (filter == 'Done') return completedItems.contains(item.id);
      if (filter == 'Skipped') return skippedItems.contains(item.id);
      return true;
    }

    final priorityOrder = ['critical', 'important', 'good-to-have'];
    final priorityLabels = {
      'critical': 'MUST DO',
      'important': 'SHOULD DO',
      'good-to-have': 'NICE TO HAVE',
    };
    final priorityColors = {
      'critical': cs.error,
      'important': const Color(0xFFF59E0B), // amber — works on both themes
      'good-to-have': cs.onSurfaceVariant,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        // Filter chips
        Wrap(
          spacing: 8,
          children: ['All', 'Todo', 'Done', 'Skipped'].map((f) {
            final isActive = filter == f;
            return GestureDetector(
              onTap: () => onFilterChanged(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? color.withValues(alpha: 0.12)
                      : Colors.transparent,
                  border: Border.all(
                    color: isActive
                        ? color.withValues(alpha: 0.3)
                        : cs.surfaceContainerHighest,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? color : cs.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Priority groups
        ...priorityOrder.where((p) => groups[p]!.isNotEmpty).map((priority) {
          final items = groups[priority]!.where(passesFilter).toList();
          if (items.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group header
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: priorityColors[priority],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    priorityLabels[priority]!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: priorityColors[priority],
                    ),
                  ),
                ]),
              ),
              ...items.map((item) {
                final isDone = completedItems.contains(item.id);
                final isSkipped = skippedItems.contains(item.id);
                final isRec = isChecklistRecommended(userType, item.id);
                return _ChecklistRow(
                  item: item,
                  isDone: isDone,
                  isSkipped: isSkipped,
                  isRecommended: isRec,
                  color: color,
                  onTap: () async {
                    await GoRouter.of(context)
                        .push('/guide/$stageSlug/checklist/${item.id}');
                    onLoadProgress();
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          );
        }),

        // Summary
        Center(
          child: Text(
            '$doneCount of ${checklist.length} completed'
            '${skippedCount > 0 ? ' \u00b7 $skippedCount skipped' : ''}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Checklist Row ────────────────────────────────────────────────────────────

class _ChecklistRow extends StatelessWidget {
  final ChecklistItem item;
  final bool isDone;
  final bool isSkipped;
  final bool isRecommended;
  final Color color;
  final VoidCallback onTap;

  const _ChecklistRow({
    required this.item,
    required this.isDone,
    required this.isSkipped,
    this.isRecommended = false,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDone ? color.withValues(alpha: 0.04) : cs.surface,
          border: Border.all(
              color: isDone
                  ? color.withValues(alpha: 0.2)
                  : cs.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          // Circle checkbox
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDone ? color : Colors.transparent,
              border: Border.all(
                color: isDone
                    ? color
                    : isSkipped
                        ? cs.outline.withValues(alpha: 0.25)
                        : cs.outline.withValues(alpha: 0.25),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              shape: BoxShape.circle,
            ),
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : isSkipped
                    ? Icon(Icons.remove, size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4))
                    : null,
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      fontStyle: isSkipped ? FontStyle.italic : null,
                      color: isDone || isSkipped
                          ? cs.onSurfaceVariant
                          : cs.onSurface,
                    )),
                const SizedBox(height: 2),
                Text(item.description,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant, height: 1.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (isRecommended && !isDone && !isSkipped) ...[
                  const SizedBox(height: 4),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(LucideIcons.sparkles, size: 9, color: color),
                        const SizedBox(width: 3),
                        Text('Recommended',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                      ]),
                    ),
                  ]),
                ],
              ])),
          const SizedBox(width: 6),
          if (isDone)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Done',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF22C55E))),
            )
          else if (isSkipped)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Skipped',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant)),
            ),
          Icon(LucideIcons.chevronRight,
              size: 14,
              color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
        ]),
      ),
    );
  }
}
