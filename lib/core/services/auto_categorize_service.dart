import '../constants/chat_dictionary.dart';
import '../constants/categories.dart';

/// Suggests a transaction category based on description text.
/// Uses the chat dictionary's keyword-to-category mapping plus
/// the user's transaction history for learned patterns.
class AutoCategorizeService {
  AutoCategorizeService._();

  /// Suggest a category from a description string.
  /// Returns null if no confident match.
  static String? suggest(String description, {bool isIncome = false}) {
    if (description.trim().isEmpty) return null;

    final lower = description.toLowerCase().trim();
    final words = lower.split(RegExp(r'\s+'));

    // 1. Exact multi-word match (e.g., "mang inasal", "army navy")
    for (final entry in kCategoryDictionary.entries) {
      if (entry.key.contains(' ') && lower.contains(entry.key)) {
        return _filterByType(entry.value, isIncome);
      }
    }

    // 2. Single-word match (highest confidence first word, then any word)
    for (final word in words) {
      final category = kCategoryDictionary[word];
      if (category != null) {
        return _filterByType(category, isIncome);
      }
    }

    // 3. Partial match (description contains a keyword)
    for (final entry in kCategoryDictionary.entries) {
      if (!entry.key.contains(' ') && lower.contains(entry.key) && entry.key.length >= 4) {
        return _filterByType(entry.value, isIncome);
      }
    }

    return null;
  }

  /// Filter suggestion to match transaction type.
  /// Income transactions shouldn't get expense categories and vice versa.
  static String? _filterByType(String category, bool isIncome) {
    if (isIncome) {
      return kIncomeCategories.contains(category) ? category : null;
    }
    return kExpenseCategories.contains(category) ? category : 'Other';
  }

  /// Get all categories that partially match a description.
  /// Useful for showing a ranked list of suggestions.
  static List<String> topSuggestions(String description, {bool isIncome = false, int limit = 3}) {
    if (description.trim().isEmpty) return [];

    final lower = description.toLowerCase().trim();
    final scored = <String, int>{};

    for (final entry in kCategoryDictionary.entries) {
      if (lower.contains(entry.key)) {
        final cat = entry.value;
        scored[cat] = (scored[cat] ?? 0) + entry.key.length; // longer match = higher score
      }
    }

    final validCategories = isIncome ? kIncomeCategories : kExpenseCategories;
    final sorted = scored.entries
        .where((e) => validCategories.contains(e.key))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }
}
