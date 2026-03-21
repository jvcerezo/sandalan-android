import '../local/app_database.dart';

/// Local-only repository for learned keyword → category mappings.
/// Keywords are learned from user corrections and manual category picks.
class LearnedKeywordRepository {
  final AppDatabase _db;

  LearnedKeywordRepository(this._db);

  /// Look up a keyword's learned category. Returns null if not learned.
  Future<String?> getCategoryForKeyword(String keyword) async {
    final row = await _db.getLearnedKeyword(keyword.toLowerCase());
    if (row == null) return null;
    return row['category'] as String;
  }

  /// Get the source of a learned keyword ('user_pick' or 'correction').
  Future<String?> getSourceForKeyword(String keyword) async {
    final row = await _db.getLearnedKeyword(keyword.toLowerCase());
    if (row == null) return null;
    return row['source'] as String;
  }

  /// Save or update a keyword mapping.
  /// [source] is either 'user_pick' (user chose category when engine didn't know)
  /// or 'correction' (user corrected a wrong category).
  Future<void> learn(String keyword, String category, {String source = 'user_pick'}) async {
    await _db.upsertLearnedKeyword(
      keyword: keyword.toLowerCase().trim(),
      category: category,
      source: source,
    );
  }

  /// Get all learned keywords (for debugging / export).
  Future<List<Map<String, dynamic>>> getAll() async {
    return _db.getAllLearnedKeywords();
  }
}
