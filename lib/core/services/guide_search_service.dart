import '../../data/guide/guide_data.dart';

class GuideSearchResult {
  final String stageSlug;
  final String stageName;
  final String? guideSlug;
  final String? checklistId;
  final String title;
  final String excerpt;
  final String type; // 'guide' or 'checklist'
  final int score;
  final String? matchedSection;

  const GuideSearchResult({
    required this.stageSlug,
    required this.stageName,
    this.guideSlug,
    this.checklistId,
    required this.title,
    required this.excerpt,
    required this.type,
    required this.score,
    this.matchedSection,
  });

  String get route => type == 'guide'
      ? '/guide/$stageSlug/$guideSlug'
      : '/guide/$stageSlug/checklist/$checklistId';
}

/// Keyword aliases to expand search coverage.
const _aliases = <String, List<String>>{
  'nbi': ['nbi clearance', 'national bureau', 'police clearance'],
  'sss': ['social security', 'sss number', 'sss contribution', 'sss id', 'sss pension'],
  'philhealth': ['phil health', 'health insurance', 'philhealth id', 'philhealth contribution'],
  'pagibig': ['pag-ibig', 'pag ibig', 'hdmf', 'housing fund', 'mp2', 'pagibig fund'],
  'bir': ['tax', 'tin', 'income tax', 'tax identification', 'bir form', 'bir 1902', 'bir 2316'],
  'birth cert': ['birth certificate', 'psa', 'psa birth', 'civil registry'],
  'passport': ['passport', 'dfa', 'travel document'],
  'drivers': ["driver's license", 'lto', 'driving license', 'non-pro', 'student permit'],
  'postal': ['postal id', 'philpost', 'phlpost'],
  'voters': ["voter's id", 'comelec', 'voter registration'],
  'umid': ['umid', 'unified multi-purpose id'],
  'clearance': ['nbi clearance', 'police clearance', 'barangay clearance'],
  'budget': ['budget', 'budgeting', '50/30/20', 'allocation', 'monthly budget'],
  'savings': ['savings', 'emergency fund', 'ipon', 'save money', 'mag-ipon'],
  'debt': ['debt', 'utang', 'loan', 'credit card', 'pay off', 'bayad utang'],
  'insurance': ['insurance', 'life insurance', 'health insurance', 'hmo', 'policy'],
  'retirement': ['retirement', 'pension', 'retire', 'sss pension', 'retirement fund'],
  'invest': ['invest', 'investment', 'stocks', 'mutual fund', 'uitf', 'mp2', 'pse'],
  'salary': ['salary', 'payslip', 'sahod', 'deductions', 'net pay', 'take home', 'sweldo'],
  'contribution': ['contribution', 'kontribusyon', 'monthly contribution'],
  '13th month': ['13th month', 'thirteenth month', '13th month pay'],
  'tax': ['tax', 'income tax', 'train law', 'bir', 'withholding tax', 'tax filing', 'buwis'],
  'rent': ['rent', 'apartment', 'condo', 'upa', 'house rental', 'landlord', 'deposit'],
  'wedding': ['wedding', 'kasal', 'marriage', 'civil wedding'],
  'baby': ['baby', 'anak', 'child', 'first baby', 'maternity', 'paternity'],
  'car': ['car', 'vehicle', 'kotse', 'auto', 'car loan', 'car insurance'],
  'will': ['will', 'estate', 'inheritance', 'mana', 'last will'],
  'senior': ['senior citizen', 'senior', 'elderly', 'golden years', 'retirement age'],
};

class GuideSearchService {
  /// Search all guide articles and checklist items for relevant content.
  static List<GuideSearchResult> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.length < 2) return [];

    // Expand query with aliases
    final queryTerms = <String>[q];
    for (final entry in _aliases.entries) {
      if (q.contains(entry.key)) {
        queryTerms.addAll(entry.value);
      }
      for (final alias in entry.value) {
        if (q.contains(alias)) {
          queryTerms.add(entry.key);
          queryTerms.addAll(entry.value);
        }
      }
    }

    final results = <GuideSearchResult>[];

    for (final stage in kLifeStages) {
      // Search guides
      for (final guide in stage.guides) {
        int score = 0;
        String excerpt = guide.description;
        String? matchedSection;

        for (final term in queryTerms) {
          // Title match (highest weight)
          if (guide.title.toLowerCase().contains(term)) score += 50;
          if (guide.title.toLowerCase() == term) score += 50; // exact bonus

          // Description match
          if (guide.description.toLowerCase().contains(term)) score += 15;

          // Section matches
          for (final section in guide.sections) {
            if (section.heading.toLowerCase().contains(term)) {
              score += 30;
              matchedSection = section.heading;
              // Use this section's content as excerpt
              excerpt = section.content.length > 200
                  ? '${section.content.substring(0, 200)}...'
                  : section.content;
            }
            if (section.content.toLowerCase().contains(term)) {
              score += 10;
              if (matchedSection == null) {
                matchedSection = section.heading;
                final idx = section.content.toLowerCase().indexOf(term);
                final start = (idx - 50).clamp(0, section.content.length);
                final end = (idx + 150).clamp(0, section.content.length);
                excerpt = '...${section.content.substring(start, end)}...';
              }
            }
            for (final item in section.items) {
              if (item.toLowerCase().contains(term)) {
                score += 8;
              }
            }
          }
        }

        if (score > 0) {
          results.add(GuideSearchResult(
            stageSlug: stage.slug,
            stageName: stage.title,
            guideSlug: guide.slug,
            title: guide.title,
            excerpt: excerpt,
            type: 'guide',
            score: score,
            matchedSection: matchedSection,
          ));
        }
      }

      // Search checklist items
      for (final itemId in stage.checklistItemIds) {
        final item = kChecklistItems[itemId];
        if (item == null) continue;

        int score = 0;
        String excerpt = item.description;

        for (final term in queryTerms) {
          if (item.title.toLowerCase().contains(term)) score += 50;
          if (item.description.toLowerCase().contains(term)) score += 15;
          for (final step in item.steps) {
            if (step.toLowerCase().contains(term)) score += 8;
          }
          for (final tip in item.tips) {
            if (tip.toLowerCase().contains(term)) score += 5;
          }
        }

        if (score > 0) {
          results.add(GuideSearchResult(
            stageSlug: stage.slug,
            stageName: stage.title,
            checklistId: item.id,
            title: item.title,
            excerpt: excerpt.length > 200 ? '${excerpt.substring(0, 200)}...' : excerpt,
            type: 'checklist',
            score: score,
          ));
        }
      }
    }

    // Sort by score descending, take top 3
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(3).toList();
  }
}
