/// Maps user_type to recommended guide slugs and checklist item IDs.
/// Guides/checklist not in this map still show — they just aren't
/// badged "Recommended" or sorted to the top.

/// Guide categories that are especially relevant per user type.
const Map<String, Set<String>> kRecommendedCategories = {
  'student': {'financial-literacy', 'government'},
  'fresh-grad': {'financial-literacy', 'government', 'career', 'housing'},
  'employee': {'financial-literacy', 'government', 'investing'},
  'freelancer': {'government', 'financial-literacy', 'career', 'investing'},
  'ofw': {'family', 'financial-literacy', 'investing', 'insurance'},
  'business-owner': {'government', 'financial-literacy', 'investing', 'insurance'},
  'homemaker': {'financial-literacy', 'family', 'health'},
};

/// Specific guide slugs that are high-signal for each user type,
/// regardless of category.
const Map<String, Set<String>> kRecommendedGuideSlugs = {
  'student': {
    'your-first-budget',
    'scam-protection-101',
    'government-id-roadmap',
    'mental-health-on-a-budget',
  },
  'fresh-grad': {
    'first-job-documents',
    'first-payslip-decoded',
    'government-id-roadmap',
    'your-first-budget',
    'understanding-deductions',
    'moving-out-first-place',
    'emergency-fund-101',
    'scam-protection-101',
  },
  'employee': {
    'first-payslip-decoded',
    'understanding-deductions',
    'emergency-fund-101',
    'investing-for-beginners',
    'credit-building',
    'maximize-sss-pension',
    'insurance-layering',
  },
  'freelancer': {
    'freelancer-tax-guide',
    'side-hustle-guide',
    'emergency-fund-101',
    'investing-for-beginners',
    'credit-building',
    'insurance-layering',
    'debt-management-young-adults',
  },
  'ofw': {
    'family-financial-boundaries',
    'emergency-fund-101',
    'investing-for-beginners',
    'insurance-layering',
    'pagibig-housing-loan',
    'real-estate-investment',
    'sandwich-generation',
    'education-fund',
  },
  'business-owner': {
    'freelancer-tax-guide',
    'credit-building',
    'investing-for-beginners',
    'insurance-layering',
    'advanced-insurance',
    'estate-planning-basics',
    'wealth-building',
  },
  'homemaker': {
    'your-first-budget',
    'emergency-fund-101',
    'family-financial-boundaries',
    'education-fund',
    'insurance-layering',
    'mental-health-on-a-budget',
    'first-baby-financial-prep',
    'sandwich-generation',
  },
};

/// Checklist item IDs that are especially relevant per user type.
const Map<String, Set<String>> kRecommendedChecklistIds = {
  'student': {
    'get-national-id',
    'get-tin',
    'open-bank-account',
    'open-savings-account',
  },
  'fresh-grad': {
    'get-national-id',
    'get-tin',
    'get-sss',
    'get-philhealth',
    'get-pagibig',
    'open-bank-account',
    'open-savings-account',
    'build-emergency-fund',
  },
  'employee': {
    'build-emergency-fund',
    'start-investing',
    'get-life-insurance',
    'maximize-sss',
    'review-philhealth',
  },
  'freelancer': {
    'get-tin',
    'register-bir',
    'open-bank-account',
    'build-emergency-fund',
    'get-sss',
    'get-philhealth',
    'get-pagibig',
  },
  'ofw': {
    'get-national-id',
    'build-emergency-fund',
    'get-life-insurance',
    'start-investing',
    'maximize-sss',
  },
  'business-owner': {
    'register-bir',
    'get-tin',
    'build-emergency-fund',
    'get-life-insurance',
    'start-investing',
  },
  'homemaker': {
    'open-bank-account',
    'build-emergency-fund',
    'get-philhealth',
    'get-life-insurance',
  },
};

/// Check if a guide is recommended for this user type.
bool isGuideRecommended(String? userType, String guideSlug, String guideCategory) {
  if (userType == null || userType.isEmpty) return false;
  final slugs = kRecommendedGuideSlugs[userType];
  if (slugs != null && slugs.contains(guideSlug)) return true;
  final cats = kRecommendedCategories[userType];
  if (cats != null && cats.contains(guideCategory)) return true;
  return false;
}

/// Check if a checklist item is recommended for this user type.
bool isChecklistRecommended(String? userType, String itemId) {
  if (userType == null || userType.isEmpty) return false;
  final ids = kRecommendedChecklistIds[userType];
  return ids != null && ids.contains(itemId);
}
