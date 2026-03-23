import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/categories.dart';

/// The search bar and expandable filter panel for the transactions screen.
class TransactionFiltersPanel extends StatelessWidget {
  final TextEditingController searchController;
  final bool showFilters;
  final String dateRange;
  final String categoryFilter;
  final VoidCallback onSearch;
  final VoidCallback onToggleFilters;
  final ValueChanged<String> onDateRangeChanged;
  final ValueChanged<String> onCategoryChanged;

  const TransactionFiltersPanel({
    super.key,
    required this.searchController,
    required this.showFilters,
    required this.dateRange,
    required this.categoryFilter,
    required this.onSearch,
    required this.onToggleFilters,
    required this.onDateRangeChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(children: [
        // Search row — compact, no card wrapper
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(LucideIcons.search, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 13),
                onSubmitted: (_) => onSearch(),
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onToggleFilters();
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(LucideIcons.slidersHorizontal, size: 16,
                    color: showFilters ? colorScheme.primary : colorScheme.onSurfaceVariant),
              ),
            ),
          ]),
        ),

        // Expandable filters
        if (showFilters) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Date Range
          _FilterSection(label: 'DATE RANGE', child: Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              _FilterPill(label: 'All Time', isSelected: dateRange == 'all',
                  onTap: () => onDateRangeChanged('all')),
              _FilterPill(label: 'This Month', isSelected: dateRange == 'month',
                  onTap: () => onDateRangeChanged('month')),
              _FilterPill(label: 'Last Month', isSelected: dateRange == 'lastMonth',
                  onTap: () => onDateRangeChanged('lastMonth')),
              _FilterPill(label: 'Last 3 Months', isSelected: dateRange == '3months',
                  onTap: () => onDateRangeChanged('3months')),
            ],
          )),
          const SizedBox(height: 12),

          // Category
          _FilterSection(label: 'CATEGORY', child: Wrap(
            spacing: 6, runSpacing: 6,
            children: ['All', ...kCategories].map((c) => _FilterPill(
              label: c,
              isSelected: categoryFilter == c,
              onTap: () => onCategoryChanged(c),
            )).toList(),
          )),
        ],
      ]);
  }
}

class _FilterSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _FilterSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
          letterSpacing: 0.8, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      child,
    ]);
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterPill({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant)),
      ),
    );
  }
}
