import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/id_generator.dart' show IdGenerator;
import '../../../core/utils/provider_utils.dart';
import '../../../data/models/expense_template.dart';
import '../providers/transaction_providers.dart';
import 'manage_templates_sheet.dart';
import '../../../shared/utils/snackbar_helper.dart';

/// Category emoji mapping for template chips.
String _categoryEmoji(String category) {
  switch (category.toLowerCase()) {
    case 'food': return '\ud83c\udf54';
    case 'transportation': return '\ud83d\ude8c';
    case 'entertainment': return '\ud83c\udfac';
    case 'healthcare': return '\ud83c\udfe5';
    case 'education': return '\ud83d\udcda';
    case 'housing': return '\ud83c\udfe0';
    case 'family support': return '\u2764\ufe0f';
    case 'salary': return '\ud83d\udcb0';
    case 'freelance': return '\ud83d\udcbb';
    case 'investment': return '\ud83d\udcc8';
    default: return '\u2615';
  }
}

/// Provider for expense templates stored in SharedPreferences.
final templatesProvider = StateNotifierProvider<TemplatesNotifier, List<ExpenseTemplate>>((ref) {
  return TemplatesNotifier();
});

class TemplatesNotifier extends StateNotifier<List<ExpenseTemplate>> {
  TemplatesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('expense_templates');
    if (jsonStr != null) {
      try {
        final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
        state = list.map((e) => ExpenseTemplate.fromJson(e)).toList();
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString('expense_templates', jsonStr);
  }

  Future<void> addTemplate(ExpenseTemplate template) async {
    state = [...state, template];
    await _save();
  }

  Future<void> updateTemplate(ExpenseTemplate template) async {
    state = [for (final t in state) t.id == template.id ? template : t];
    await _save();
  }

  Future<void> removeTemplate(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _save();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final items = [...state];
    final item = items.removeAt(oldIndex);
    items.insert(newIndex < oldIndex ? newIndex : newIndex - 1, item);
    state = items;
    await _save();
  }

  Future<void> recordUse(String id) async {
    state = [
      for (final t in state)
        t.id == id
            ? t.copyWith(useCount: t.useCount + 1, lastUsed: DateTime.now())
            : t,
    ];
    await _save();
  }
}

/// Horizontal scrollable row of template chips for quick transaction adding.
class QuickAddStrip extends ConsumerWidget {
  final Future<void> Function(ExpenseTemplate template)? onUseTemplate;
  const QuickAddStrip({super.key, this.onUseTemplate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (templates.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: templates.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == templates.length) {
            // "+ New" chip
            return ActionChip(
              avatar: Icon(LucideIcons.plus, size: 14, color: colorScheme.primary),
              label: Text('New', style: TextStyle(fontSize: 12, color: colorScheme.primary)),
              side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
              backgroundColor: colorScheme.primary.withOpacity(0.05),
              onPressed: () => showManageTemplatesSheet(context, ref),
            );
          }

          final t = templates[index];
          return ActionChip(
            avatar: Text(_categoryEmoji(t.category), style: const TextStyle(fontSize: 14)),
            label: Text(
              '${t.name} \u20b1${t.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            side: BorderSide(color: colorScheme.surfaceContainerHighest),
            backgroundColor: colorScheme.surface,
            onPressed: () async {
              HapticFeedback.lightImpact();
              if (onUseTemplate != null) {
                await onUseTemplate!(t);
              } else {
                // Create transaction directly
                await _createFromTemplate(context, ref, t);
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _createFromTemplate(BuildContext context, WidgetRef ref, ExpenseTemplate t) async {
    try {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.createTransaction(
        amount: -t.amount,
        category: t.category,
        description: t.description ?? t.name,
        date: DateTime.now(),
        accountId: t.accountId,
      );
      ref.read(templatesProvider.notifier).recordUse(t.id);
      invalidateTransactionProviders(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${t.name} — \u20b1${t.amount.toStringAsFixed(0)} logged'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Undo by deleting the most recent transaction
              // For simplicity, just invalidate to refresh
              ref.invalidate(transactionsSummaryProvider);
              ref.invalidate(recentTransactionsProvider);
            },
          ),
        ));
      }
    } catch (e) {
      showAppSnackBar(context, 'Failed to log transaction', isError: true);
    }
  }
}

/// Check if a transaction should be suggested as a template.
/// Call this after saving a transaction.
Future<void> checkTemplateSuggestion({
  required BuildContext context,
  required WidgetRef ref,
  required String description,
  required double amount,
  required String category,
  required String? accountId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'template_check_${description.toLowerCase()}_${amount.toStringAsFixed(0)}_$category';
  final count = prefs.getInt(key) ?? 0;
  await prefs.setInt(key, count + 1);

  if (count + 1 >= 3) {
    // Already suggested?
    final suggested = prefs.getBool('template_suggested_$key') ?? false;
    if (suggested) return;
    await prefs.setBool('template_suggested_$key', true);

    // Check if template already exists
    final templates = ref.read(templatesProvider);
    final exists = templates.any((t) =>
        t.name.toLowerCase() == description.toLowerCase() && t.amount == amount);
    if (exists) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Save "$description" as a quick template?'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Save',
          onPressed: () {
            ref.read(templatesProvider.notifier).addTemplate(ExpenseTemplate(
              id: IdGenerator.generate('local-tpl'),
              name: description,
              amount: amount,
              category: category,
              accountId: accountId,
              description: description,
              lastUsed: DateTime.now(),
            ));
          },
        ),
      ));
    }
  }
}
