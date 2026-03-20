import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ─── Types ────────────────────────────────────────────────────────────────────

enum CalloutType { tip, warning, info, phLaw }

class GuideSection {
  final String heading;
  final String content;
  final List<String> items;
  final CalloutType? calloutType;
  final String? calloutText;

  const GuideSection({
    required this.heading,
    required this.content,
    this.items = const [],
    this.calloutType,
    this.calloutText,
  });
}

class ToolLink {
  final String href;
  final String label;
  const ToolLink({required this.href, required this.label});
}

class Guide {
  final String slug;
  final String title;
  final String description;
  final String category;
  final int readMinutes;
  final List<ToolLink> toolLinks;
  final List<GuideSection> sections;

  const Guide({
    required this.slug,
    required this.title,
    required this.description,
    required this.category,
    required this.readMinutes,
    this.toolLinks = const [],
    required this.sections,
  });
}

class ChecklistItem {
  final String id;
  final String title;
  final String description;
  final String priority; // 'high', 'medium', 'low'
  final String? fee;
  final String? processingTime;
  final List<String> steps;

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    this.priority = 'medium',
    this.fee,
    this.processingTime,
    this.steps = const [],
  });
}

class LifeStage {
  final String slug;
  final String title;
  final String subtitle;
  final String ageRange;
  final String description;
  final Color color;
  final IconData icon;
  final List<Guide> guides;
  final List<String> checklistItemIds;

  const LifeStage({
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.ageRange,
    required this.description,
    required this.color,
    required this.icon,
    required this.guides,
    this.checklistItemIds = const [],
  });

  List<ChecklistItem> get checklist =>
      checklistItemIds
          .where((id) => kChecklistItems.containsKey(id))
          .map((id) => kChecklistItems[id]!)
          .toList();
}

// ─── Stage definitions ────────────────────────────────────────────────────────

final List<LifeStage> kLifeStages = [
  LifeStage(
    slug: 'unang-hakbang',
    title: 'Unang Hakbang',
    subtitle: 'First Steps',
    ageRange: '18–22',
    description: 'Your first job, first IDs, first payslip. Everything you need to start adulting in the Philippines.',
    color: Colors.blue,
    icon: LucideIcons.graduationCap,
    checklistItemIds: ['tin', 'sss', 'philhealth', 'pagibig', 'philsys', 'umid', 'passport', 'drivers-license', 'voters-id', 'first-time-jobseeker', 'savings-account', 'understand-payslip'],
    guides: _unangHakbangGuides,
  ),
  LifeStage(
    slug: 'pundasyon',
    title: 'Pundasyon',
    subtitle: 'Building the Foundation',
    ageRange: '23–28',
    description: 'Emergency fund, first investments, credit building, and freelancer taxes. Build the financial habits that last a lifetime.',
    color: Colors.green,
    icon: LucideIcons.toyBrick,
    checklistItemIds: ['digital-savings', 'emergency-fund-3mo', 'credit-card', 'sss-active', 'philhealth-active', 'pagibig-active', '13th-month', 'bir-2316', 'substituted-filing', 'bir-freelancer', 'bir-deductions'],
    guides: _pundasyonGuides,
  ),
  LifeStage(
    slug: 'tahanan',
    title: 'Tahanan',
    subtitle: 'Establishing a Home',
    ageRange: '29–35',
    description: 'Marriage, homeownership, insurance, and starting a family. The decisions that shape your next decades.',
    color: Colors.purple,
    icon: LucideIcons.home,
    checklistItemIds: ['philhealth-benefits', 'hmo', 'life-insurance', 'ctpl', 'emergency-fund-6mo'],
    guides: _tahananGuides,
  ),
  LifeStage(
    slug: 'tugatog',
    title: 'Tugatog',
    subtitle: 'Career Peak',
    ageRange: '36–45',
    description: 'Peak earning years. Build wealth, diversify investments, and secure your children\'s future.',
    color: Colors.amber,
    icon: LucideIcons.trendingUp,
    checklistItemIds: ['mp2', 'uitf', 'stocks-pse', 'sss-voluntary'],
    guides: _tugatogGuides,
  ),
  LifeStage(
    slug: 'paghahanda',
    title: 'Paghahanda',
    subtitle: 'Preparing for the Future',
    ageRange: '46–55',
    description: 'Retirement planning, estate planning, and managing the sandwich generation. Prepare for what\'s ahead.',
    color: Colors.red,
    icon: LucideIcons.shield,
    checklistItemIds: ['beneficiaries', 'will', 'estate-tax'],
    guides: _paghahandaGuides,
  ),
  LifeStage(
    slug: 'gintong-taon',
    title: 'Gintong Taon',
    subtitle: 'Golden Years',
    ageRange: '56+',
    description: 'Retirement, senior citizen benefits, healthcare, and passing wealth to the next generation.',
    color: Colors.yellow.shade700,
    icon: LucideIcons.sun,
    checklistItemIds: [],
    guides: _gintongTaonGuides,
  ),
];

// ─── UNANG HAKBANG (5 guides) ─────────────────────────────────────────────────

const _unangHakbangGuides = [
  Guide(
    slug: 'first-job-documents',
    title: 'Preparing Documents for Your First Job',
    description: 'The complete list of documents Filipino employers require — and how to get them fast and free with your First Time Jobseeker certificate.',
    category: 'government',
    readMinutes: 6,
    toolLinks: [ToolLink(href: '/guide/unang-hakbang', label: 'View Stage Progress')],
    sections: [
      GuideSection(
        heading: 'The standard requirements',
        content: 'Almost every employer in the Philippines asks for the same set of documents. Having these ready before you even start applying puts you ahead of 90% of fresh graduates.',
        items: [
          'Resume/CV (updated, 1-2 pages max)',
          'PSA Birth Certificate (not the local civil registrar copy — must be PSA-issued)',
          'Transcript of Records (TOR) or diploma',
          'NBI Clearance',
          'Police Clearance or Barangay Clearance',
          'TIN (Tax Identification Number) from BIR',
          'SSS number (E-1 form or printout)',
          'PhilHealth number (PMRF or printout)',
          'Pag-IBIG MID number',
          '2x2 and 1x1 ID photos (white background, at least 4 copies each)',
          'Valid government-issued ID',
          'First Time Jobseeker Certificate from your Barangay (saves you money on fees)',
        ],
      ),
      GuideSection(
        heading: 'Get your First Time Jobseeker Certificate first',
        content: 'Before applying for NBI clearance, police clearance, or any other document — go to your Barangay Hall and get a First Time Jobseeker Certificate under RA 11261. This exempts you from paying fees on most employment requirements. It typically saves ₱500–₱1,500.',
        calloutType: CalloutType.tip,
        calloutText: 'Get the First Time Jobseeker Certificate BEFORE anything else. It makes NBI Clearance, Police Clearance, Barangay Clearance, and even your PSA Birth Certificate FREE. Valid for 1 year.',
      ),
      GuideSection(
        heading: 'NBI Clearance — step by step',
        content: 'The NBI Clearance is the most commonly required pre-employment document. Here\'s how to get it:',
        items: [
          'Go to clearance.nbi.gov.ph and create an account',
          'Fill out the online application form',
          'Select your preferred NBI branch and appointment date',
          'Pay the fee online (₱155) or present your First Time Jobseeker Certificate for exemption',
          'On your appointment date, bring: valid ID, printed reference number, and First Time Jobseeker Certificate (if applicable)',
          'Biometrics capture (fingerprints and photo) takes about 10-15 minutes',
          'If no \'hit\' (name match in records): clearance is released same day',
          'If there\'s a \'hit\': you\'ll need to return after 7-14 business days for verification',
        ],
      ),
      GuideSection(
        heading: 'BIR Form 1902 — for new employees',
        content: 'When you get hired, your employer will ask you to fill out BIR Form 1902. This registers you as a new employee with the Bureau of Internal Revenue and generates your TIN if you don\'t already have one.',
        items: [
          'Your employer\'s HR department provides the form — don\'t go to BIR yourself',
          'Fill it out completely: personal info, employer details, and tax status',
          'Tax status: \'S\' for single with no dependents, \'S1\' for single with 1 dependent, \'ME\' for married',
          'If you already have a TIN from a previous registration (e.g., freelancing), inform HR immediately — do NOT get a second TIN',
          'Your employer submits this to BIR within 10 days of your start date',
        ],
        calloutType: CalloutType.warning,
        calloutText: 'Never apply for a second TIN. If you already have one (from freelancing, OJT, or scholarship), tell your employer. Having multiple TINs is a criminal offense under the Tax Code.',
      ),
      GuideSection(
        heading: 'Pro tips for first-time applicants',
        content: 'Save time and avoid common mistakes:',
        items: [
          'Process all documents in one week: Day 1 — Barangay (FTJC), Day 2 — NBI, Day 3 — SSS/PhilHealth/Pag-IBIG, Day 4 — PSA birth cert, Day 5 — photos',
          'Bring at least 5 photocopies of every document — employers, banks, and government offices all ask for copies',
          'Wear a collared shirt for your ID photos — some companies require this for their employee IDs',
          'Save digital copies (photos/scans) of all documents on your phone and cloud storage',
          'Create a folder (physical and digital) labeled \'Employment Documents\' — you\'ll need these for your entire career',
        ],
      ),
    ],
  ),
  Guide(
    slug: 'first-payslip-decoded',
    title: 'Your First Payslip, Decoded',
    description: 'Understand every line of your payslip — where your money goes and why those deductions actually protect you.',
    category: 'financial-literacy',
    readMinutes: 5,
    toolLinks: [
      ToolLink(href: '/tools/contributions', label: 'Salary & Deductions Calculator'),
      ToolLink(href: '/tools/contributions', label: 'Track Contributions'),
    ],
    sections: [
      GuideSection(heading: 'Why your payslip matters', content: 'Your payslip is a map of your money. Every peso deducted has a purpose — from funding your future retirement pension to covering hospitalization costs. Most fresh graduates glance at the net pay and ignore the rest. That\'s a mistake. Understanding your payslip is the first step to taking control of your finances.'),
      GuideSection(heading: 'Gross pay vs. net pay', content: 'Gross pay is your salary before deductions. Net pay (take-home pay) is what actually lands in your bank account. The difference? Mandatory government contributions and income tax. On a P25,000 gross salary, expect roughly P2,500–P3,000 in total deductions, leaving you with around P22,000–P22,500 net.', calloutType: CalloutType.tip, calloutText: 'Use the Gov\'t Contributions calculator to see the exact breakdown for your salary — it computes your SSS, PhilHealth, Pag-IBIG deductions, and withholding tax automatically based on current 2024 rates.'),
      GuideSection(heading: 'SSS (Social Security System)', content: 'Your SSS contribution is split between you and your employer. The employee share is 5% of your Monthly Salary Credit (MSC). This funds your retirement pension, maternity/sickness benefits, disability coverage, and salary/calamity loans. The more you contribute over your career, the higher your pension will be.', items: ['Retirement pension after 120 months (10 years) of contributions', 'Salary loan up to 2 months\' salary after 36 contributions', 'Maternity benefit: 100% of daily salary credit for 105 days', 'Sickness benefit: 90% of daily salary credit for up to 120 days']),
      GuideSection(heading: 'PhilHealth', content: 'PhilHealth is your national health insurance. The premium is 5% of your basic salary, split equally between you and your employer. It covers inpatient hospitalization, outpatient consultations, and selected medicines. A single hospital stay without PhilHealth can cost P50,000–P200,000+ out of pocket.', calloutType: CalloutType.phLaw, calloutText: 'PhilHealth contributions are mandatory for all employed Filipinos under Republic Act No. 11223 (Universal Health Care Act).'),
      GuideSection(heading: 'Pag-IBIG (HDMF)', content: 'Pag-IBIG contributions are P200/month for most employees. Your employer matches this amount. While it seems small, Pag-IBIG opens the door to housing loans (up to P6,000,000 at 5.75% interest) and the MP2 savings program that earns 6–7% tax-free annually.', calloutType: CalloutType.tip, calloutText: 'After 24 months of Pag-IBIG contributions, you\'re eligible for housing loans. Start tracking your contributions now so you know exactly when you qualify.'),
      GuideSection(heading: 'Withholding tax', content: 'Under the TRAIN Law, you pay 0% income tax if your annual taxable income is P250,000 or below (roughly P20,833/month). Above that threshold, tax rates range from 15% to 35% on a graduated scale. Your employer withholds this tax from each paycheck and remits it to the BIR on your behalf.'),
      GuideSection(heading: 'What to do right now', content: 'Don\'t just look at your payslip — verify it. Check that your SSS, PhilHealth, and Pag-IBIG deductions match the official contribution tables. Some employers make errors or, worse, deduct but fail to remit. Track your contributions monthly using Sandalan.', items: ['Open the Gov\'t Contributions calculator and enter your gross salary', 'Compare the calculated deductions with your actual payslip', 'Start logging your contributions in the Contributions Tracker', 'Set a monthly reminder to verify your contributions are posted']),
    ],
  ),
  Guide(
    slug: 'government-id-roadmap',
    title: 'The Government ID Roadmap',
    description: 'Which IDs to get first, what documents you need, and how to avoid the \'you need an ID to get an ID\' trap.',
    category: 'government',
    readMinutes: 6,
    toolLinks: [ToolLink(href: '/guide/unang-hakbang', label: 'View Stage Progress')],
    sections: [
      GuideSection(heading: 'The chicken-and-egg problem', content: 'Fresh graduates often face a frustrating loop: you need a valid ID to get a valid ID. Most government agencies require at least one government-issued ID for registration. If you have zero IDs, where do you even start?', calloutType: CalloutType.tip, calloutText: 'Start with a Postal ID (P504, requires only a birth certificate) or PhilSys National ID (free, requires birth certificate + biometrics). These are the easiest \'starter\' IDs.'),
      GuideSection(heading: 'The recommended order', content: 'Based on ease of acquisition and usefulness, here\'s the optimal order to get your IDs:', items: ['1. PhilSys National ID — free, lifetime validity, biometric-linked, accepted everywhere once fully rolled out', '2. TIN (BIR) — required before employment. Your employer can process this for you via Form 1902', '3. SSS Number — mandatory for employment. Register online at my.sss.gov.ph', '4. PhilHealth — mandatory. Employer enrolls you, or self-register at PhilHealth office', '5. Pag-IBIG MID — mandatory. Register at Virtual Pag-IBIG or any branch', '6. Postal ID — backup ID, P504, available at any post office', '7. UMID — combines SSS/PhilHealth/Pag-IBIG into one card. Apply after 1+ SSS contribution', '8. Passport — most powerful ID. Apply at DFA (P950 regular, P1,200 expedited)']),
      GuideSection(heading: 'Documents you need for almost everything', content: 'Keep certified true copies of these documents ready. You\'ll need them repeatedly across all government applications:', items: ['PSA Birth Certificate (order at psaserbilis.com.ph, P365)', 'Two 1x1 and two 2x2 ID photos (white background)', 'Proof of address (barangay certificate, utility bill, or rent contract)', 'Any existing valid government ID (for subsequent applications)']),
      GuideSection(heading: 'Common pitfalls to avoid', content: 'Government ID processes in the Philippines have known friction points. Here\'s how to navigate them:', items: ['NBI Clearance \'hits\': Common Filipino surnames trigger false positives. Bring extra valid IDs and be prepared to return for verification', 'DFA passport appointments: Slots fill up fast. Book 2–3 weeks ahead on dfa.gov.ph. Avoid fixers — it\'s a criminal offense', 'Multiple TINs: Having more than one TIN is illegal (up to P1,000 fine and/or imprisonment). If your employer issues you a new TIN, inform BIR immediately to merge records', 'SSS/PhilHealth/Pag-IBIG portals: These go down frequently. Try during off-peak hours (early morning or late evening)'], calloutType: CalloutType.warning, calloutText: 'Never surrender your original PSA birth certificate. Government agencies only need to see the original — they should accept a photocopy for their records.'),
      GuideSection(heading: 'Track your progress', content: 'Use the Adulting Checklist in Sandalan to track which IDs you\'ve obtained and which are still pending. Each ID is marked with a priority level — start with the \'Must Do\' items and work your way down.'),
    ],
  ),
  Guide(
    slug: 'your-first-budget',
    title: 'Your First Budget (That Actually Works)',
    description: 'Forget the 50/30/20 rule. Here\'s a budgeting approach designed for Filipino realities — from \'petsa de peligro\' to family obligations.',
    category: 'financial-literacy',
    readMinutes: 5,
    toolLinks: [ToolLink(href: '/budgets', label: 'Set Up Your Budget'), ToolLink(href: '/transactions', label: 'Track Expenses')],
    sections: [
      GuideSection(heading: 'Why most budgets fail for Filipinos', content: 'The popular 50/30/20 rule (50% needs, 30% wants, 20% savings) was designed for Western households. It doesn\'t account for Filipino realities: family obligations (utang na loob), irregular income, the \'petsa de peligro\' cycle, and the cultural expectation that breadwinners support extended family. Let\'s build a budget that actually works.'),
      GuideSection(heading: 'The Filipino 4-Bucket System', content: 'Instead of percentages, think in four buckets that you fill in priority order every payday:', items: ['Bucket 1 — SURVIVE (fixed costs): Rent, utilities, food, transport, phone/internet. These are non-negotiable. Know this number exactly.', 'Bucket 2 — PROTECT (savings & insurance): Emergency fund, SSS/PhilHealth/Pag-IBIG (if voluntary), insurance premiums. Pay yourself second, not last.', 'Bucket 3 — SUPPORT (family obligations): Monthly padala to parents, sibling tuition, family emergencies. Set a fixed amount you can actually afford — don\'t give until you\'re broke.', 'Bucket 4 — LIVE (everything else): Social, dating, hobbies, shopping, subscriptions. Whatever\'s left after the first three buckets.'], calloutType: CalloutType.tip, calloutText: 'The magic is in the order. Most Filipinos do Survive → Support → Live → (nothing left for) Protect. Flip the script: Survive → Protect → Support → Live.'),
      GuideSection(heading: 'Beating \'petsa de peligro\'', content: 'The \'danger payday\' cycle happens when you spend freely after payday and scrape by before the next one. The fix: divide your monthly budget by 2 (for bi-monthly paydays) or 4 (for weekly budgeting). Allocate your four buckets per pay period, not per month. This way you never have a \'feast or famine\' cycle.'),
      GuideSection(heading: 'Start tracking today', content: 'You don\'t need a perfect budget on day one. Start by tracking every peso for 30 days — just record what you spend. After one month, you\'ll know exactly where your money goes. Then set realistic budget limits based on actual data, not guesses.', items: ['Log every expense in Sandalan (even P20 jeepney fares)', 'After 30 days, review your spending by category', 'Set budget limits in the Budgets tab based on your actual patterns', 'Adjust monthly until you find a rhythm that works for your income']),
    ],
  ),
  Guide(
    slug: 'understanding-deductions',
    title: 'Where Does My Salary Go?',
    description: 'A visual guide to every peso deducted from your paycheck — SSS, PhilHealth, Pag-IBIG, and taxes explained simply.',
    category: 'financial-literacy',
    readMinutes: 4,
    toolLinks: [ToolLink(href: '/tools/contributions', label: 'Salary & Deductions Calculator'), ToolLink(href: '/tools/contributions', label: 'Contributions Tracker')],
    sections: [
      GuideSection(heading: 'It\'s not just deductions — it\'s your safety net', content: 'Most fresh grads see salary deductions as money taken away. In reality, these deductions build your personal safety net: retirement income, health coverage, housing eligibility, and emergency loans. Think of them as forced savings managed by the government on your behalf.'),
      GuideSection(heading: 'Sample breakdown: P25,000 monthly salary', content: 'Here\'s what happens to a P25,000 gross monthly salary for a regular employee:', items: ['SSS (employee share): ~P1,125 — funds your pension, loans, maternity/sickness benefits', 'PhilHealth (employee share): ~P625 — covers hospitalization and outpatient care', 'Pag-IBIG (employee share): P200 — housing loans and MP2 savings eligibility', 'Withholding tax: ~P416 — income tax on earnings above P20,833/month', 'Total deductions: ~P2,366', 'Net take-home: ~P22,634'], calloutType: CalloutType.info, calloutText: 'Your employer also contributes on top of your deductions: ~P2,250 for SSS, ~P625 for PhilHealth, and P200 for Pag-IBIG. Your total compensation is actually higher than your gross salary.'),
      GuideSection(heading: 'What you get back', content: 'These aren\'t just costs — they\'re benefits you can claim:', items: ['SSS: Retirement pension (after 120 months of contributions), salary loan (up to 2x monthly salary), maternity leave pay, sickness benefit', 'PhilHealth: Hospital bill coverage through case rates, outpatient consultations, Z-benefits for cancer and other conditions', 'Pag-IBIG: Housing loan at 5.75% (after 24 contributions), multi-purpose loan, MP2 savings at 6–7% tax-free dividends', 'Income tax: Funds public services — roads, schools, healthcare. Under TRAIN Law, the first P250,000/year is tax-free']),
      GuideSection(heading: 'Verify your deductions', content: 'Don\'t blindly trust your payslip. Use the Gov\'t Contributions calculator to check if your deductions are computed correctly. Then log your contributions monthly to catch any discrepancies early — some employers deduct but fail to remit to SSS/PhilHealth/Pag-IBIG.'),
    ],
  ),
];

// ─── PUNDASYON (4 guides) ─────────────────────────────────────────────────────

const _pundasyonGuides = [
  Guide(slug: 'emergency-fund-101', title: 'Emergency Fund 101', description: '60.7% of Filipinos can\'t cover a P20,000 emergency. Here\'s how to build your safety net — even on a tight salary.', category: 'financial-literacy', readMinutes: 5, toolLinks: [ToolLink(href: '/goals', label: 'Set Emergency Fund Goal')], sections: [
    GuideSection(heading: 'Why you need one before anything else', content: 'An emergency fund is money set aside for the unexpected: a medical bill, job loss, broken phone, or urgent family need. Without one, any surprise expense forces you into debt — credit cards at 24–36% interest, 5-6 loans from coworkers, or predatory lending apps. Building an emergency fund is the single most important financial step you can take.', calloutType: CalloutType.warning, calloutText: '60.7% of Filipinos cannot cover a P20,000 emergency expense. Don\'t be part of that statistic.'),
    GuideSection(heading: 'How much do you need?', content: 'The standard advice is 3–6 months of essential living expenses. But start with a more achievable target:', items: ['Starter goal: P10,000–P20,000 (covers most common emergencies)', 'Minimum target: 3 months of living expenses (single, stable job)', 'Ideal target: 6 months of living expenses (freelancer, breadwinner, or dependents)', 'Formula: Monthly expenses (rent + food + transport + utilities + insurance) × target months']),
    GuideSection(heading: 'Where to keep it', content: 'Your emergency fund must be liquid (accessible within 24 hours) but not too easy to spend. Best options:', items: ['High-yield digital savings: ING (4% p.a.), CIMB (4.5%), Maya (3.5%), Tonik (4%) — no maintaining balance, PDIC-insured', 'Separate from your spending account — open a dedicated \'EF\' savings account so you don\'t accidentally spend it', 'Not in investments: Stocks, UITFs, or crypto are NOT emergency funds. They can lose value when you need them most', 'Not in time deposits: You can\'t withdraw without penalty before maturity'], calloutType: CalloutType.tip, calloutText: 'Open a separate high-yield digital bank account just for your emergency fund. Name it \'DO NOT TOUCH\' if that helps. The slight friction of transferring money out helps prevent impulse withdrawals.'),
    GuideSection(heading: 'Building it on a tight salary', content: 'Even on P15,000–P25,000/month, you can build an emergency fund. The key is automation and consistency, not large amounts:', items: ['P500/payday = P1,000/month = P12,000/year (a solid starter emergency fund)', 'P1,000/payday = P2,000/month = P24,000/year (almost 2 months\' expenses for a frugal lifestyle)', 'Set up auto-transfer from your payroll bank on payday — \'pay yourself first\' before you spend anything', 'Funnel windfalls: 13th month, bonuses, tax refunds, and monetary gifts go straight to EF until it\'s funded']),
    GuideSection(heading: 'Track your runway', content: 'Create an Emergency Fund goal in Sandalan. Set your target amount (monthly expenses × 3 or 6) and log every deposit. The goal tracker shows your progress and tells you how many months of coverage you have. Watching the bar fill up is genuinely motivating.'),
  ]),
  Guide(slug: 'investing-for-beginners', title: 'Investing 101 for Filipinos', description: 'You\'ve got your emergency fund. Now make your money work. A beginner\'s guide to MP2, UITFs, and the Philippine stock market.', category: 'investing', readMinutes: 6, toolLinks: [ToolLink(href: '/tools/calculators', label: 'Compound Interest Calculator'), ToolLink(href: '/goals', label: 'Set Investment Goal')], sections: [
    GuideSection(heading: 'When to start investing', content: 'Only invest after you have: (1) an emergency fund covering 3–6 months of expenses, (2) no high-interest debt (credit cards, lending apps), and (3) adequate insurance. Investing before these foundations are in place is like building a house on sand.', calloutType: CalloutType.warning, calloutText: 'Never invest your emergency fund. Investments can lose value. Your EF must be 100% liquid and safe.'),
    GuideSection(heading: 'The investment ladder for Filipinos', content: 'Start at the bottom (safest, lowest returns) and climb up as your knowledge and risk tolerance grow:', items: ['Rung 1 — Pag-IBIG MP2: 6–7% annual dividends, tax-free, government-backed. Minimum P500. Best guaranteed return in the Philippines. Start here.', 'Rung 2 — Money Market Funds / Bond Funds: UITFs available through BDO, BPI, UnionBank. Low risk, 3–5% returns. Minimum P1,000–P10,000.', 'Rung 3 — Balanced Funds: Mix of bonds and stocks. Moderate risk, 5–8% historical returns. Good for 3–5 year goals.', 'Rung 4 — Equity Funds / Index Funds: Invest in the Philippine stock market without picking stocks. Higher risk, 8–12% long-term returns. Minimum 5–10 year horizon.', 'Rung 5 — Direct Stock Market (PSE): Buy individual stocks through COL Financial, BDO Nomura, or First Metro. Requires learning and monitoring. Only with money you won\'t need for 10+ years.']),
    GuideSection(heading: 'Pag-IBIG MP2: The best-kept secret', content: 'MP2 is a voluntary savings program from Pag-IBIG that has consistently delivered 6–7% annual dividends — completely tax-free. It\'s arguably the best guaranteed return available to any Filipino. The 5-year maturity period locks your money in, but you can withdraw dividends annually. After 5 years, you can renew or withdraw everything.', calloutType: CalloutType.tip, calloutText: 'You can enroll in MP2 through Virtual Pag-IBIG with just P500. Set up auto-debit and forget about it. In 5 years, you\'ll thank yourself.'),
    GuideSection(heading: 'The magic of compound interest', content: 'If you invest P2,000/month starting at age 23 at 7% annual returns (MP2-equivalent), you\'ll have approximately P2,400,000 by age 45 — you only contributed P528,000. The rest is compound interest. Starting 5 years later (at 28) with the same amount gives you only P1,500,000. Time is your biggest advantage.'),
    GuideSection(heading: 'Common mistakes to avoid', content: 'Filipino investors frequently make these errors:', items: ['Buying VUL (Variable Universal Life) as your \'investment\': VUL mixes insurance and investing, resulting in high fees and mediocre returns for both. Get term insurance + separate investments instead.', 'Investing based on social media tips: Don\'t buy stocks because someone on TikTok said to. Do your own research.', 'Panic selling during market drops: The PSE drops 10–20% regularly. If you\'re investing for 10+ years, downturns are buying opportunities.', 'Not diversifying: Don\'t put everything in one stock or one investment type. Spread across MP2, UITFs, and equities.']),
  ]),
  Guide(slug: 'credit-building', title: 'Building Your Credit Score', description: 'Good credit unlocks lower interest rates on loans and credit cards. Here\'s how the Philippine credit system works and how to build yours.', category: 'financial-literacy', readMinutes: 4, toolLinks: [ToolLink(href: '/tools/debts', label: 'Debt Manager')], sections: [
    GuideSection(heading: 'Philippine credit scores explained', content: 'The Credit Information Corporation (CIC) maintains credit records for all Filipinos. Your score ranges from 300–850. Banks and lenders check this score when you apply for credit cards, personal loans, home loans, and car loans. A score above 700 is considered good for approval with favorable rates.'),
    GuideSection(heading: 'How to check your score', content: 'You can check your CIC credit score for free twice per year using the CIC App 3.0 (available on Android and iOS). You\'ll need a valid government ID to register. Your report shows all credit accounts, payment history, and inquiries from lenders.', calloutType: CalloutType.phLaw, calloutText: 'Under Republic Act No. 9510, every Filipino has the right to access their credit information from the CIC. Lenders must report to the CIC and are required to inform you if they deny credit based on your CIC record.'),
    GuideSection(heading: 'Building credit from scratch', content: 'If you have no credit history (common for fresh graduates), here\'s how to build it:', items: ['Start with a secured credit card: Deposit P2,000–P10,000 as collateral and get a credit card with that limit. BPI, Security Bank, and RCBC offer these.', 'Use it for small, regular purchases: Groceries, gas, subscriptions. Spend 10–30% of your limit.', 'Pay the full balance every billing cycle: This costs you P0 in interest and builds a perfect payment history.', 'After 6–12 months: Apply for a regular credit card. Your payment history from the secured card will support your application.']),
    GuideSection(heading: 'The golden rules of credit', content: 'Credit is a powerful tool when used correctly, and a dangerous trap when misused:', items: ['Always pay the full balance — minimum payments trap you in 24–36% annual interest', 'Never use more than 30% of your credit limit (utilization ratio affects your score)', 'Never use credit cards for cash advances (25–30% interest + additional fees)', 'Set up auto-pay for at least the minimum payment to avoid late fees', 'Don\'t apply for multiple credit cards at once — each application creates an inquiry that temporarily lowers your score']),
  ]),
  Guide(slug: 'freelancer-tax-guide', title: 'The Filipino Freelancer Tax Guide', description: 'Freelancing? The BIR knows. Here\'s how to register, file, and potentially save money with the 8% flat tax option.', category: 'government', readMinutes: 6, toolLinks: [ToolLink(href: '/tools/taxes', label: 'BIR Tax Tracker'), ToolLink(href: '/tools/calculators', label: 'Tax Calculator')], sections: [
    GuideSection(heading: 'If you earn outside of employment, you must register', content: 'Any income from freelancing, consulting, online selling, content creation, or side businesses requires BIR registration. The BIR has been actively cracking down on unregistered digital earners and influencers. Penalties for non-compliance include 25% surcharge, 12% annual interest, and potential criminal charges going back 3–10 years.', calloutType: CalloutType.warning, calloutText: 'Saying \'I didn\'t know\' is not a defense. The BIR has filed cases against freelancers and online sellers who failed to register. Register now before you get caught.'),
    GuideSection(heading: 'How to register as a freelancer', content: 'Step-by-step BIR registration for self-employed individuals:', items: ['1. Go to your local Revenue District Office (RDO) based on your home address', '2. File BIR Form 1901 with: TIN, valid government ID, birth certificate, proof of business address', '3. Pay the P500 annual registration fee (abolished from 2025 onward) and P30 documentary stamp tax', '4. Register your books of accounts (you can buy blank books from bookstores)', '5. Get authority to print Official Receipts (OR) or use BIR\'s electronic invoicing system', '6. You\'re now registered. File quarterly and annual tax returns on time.']),
    GuideSection(heading: '8% flat tax vs graduated rates', content: 'If your annual gross receipts are P3,000,000 or below, you can choose the 8% flat income tax rate instead of the graduated rates (0–35%). The 8% rate is computed on gross receipts exceeding P250,000 (the tax-free threshold). For most freelancers earning under P3M/year, the 8% option is simpler and often cheaper.', items: ['8% flat tax: 8% × (gross receipts - P250,000). No need to track itemized expenses.', 'Graduated rates + OSD: Net income × tax bracket rate. You can deduct 40% of gross as Optional Standard Deduction.', 'Example: P500,000 gross receipts → 8% flat tax = P20,000. Graduated with OSD → P17,500. Compare both before choosing.'], calloutType: CalloutType.tip, calloutText: 'You must elect your tax option at the start of the year. Once chosen, you can\'t switch until the next tax year. Use the Tax Calculator to compare both options for your income level.'),
    GuideSection(heading: 'Filing deadlines (don\'t miss these)', content: 'Self-employed individuals must file these returns on time. Late filing incurs automatic penalties:', items: ['Quarterly Income Tax (Form 1701Q): May 15, August 15, November 15', 'Annual Income Tax (Form 1701): April 15', 'Quarterly Percentage Tax (Form 2551Q): April 25, July 25, October 25, January 25 — only if NOT using 8% flat tax', 'You must file even if you had zero income for the quarter']),
  ]),
];

// ─── TAHANAN (4 guides) ───────────────────────────────────────────────────────

const _tahananGuides = [
  Guide(slug: 'pagibig-housing-loan', title: 'Pag-IBIG Housing Loan Step-by-Step', description: 'The most affordable path to homeownership in the Philippines. Everything you need to know about qualifying, applying, and getting approved.', category: 'housing', readMinutes: 7, toolLinks: [ToolLink(href: '/tools/rent-vs-buy', label: 'Rent vs Buy Calculator'), ToolLink(href: '/tools/contributions', label: 'Check Pag-IBIG Contributions')], sections: [
    GuideSection(heading: 'Why Pag-IBIG is your best option', content: 'Pag-IBIG offers housing loans at 5.75% annual interest — roughly half the rate of commercial bank loans (7–10%). Maximum loan amount is P6,000,000 with a term of up to 30 years. This makes monthly amortization significantly lower than bank alternatives.'),
    GuideSection(heading: 'Eligibility requirements', content: 'To qualify for a Pag-IBIG housing loan, you need:', items: ['At least 24 monthly Pag-IBIG contributions (not necessarily consecutive)', 'Not over 65 years old at the time of application', 'No outstanding Pag-IBIG housing loan', 'Legal capacity to acquire property', 'Adequate income to cover amortization (debt-to-income ratio assessed)'], calloutType: CalloutType.tip, calloutText: 'Start tracking your Pag-IBIG contributions now. After 24 months, you\'re eligible. The Contributions Tracker shows exactly how many months you have.'),
    GuideSection(heading: 'Required documents', content: 'Prepare these before visiting the Pag-IBIG office:', items: ['Housing Loan Application Form', 'Two valid government IDs', 'Proof of income: payslips (3 months), ITR, Certificate of Employment', 'Pag-IBIG loyalty card or MID number', 'Transfer Certificate of Title (TCT) or Condominium Certificate of Title (CCT)', 'Current real estate tax receipt and tax declaration', 'Vicinity map and lot plan of the property']),
    GuideSection(heading: 'Sample computation', content: 'For a P2,000,000 property with 10% down payment and a 20-year loan at 5.75%:', items: ['Loan amount: P1,800,000', 'Monthly amortization: ~P12,636', 'Total amount paid over 20 years: ~P3,032,640', 'Compare with bank loan at 8%: monthly amortization ~P15,053 (P2,417 more per month)']),
  ]),
  Guide(slug: 'insurance-layering', title: 'PhilHealth vs HMO vs Private Insurance', description: 'The three-layer health protection system explained. Know what each one covers so you\'re never caught off guard by a hospital bill.', category: 'insurance', readMinutes: 5, toolLinks: [ToolLink(href: '/tools/insurance', label: 'Insurance Tracker')], sections: [
    GuideSection(heading: 'The three layers of protection', content: 'Filipino healthcare coverage works in three layers. Each serves a different purpose — ideally, you have all three:', items: ['Layer 1 — PhilHealth (mandatory): Government insurance covering inpatient hospitalization, outpatient care, and selected procedures through case rates. Everyone should have this.', 'Layer 2 — HMO (employer-provided or personal): Prepaid healthcare covering outpatient consultations, lab tests, ER visits, and dental. Faster service through accredited clinics and hospitals.', 'Layer 3 — Private Health Insurance: Long-term coverage for critical illness, hospitalization gaps, and conditions HMO doesn\'t cover. Complements the first two layers.']),
    GuideSection(heading: 'What PhilHealth actually covers', content: 'PhilHealth covers specific amounts per diagnosis (case rate system). It does NOT cover the full hospital bill in most cases. You pay the difference. Recent 2025 expansions increased coverage significantly for heart disease, kidney transplant, and dental care.', calloutType: CalloutType.phLaw, calloutText: 'Under the Universal Health Care Act (RA 11223), all Filipinos are automatically enrolled in PhilHealth. You have the right to PhilHealth coverage regardless of employment status.'),
    GuideSection(heading: 'When to get an HMO', content: 'If your employer offers an HMO, always enroll — it\'s usually free or heavily subsidized. For self-employed individuals, personal HMO plans start at P3,000–P8,000/year for basic coverage. An HMO is worth it if you visit doctors, get lab tests, or need emergency care more than 2–3 times per year.'),
    GuideSection(heading: 'Choosing the right insurance mix', content: 'Your ideal coverage depends on your life stage:', items: ['Single, employed: PhilHealth + company HMO (both usually free)', 'Self-employed: PhilHealth (mandatory) + personal HMO (P3K–P8K/year)', 'Married with kids: PhilHealth + HMO with family plan + term life insurance', 'Breadwinner: All three layers plus disability insurance']),
  ]),
  Guide(slug: 'marriage-finances', title: 'Marriage Finances in the Philippines', description: 'From wedding costs to joint budgets. A practical financial guide for Filipino couples planning to get married.', category: 'financial-literacy', readMinutes: 5, toolLinks: [ToolLink(href: '/budgets', label: 'Set Up Joint Budget')], sections: [
    GuideSection(heading: 'The real cost of getting married in the Philippines', content: 'A Filipino wedding costs anywhere from P50,000 (civil ceremony + simple reception) to P1,000,000+ (church wedding + hotel reception + entourage). The average sits around P200,000–P400,000. Before you start planning the event, plan the finances.', items: ['Civil wedding: P500–P2,000 (fees only) + reception budget', 'Church wedding: P5,000–P30,000 (church fees, flowers, choir)', 'Reception: P50,000–P500,000 (depends on venue and guest count)', 'Rings, attire, photos, video: P30,000–P150,000', 'Marriage license and requirements: ~P500–P1,500']),
    GuideSection(heading: 'Financial conversations to have before marriage', content: 'Money is the #1 cause of marital conflict. Have these conversations before the wedding:', items: ['Full disclosure: Share all debts, savings, income, and financial obligations', 'Family obligations: How much will each of you continue to give to parents/siblings?', 'Joint vs separate accounts: Most Filipino couples benefit from \'yours, mine, and ours\' — three accounts', 'Financial goals: Align on priorities (house, kids, retirement, travel)', 'Budget system: Agree on how you\'ll manage monthly spending together'], calloutType: CalloutType.tip, calloutText: 'Open a joint account for shared expenses (rent, bills, groceries) while keeping individual accounts for personal spending. This reduces friction while maintaining autonomy.'),
    GuideSection(heading: 'Legal financial implications', content: 'Under Philippine law, marriage creates an Absolute Community of Property (ACP) regime by default — meaning all property acquired during the marriage is owned jointly. To opt out, you need a prenuptial agreement signed before the wedding.', calloutType: CalloutType.phLaw, calloutText: 'Under the Family Code of the Philippines, the default property regime is Absolute Community of Property. A prenuptial agreement (ante-nuptial contract) must be executed before the marriage ceremony.'),
  ]),
  Guide(slug: 'education-fund', title: 'Starting a Children\'s Education Fund', description: 'Private school tuition rises 8–12% annually. Here\'s how to start saving early so education costs don\'t crush your finances.', category: 'financial-literacy', readMinutes: 4, toolLinks: [ToolLink(href: '/goals', label: 'Set Education Fund Goal'), ToolLink(href: '/tools/calculators', label: 'Compound Interest Calculator')], sections: [
    GuideSection(heading: 'The numbers are staggering', content: 'Private university tuition in the Philippines ranges from P200,000–P500,000/year. With 8–12% annual increases, a child born today could face P800,000+/year by the time they enter college. Public universities are cheaper but competitive — don\'t count on them as your only option.'),
    GuideSection(heading: 'When to start', content: 'The answer is always \'now.\' A P3,000/month investment at 7% returns starting at your child\'s birth grows to approximately P1,200,000 by the time they\'re 18. Starting when they\'re 6 gives you only about P600,000 with the same contribution. Time is the biggest factor.', items: ['From birth: P3,000/month at 7% = ~P1.2M by age 18', 'From age 6: P3,000/month at 7% = ~P600K by age 18', 'From age 12: P3,000/month at 7% = ~P250K by age 18']),
    GuideSection(heading: 'Best investment vehicles for education funds', content: 'Match the investment to your timeline:', items: ['18+ years away: Equity index funds, UITFs (aggressive growth)', '10–17 years away: Balanced funds (mix of stocks and bonds)', '5–9 years away: Bond funds, Pag-IBIG MP2', 'Under 5 years: High-yield savings, time deposits (capital preservation)'], calloutType: CalloutType.warning, calloutText: 'Avoid \'education plans\' from insurance companies. They often have high fees, low returns, and inflexible terms. You\'re better off investing directly in UITFs or MP2.'),
  ]),
];

// ─── TUGATOG (3 guides) ──────────────────────────────────────────────────────

const _tugatogGuides = [
  Guide(slug: 'wealth-building', title: 'Building Wealth in Your Peak Years', description: 'Your 30s and 40s are when income is highest. Here\'s how to make the most of your peak earning years.', category: 'investing', readMinutes: 5, toolLinks: [ToolLink(href: '/tools/calculators', label: 'Compound Interest Calculator'), ToolLink(href: '/tools/retirement', label: 'Retirement Projection')], sections: [
    GuideSection(heading: 'Why your peak years matter most', content: 'Ages 36–45 are typically your highest-earning years. The financial decisions you make now determine whether you retire comfortably or struggle. By this stage, you should have your emergency fund, insurance, and basic investments in place. Now it\'s time to accelerate.'),
    GuideSection(heading: 'Diversification is key', content: 'Don\'t put all your eggs in one basket. A balanced portfolio for your peak years might look like:', items: ['30% — Low risk: Pag-IBIG MP2, government bonds, money market funds', '40% — Medium risk: Balanced UITFs, blue-chip dividend stocks, REITs', '20% — Higher risk: Equity index funds, growth stocks', '10% — Alternative: Real estate, small business, or other income-generating assets']),
    GuideSection(heading: 'Financial milestones to hit', content: 'By age 45, aim to have achieved these milestones:', items: ['Retirement savings: 2–4x your annual income accumulated', 'Emergency fund: 6+ months of expenses (fully funded)', 'Insurance: Adequate life, health, and property coverage', 'Debt: No high-interest consumer debt remaining', 'Children\'s education fund: Started and growing', 'Estate plan: Basic will and beneficiary designations updated']),
  ]),
  Guide(slug: 'mid-career-review', title: 'Mid-Career Financial Review', description: 'A comprehensive checklist for your 30s and 40s. Are you on track? Here\'s what to evaluate.', category: 'financial-literacy', readMinutes: 4, toolLinks: [ToolLink(href: '/tools/retirement', label: 'Retirement Projection'), ToolLink(href: '/tools/insurance', label: 'Insurance Tracker')], sections: [
    GuideSection(heading: 'The mid-career checkpoint', content: 'By your mid-30s to 40s, you should have a clear picture of your financial trajectory. This isn\'t about being perfect — it\'s about knowing where you stand and adjusting course before it\'s too late.'),
    GuideSection(heading: 'Annual financial review checklist', content: 'Go through this every year:', items: ['Net worth: Calculate total assets minus total liabilities. Is it growing year over year?', 'Emergency fund: Still fully funded at 6 months? Top up if you\'ve used it', 'Insurance: Coverage still adequate for your dependents? Update beneficiaries', 'Retirement savings: On track for 2–4x annual income by age 45?', 'Debt: Any high-interest debt remaining? Prioritize payoff', 'Estate plan: Will and beneficiaries up to date?', 'SSS contributions: Maximized MSC bracket? Check contribution history for gaps']),
    GuideSection(heading: 'Common mid-career money traps', content: 'Avoid these patterns that derail peak-earner finances:', items: ['Lifestyle creep: Income rises but so does spending. Keep your \'survive\' bucket fixed', 'Over-reliance on single income: Build passive income streams (dividends, rental, MP2)', 'Neglecting health: Medical costs compound. Annual checkups are cheaper than hospital stays', 'Delaying retirement planning: Every year you wait costs exponentially more to catch up']),
  ]),
  Guide(slug: 'health-planning', title: 'Health Planning for Your Peak Years', description: 'Chronic conditions start appearing in your 30s-40s. Here\'s how to protect your health and your wallet.', category: 'health', readMinutes: 4, toolLinks: [ToolLink(href: '/tools/insurance', label: 'Insurance Tracker')], sections: [
    GuideSection(heading: 'Prevention is cheaper than treatment', content: 'The leading causes of death in the Philippines — heart disease, stroke, diabetes, cancer — are largely preventable or manageable with early detection. A P5,000 annual checkup is infinitely cheaper than a P500,000 hospital bill.'),
    GuideSection(heading: 'Essential annual health checkups', content: 'Starting at age 35, get these done yearly:', items: ['Complete blood count (CBC) and blood chemistry (glucose, cholesterol, uric acid)', 'Blood pressure monitoring (hypertension affects 1 in 4 Filipino adults)', 'Chest X-ray and ECG (heart screening)', 'Urinalysis and fecalysis', 'Eye exam (especially if you work on screens all day)', 'Dental cleaning and checkup', 'Women: Pap smear and breast exam. Men: PSA test after age 40']),
    GuideSection(heading: 'Healthcare cost management', content: 'Layer your protection to minimize out-of-pocket costs:', items: ['PhilHealth: Use Konsulta package for free outpatient primary care at accredited facilities', 'HMO: Maximize your company HMO for consultations, labs, and prescriptions', 'Critical illness insurance: Consider adding a rider if you have dependents', 'Health savings: Set aside P2,000–P5,000/month specifically for health expenses']),
  ]),
];

// ─── PAGHAHANDA (4 guides) ───────────────────────────────────────────────────

const _paghahandaGuides = [
  Guide(slug: 'maximize-sss-pension', title: 'Maximizing Your SSS Pension', description: 'The average SSS pension is P6,000–P7,000/month — far below living costs. Here\'s how to optimize your contributions for a higher pension.', category: 'retirement', readMinutes: 5, toolLinks: [ToolLink(href: '/tools/retirement', label: 'Retirement Projection'), ToolLink(href: '/tools/contributions', label: 'Contributions Tracker')], sections: [
    GuideSection(heading: 'How SSS pension is calculated', content: 'Your SSS monthly pension is based on three factors: your Average Monthly Salary Credit (AMSC), the number of credited years of service (CYS), and the pension formula. The formula is: P300 + 20% of AMSC + (2% of AMSC × CYS beyond 10 years). Higher AMSC and more years of contribution mean a higher pension.'),
    GuideSection(heading: 'Strategies to increase your pension', content: 'You can take action now to significantly boost your retirement income:', items: ['Maximize your Monthly Salary Credit: Contribute at the highest MSC bracket possible (up to P35,000)', 'Don\'t have gaps: Every month without a contribution is a missed opportunity. Voluntary members can pay during unemployment', 'Contribute for as long as possible: The minimum is 120 months (10 years), but 30+ years of contributions dramatically increases your pension', 'Consider voluntary contributions above the mandatory: The MySSS Pension Booster takes contributions above P20,000 MSC'], calloutType: CalloutType.tip, calloutText: 'Use the Retirement Projection tool to see how increasing your MSC or adding more years of contributions affects your estimated pension.'),
    GuideSection(heading: 'SSS pension alone is not enough', content: 'Even at the maximum pension, SSS will not cover a comfortable retirement. You need supplementary income from personal savings, investments (MP2, UITFs, stocks), rental income, or a small business. Start planning your retirement income sources now — don\'t wait until you\'re 60.'),
  ]),
  Guide(slug: 'sandwich-generation', title: 'Surviving the Sandwich Generation', description: 'Supporting aging parents and growing children simultaneously. A financial and emotional survival guide for Filipino breadwinners.', category: 'family', readMinutes: 5, toolLinks: [ToolLink(href: '/tools/panganay', label: 'Panganay Mode'), ToolLink(href: '/budgets', label: 'Set Up Family Budget')], sections: [
    GuideSection(heading: 'You\'re not alone', content: 'A rising number of Filipinos belong to the sandwich generation — supporting aging parents while also raising their own children. Philippine culture makes this uniquely intense: filial duty (utang na loob), limited social safety nets, and insufficient SSS pensions mean the financial burden falls squarely on working adults.'),
    GuideSection(heading: 'Setting boundaries without guilt', content: 'Supporting family doesn\'t mean sacrificing your own financial future. You can\'t help others from a position of financial ruin:', items: ['Set a fixed monthly amount for family support — communicate it clearly and stick to it', 'Protect your emergency fund and retirement savings first — these are non-negotiable', 'Help siblings become self-sufficient rather than perpetuating dependency', 'It\'s okay to say no to extended family requests that would put you in debt', 'Use Panganay Mode in Sandalan to track family obligations separately from personal spending'], calloutType: CalloutType.info, calloutText: 'Setting financial boundaries is not selfishness — it\'s sustainability. You can\'t give from an empty cup.'),
    GuideSection(heading: 'Practical budgeting for sandwich generation', content: 'Use the 4-bucket system adapted for your situation:', items: ['Bucket 1 — Your household: Rent, utilities, food, transport, children\'s needs', 'Bucket 2 — Your protection: Emergency fund, retirement, insurance', 'Bucket 3 — Parent support: Fixed monthly amount for parents\' needs', 'Bucket 4 — Everything else: Personal spending, wants, treats']),
  ]),
  Guide(slug: 'estate-planning-basics', title: 'Estate Planning Basics for Filipinos', description: 'Wills, beneficiaries, and estate tax. Protect your family from legal headaches and financial loss.', category: 'retirement', readMinutes: 5, toolLinks: [ToolLink(href: '/guide/paghahanda', label: 'View Stage Progress')], sections: [
    GuideSection(heading: 'Why you need an estate plan now', content: 'Most Filipinos think estate planning is only for the wealthy. It\'s not. If you own any property, have savings, or have dependents, you need a basic estate plan. Without one, your assets get tied up in courts for years, family disputes arise, and the government takes 6% estate tax before your heirs see a peso.'),
    GuideSection(heading: 'The basics: will types in the Philippines', content: 'Philippine law recognizes two types of wills:', items: ['Notarial will: Typed or printed, signed by you and 3 witnesses, notarized. Most common and safest option. Cost: P3,000–P8,000 with a lawyer.', 'Holographic will: Entirely handwritten by you, dated, and signed. No witnesses or notarization needed. Free but can be contested more easily.'], calloutType: CalloutType.phLaw, calloutText: 'The Philippines follows forced heirship (legitimes). You cannot disinherit legitimate children, your spouse, or parents from their legal share. A will distributes the \'free portion\' of your estate — typically 25–50% depending on surviving heirs.'),
    GuideSection(heading: 'Estate tax: the 6% rule', content: 'The estate tax in the Philippines is a flat 6% of the net estate (total assets minus deductions like debts, funeral expenses, and the standard deduction of P5,000,000). The estate tax return must be filed within 1 year of death. Failure to file incurs 25% surcharge + 12% annual interest.'),
    GuideSection(heading: 'Action items you can do today', content: 'Estate planning doesn\'t require a lawyer on day one. Start with these steps:', items: ['Update all beneficiaries: SSS (Form E-4), Pag-IBIG (MDF), bank accounts, insurance policies', 'Create an asset inventory: List all bank accounts, investments, properties, and valuable items', 'Organize documents: Keep titles, insurance policies, and financial records in one secure place', 'Tell a trusted person: At minimum, one family member should know where your documents are', 'Consider a holographic will: It\'s free, legally valid, and takes 30 minutes to write']),
  ]),
  Guide(slug: 'debt-free-before-retirement', title: 'Paying Off All Debt Before Retirement', description: 'Entering retirement with debt is dangerous. Here\'s how to accelerate debt payoff in your 40s and 50s.', category: 'financial-literacy', readMinutes: 4, toolLinks: [ToolLink(href: '/tools/debts', label: 'Debt Manager')], sections: [
    GuideSection(heading: 'Why debt-free retirement matters', content: 'Your SSS pension will likely be P6,000–P12,000/month. If you\'re still paying P8,000/month on a housing loan and P3,000/month on credit cards, your pension is consumed before you buy groceries. The goal: zero debt by age 60.'),
    GuideSection(heading: 'Debt payoff strategies', content: 'Two proven approaches:', items: ['Avalanche method: Pay minimums on all debts, throw extra money at the highest-interest debt first. Mathematically optimal — saves the most on interest.', 'Snowball method: Pay minimums on all debts, throw extra money at the smallest balance first. Psychologically motivating — you see debts disappear faster.', 'Either method works. Pick the one you\'ll stick with. Consistency beats optimization.']),
    GuideSection(heading: 'Accelerating payoff in your 40s-50s', content: 'Strategies specific to this life stage:', items: ['Redirect 13th month pay and bonuses to debt payoff', 'If children are independent, redirect their education fund contributions to debt', 'Consider refinancing high-interest loans (credit cards at 24% → personal loan at 12%)', 'Use the Debt Manager tool to track balances and visualize your payoff timeline', 'Avoid taking on new debt — no new car loans or credit cards'], calloutType: CalloutType.warning, calloutText: 'Never borrow from your retirement savings or emergency fund to pay off debt. That trades one problem for a worse one.'),
  ]),
];

// ─── GINTONG TAON (3 guides) ─────────────────────────────────────────────────

const _gintongTaonGuides = [
  Guide(slug: 'senior-citizen-benefits', title: 'Senior Citizen Benefits Complete Guide', description: 'Every discount, exemption, and benefit available to Filipino seniors under Republic Act 9994.', category: 'retirement', readMinutes: 5, sections: [
    GuideSection(heading: 'Who qualifies', content: 'Filipino citizens aged 60 and above are considered senior citizens under the law. To access benefits, you need a Senior Citizen ID issued by the Office for Senior Citizens Affairs (OSCA) in your city or municipality. Registration is free.'),
    GuideSection(heading: 'Mandatory discounts', content: 'Senior citizens are entitled to a 20% discount and VAT exemption on:', items: ['Medicines, vitamins, and medical supplies in all drugstores', 'Medical and dental services, diagnostic fees, and professional fees', 'Public transportation (bus, jeepney, MRT, LRT, PNR)', 'Hotels, restaurants, and recreation centers', 'Funeral and burial services', 'Admission to theaters, concert halls, and amusement parks'], calloutType: CalloutType.phLaw, calloutText: 'These discounts are mandatory under Republic Act 9994 (Expanded Senior Citizens Act of 2010). Establishments that refuse to honor them can be fined P50,000 for first offense.'),
    GuideSection(heading: 'Social pension for indigent seniors', content: 'The DSWD provides a monthly social pension of P1,000 to indigent senior citizens — those without regular income, pension, or permanent source of financial support. Apply through your barangay or city social welfare office.'),
    GuideSection(heading: 'SSS and GSIS pension claims', content: 'If you\'ve completed the required contributions, file your retirement claim:', items: ['SSS: Optional retirement at age 60 (must stop working), mandatory at 65. Minimum 120 monthly contributions required.', 'GSIS: For government employees. File through your agency HR or the nearest GSIS branch.', 'Keep your records: Contribution history, employment records, and valid IDs ready for the claims process.']),
  ]),
  Guide(slug: 'healthcare-retirement', title: 'Healthcare Management in Retirement', description: 'Medical costs are the biggest threat to retirement savings. Here\'s how to manage healthcare expenses as a senior citizen.', category: 'health', readMinutes: 4, toolLinks: [ToolLink(href: '/tools/insurance', label: 'Insurance Tracker')], sections: [
    GuideSection(heading: 'Healthcare costs in retirement', content: 'Healthcare is typically the largest expense for Filipino retirees. Out-of-pocket health spending accounts for 42.7% of total healthcare costs in the Philippines. Without proper coverage, a single hospitalization can wipe out years of savings.'),
    GuideSection(heading: 'Maximizing PhilHealth as a retiree', content: 'As a retiree, you can maintain PhilHealth coverage:', items: ['Lifetime member: If you\'ve contributed for 120 months, you qualify for lifetime coverage', 'Senior citizen PhilHealth: Automatic coverage under the Universal Health Care Act', 'Konsulta package: Free outpatient primary care at accredited health centers', 'New 2025 benefits: Expanded coverage for heart disease, kidney transplant, dental, and emergency care']),
    GuideSection(heading: 'Building a healthcare fund', content: 'Beyond PhilHealth, set aside dedicated funds for medical expenses not covered by insurance. A healthcare fund of P200,000–P500,000 provides a buffer for emergencies, medications, and procedures that PhilHealth doesn\'t fully cover.', calloutType: CalloutType.tip, calloutText: 'Keep your healthcare fund in a high-yield savings account (not invested). You need it liquid and accessible for emergencies.'),
  ]),
  Guide(slug: 'passing-wealth', title: 'Passing Wealth to the Next Generation', description: 'How to transfer assets smoothly, minimize estate tax, and prevent family disputes.', category: 'retirement', readMinutes: 4, sections: [
    GuideSection(heading: 'Planning the transfer', content: 'Wealth transfer in the Philippines is governed by the Civil Code\'s rules on succession. Whether you have P100,000 or P10,000,000, how you transfer it matters — both for tax efficiency and family harmony.'),
    GuideSection(heading: 'Strategies for smooth transfer', content: 'Consider these approaches:', items: ['Write a will: Even a holographic (handwritten) will prevents intestate succession disputes', 'Update beneficiaries: SSS, Pag-IBIG, bank accounts, insurance — review annually', 'Consider living donations: You can donate up to P250,000/year tax-free to each child', 'Insurance as estate tool: A life insurance payout goes directly to beneficiaries, bypassing estate settlement', 'Organize documentation: Land titles, vehicle registration, bank records — make them easily accessible']),
    GuideSection(heading: 'Avoiding common pitfalls', content: 'These mistakes cause the most pain for Filipino families:', items: ['No will: Assets get divided by intestate law, which may not match your wishes', 'Verbal promises: \'I told my anak they\'d get the house\' has no legal weight without documentation', 'Co-mingled property: Assets with unclear ownership create disputes. Keep titles and records clean', 'Ignoring estate tax: The 6% estate tax must be paid before assets can be transferred. Plan for it'], calloutType: CalloutType.phLaw, calloutText: 'Under Philippine law, legitimate children, the surviving spouse, and (in some cases) parents are compulsory heirs who cannot be disinherited from their legal share (legitime).'),
  ]),
];

// ─── Checklist Items ──────────────────────────────────────────────────────────

const kChecklistItems = <String, ChecklistItem>{
  // Unang Hakbang
  'tin': ChecklistItem(
    id: 'tin', title: 'Get your TIN', priority: 'high',
    description: 'Your Tax Identification Number (TIN) is required for employment, banking, and government transactions. Apply at BIR or through your employer.',
    fee: 'Free', processingTime: '1–3 days',
    steps: ['Prepare valid IDs and birth certificate', 'Visit your nearest BIR Revenue District Office (RDO)', 'Fill out BIR Form 1901 (self-employed) or 1902 (employed)', 'Submit and wait for your TIN to be issued'],
  ),
  'sss': ChecklistItem(
    id: 'sss', title: 'Register with SSS', priority: 'high',
    description: 'Social Security System membership gives you salary loans, sickness/maternity benefits, disability, retirement pension, and death benefits.',
    fee: 'Free', processingTime: '1 day',
    steps: ['Go to sss.gov.ph and create an account', 'Fill out the online registration form', 'Visit an SSS branch to verify your identity', 'Start contributing (employer deducts automatically if employed)'],
  ),
  'philhealth': ChecklistItem(
    id: 'philhealth', title: 'Register with PhilHealth', priority: 'high',
    description: 'PhilHealth provides health insurance coverage for hospitalization, outpatient care, and other medical services.',
    fee: 'Free', processingTime: '1 day',
    steps: ['Visit the nearest PhilHealth office or register online', 'Fill out the PhilHealth Member Registration Form (PMRF)', 'Submit valid IDs and documents', 'Get your PhilHealth ID number'],
  ),
  'pagibig': ChecklistItem(
    id: 'pagibig', title: 'Register with Pag-IBIG', priority: 'high',
    description: 'Pag-IBIG Fund provides housing loans, savings programs (MP2), and multi-purpose loans for members.',
    fee: 'Free', processingTime: '1 day',
    steps: ['Go to pagibigfundservices.com and register online', 'Fill out the Member\'s Data Form (MDF)', 'Visit a Pag-IBIG branch for verification if needed', 'Start contributions through your employer'],
  ),
  'philsys': ChecklistItem(
    id: 'philsys', title: 'Get your PhilSys National ID', priority: 'high',
    description: 'The Philippine Identification System (PhilSys) ID is a government-issued ID valid for all transactions.',
    fee: 'Free', processingTime: '2–4 weeks',
    steps: ['Pre-register online at register.philsys.gov.ph', 'Book an appointment at your nearest registration center', 'Bring supporting documents (birth certificate, valid ID)', 'Wait for your PhilSys ID card to be delivered'],
  ),
  'umid': ChecklistItem(
    id: 'umid', title: 'Get your UMID card', priority: 'medium',
    description: 'The Unified Multi-Purpose ID combines SSS, PhilHealth, Pag-IBIG, and GSIS membership in one card with ATM functionality.',
    fee: 'Free', processingTime: '2–3 months',
    steps: ['Be a registered member of SSS, GSIS, PhilHealth, or Pag-IBIG', 'Visit an SSS branch with a UMID enrollment facility', 'Fill out the application form and have biometrics captured', 'Wait for card delivery or pick up at the branch'],
  ),
  'passport': ChecklistItem(
    id: 'passport', title: 'Get your passport', priority: 'medium',
    description: 'A Philippine passport is essential for international travel and serves as a primary valid ID.',
    fee: '₱950 (regular) / ₱1,200 (rush)', processingTime: '2–6 weeks',
    steps: ['Create an account at passport.gov.ph', 'Book an appointment at a DFA office', 'Prepare birth certificate (PSA), valid ID, and payment', 'Attend your appointment for processing and biometrics'],
  ),
  'drivers-license': ChecklistItem(
    id: 'drivers-license', title: 'Get your driver\'s license', priority: 'low',
    description: 'A Philippine driver\'s license from LTO allows you to legally drive and serves as a valid government ID.',
    fee: '₱585–₱1,185', processingTime: '1 day (exam + release)',
    steps: ['Complete a driving course at an accredited school', 'Apply for a student permit at LTO', 'Pass the written and practical exams', 'Claim your non-professional or professional license'],
  ),
  'voters-id': ChecklistItem(
    id: 'voters-id', title: 'Register as a voter', priority: 'medium',
    description: 'Voter registration enables you to participate in elections and the voter\'s ID/certification is a valid government ID.',
    fee: 'Free', processingTime: '1 day (registration)',
    steps: ['Visit your local COMELEC office during registration period', 'Fill out the voter registration form', 'Have your biometrics captured', 'Check the voters\' list to confirm registration'],
  ),
  'first-time-jobseeker': ChecklistItem(
    id: 'first-time-jobseeker', title: 'Get First-Time Jobseeker certificate', priority: 'medium',
    description: 'Under RA 11261, first-time jobseekers are exempt from fees for government documents (TIN, NBI, police clearance, etc.) for one year.',
    fee: 'Free', processingTime: 'Same day',
    steps: ['Visit your barangay hall', 'Bring a valid ID and proof of address', 'Request a First-Time Jobseeker Barangay Certificate', 'Use it within 1 year to waive fees on government IDs'],
  ),
  'savings-account': ChecklistItem(
    id: 'savings-account', title: 'Open a savings account', priority: 'high',
    description: 'A bank savings account is your foundation for financial management. Choose a bank with low maintaining balance and good digital features.',
    fee: '₱100–₱2,000 initial deposit',
    steps: ['Compare banks for fees, interest rates, and digital features', 'Prepare 2 valid IDs, proof of address, and TIN', 'Visit the bank or apply online (for digital banks)', 'Set up online/mobile banking access'],
  ),
  'understand-payslip': ChecklistItem(
    id: 'understand-payslip', title: 'Understand your payslip', priority: 'medium',
    description: 'Know what\'s being deducted from your salary — SSS, PhilHealth, Pag-IBIG contributions, withholding tax, and your net pay.',
    steps: ['Get a copy of your latest payslip from HR', 'Identify gross pay, deductions, and net pay', 'Verify SSS, PhilHealth, and Pag-IBIG contribution amounts', 'Understand your income tax withholding bracket'],
  ),
  // Pundasyon
  'digital-savings': ChecklistItem(
    id: 'digital-savings', title: 'Open a digital savings account', priority: 'medium',
    description: 'Digital banks like Maya, GCash Save, or Tonik offer higher interest rates (up to 5–6% p.a.) compared to traditional banks.',
    steps: ['Research digital banks and compare interest rates', 'Download the app and sign up', 'Complete identity verification (KYC)', 'Transfer funds and start earning higher interest'],
  ),
  'emergency-fund-3mo': ChecklistItem(
    id: 'emergency-fund-3mo', title: 'Build 3-month emergency fund', priority: 'high',
    description: 'Save at least 3 months of living expenses in a liquid, accessible account. This protects you from job loss, medical emergencies, and unexpected expenses.',
    steps: ['Calculate your monthly essential expenses', 'Multiply by 3 to get your target amount', 'Set up automatic transfers each payday', 'Keep it in a high-yield savings account (not invested)'],
  ),
  'credit-card': ChecklistItem(
    id: 'credit-card', title: 'Get your first credit card', priority: 'low',
    description: 'Building a credit history early helps you qualify for loans later. Start with a secured credit card or one with low annual fees.',
    fee: '₱0–₱2,500/year',
    steps: ['Check if you qualify (most require ₱10k+ monthly income)', 'Apply for a no-annual-fee or secured card', 'Use it for small purchases and pay the full balance monthly', 'Never carry a balance — credit card interest is 24–36% p.a.'],
  ),
  'sss-active': ChecklistItem(
    id: 'sss-active', title: 'Verify SSS contributions are active', priority: 'high',
    description: 'Check your SSS contribution record online to make sure your employer is remitting correctly. Missing contributions affect your loan eligibility and future pension.',
    steps: ['Log in to my.sss.gov.ph', 'Go to Inquiry > Contributions', 'Verify that monthly contributions are being posted', 'Report discrepancies to your HR department'],
  ),
  'philhealth-active': ChecklistItem(
    id: 'philhealth-active', title: 'Verify PhilHealth contributions', priority: 'medium',
    description: 'Ensure your PhilHealth contributions are up to date for uninterrupted health coverage.',
    steps: ['Log in to memberinquiry.philhealth.gov.ph', 'Check your contribution history', 'Verify your employer is remitting monthly', 'Update your MDR if you changed employers'],
  ),
  'pagibig-active': ChecklistItem(
    id: 'pagibig-active', title: 'Verify Pag-IBIG contributions', priority: 'medium',
    description: 'Active Pag-IBIG membership qualifies you for housing loans (lowest interest in PH) and the MP2 savings program.',
    steps: ['Log in to pagibigfundservices.com', 'Check your contribution history', 'Verify at least 24 monthly contributions for loan eligibility', 'Consider increasing voluntary contributions'],
  ),
  '13th-month': ChecklistItem(
    id: '13th-month', title: 'Understand your 13th month pay', priority: 'medium',
    description: 'All rank-and-file employees are entitled to 13th month pay (PD 851). It must be paid on or before December 24.',
    steps: ['Calculate: total basic salary earned in the year ÷ 12', 'Check if your employer gives it as a lump sum or split', 'Note: first ₱90,000 of 13th month + bonuses is tax-exempt', 'Plan how to allocate it (savings, debt, investments)'],
  ),
  'bir-2316': ChecklistItem(
    id: 'bir-2316', title: 'Get your BIR Form 2316', priority: 'medium',
    description: 'Your employer must provide BIR Form 2316 (Certificate of Compensation Payment/Tax Withheld) by January 31 each year. Keep it for your records.',
    steps: ['Request from your HR/payroll department', 'Verify the income and tax withheld amounts', 'Keep copies for at least 3 years', 'Use it if you need to file your own ITR'],
  ),
  'substituted-filing': ChecklistItem(
    id: 'substituted-filing', title: 'Confirm substituted filing eligibility', priority: 'low',
    description: 'If you only have one employer and no other income, your employer files your tax return for you (substituted filing). Confirm this with HR.',
    steps: ['Check with HR if they do substituted filing', 'Verify you have no other taxable income sources', 'Sign the BIR Form 2316 your employer provides', 'Keep your copy as proof of filing'],
  ),
  'bir-freelancer': ChecklistItem(
    id: 'bir-freelancer', title: 'Register as freelancer with BIR', priority: 'high',
    description: 'If you have freelance income, you must register with BIR, file quarterly and annual returns, and pay taxes. Non-registration has penalties.',
    fee: '₱500 registration fee + ₱30 documentary stamp',
    steps: ['Register at your RDO using BIR Form 1901', 'Get your Certificate of Registration (COR)', 'Buy or register official receipts/invoices', 'File quarterly (Form 2551Q for percentage tax) and annual returns'],
  ),
  'bir-deductions': ChecklistItem(
    id: 'bir-deductions', title: 'Choose OSD vs itemized deductions', priority: 'low',
    description: 'Self-employed and mixed-income earners can choose between Optional Standard Deduction (40% of gross) or itemized deductions. Choose whichever gives you a lower tax bill.',
    steps: ['Calculate your actual business expenses for the year', 'Compare with 40% of gross receipts (OSD)', 'If actual expenses > 40% of gross, use itemized', 'Otherwise, OSD is simpler and often better'],
  ),
  // Tahanan
  'philhealth-benefits': ChecklistItem(
    id: 'philhealth-benefits', title: 'Know your PhilHealth benefits', priority: 'medium',
    description: 'Understand your PhilHealth coverage: inpatient, outpatient, Z-benefits for catastrophic illnesses, and the Konsulta package for free primary care.',
    steps: ['Review the PhilHealth benefit packages on their website', 'Locate accredited hospitals and clinics near you', 'Know the claim process before you need it', 'Register for the Konsulta package at an accredited facility'],
  ),
  'hmo': ChecklistItem(
    id: 'hmo', title: 'Get an HMO plan', priority: 'medium',
    description: 'An HMO (Health Maintenance Organization) plan supplements PhilHealth with broader hospital coverage, annual check-ups, and faster access to specialists.',
    fee: '₱8,000–₱25,000/year',
    steps: ['Compare HMO plans (Maxicare, Intellicare, Medicard, etc.)', 'Check coverage limits, room rates, and network hospitals', 'Consider if your employer provides one before buying your own', 'Review pre-existing condition exclusions'],
  ),
  'life-insurance': ChecklistItem(
    id: 'life-insurance', title: 'Get life insurance', priority: 'medium',
    description: 'Term life insurance provides financial protection for your dependents. Get coverage of 10x your annual income.',
    fee: '₱5,000–₱20,000/year (term)',
    steps: ['Determine how much coverage you need (10x annual income)', 'Compare term life vs VUL (term is usually better value)', 'Get quotes from multiple insurers', 'Designate your beneficiaries clearly'],
  ),
  'ctpl': ChecklistItem(
    id: 'ctpl', title: 'Get CTPL insurance for your vehicle', priority: 'low',
    description: 'Compulsory Third Party Liability (CTPL) insurance is required for all registered vehicles in the Philippines.',
    fee: '₱600–₱1,800/year',
    steps: ['Purchase CTPL when you register/renew your vehicle at LTO', 'Choose a reputable insurance provider', 'Keep the policy in your vehicle at all times', 'Consider adding comprehensive coverage for your own vehicle'],
  ),
  'emergency-fund-6mo': ChecklistItem(
    id: 'emergency-fund-6mo', title: 'Grow emergency fund to 6 months', priority: 'high',
    description: 'With more financial responsibilities (home, family), extend your emergency fund to 6 months of expenses.',
    steps: ['Review and update your monthly essential expenses', 'Calculate the gap between current fund and 6-month target', 'Set up automatic monthly transfers', 'Keep it in a separate high-yield savings account'],
  ),
  // Tugatog
  'mp2': ChecklistItem(
    id: 'mp2', title: 'Open a Pag-IBIG MP2 account', priority: 'high',
    description: 'MP2 (Modified Pag-IBIG 2) is a voluntary savings program with tax-free dividends averaging 6–7% p.a. — one of the best risk-free returns in PH.',
    fee: '₱500 minimum',
    steps: ['Log in to pagibigfundservices.com or visit a branch', 'Apply for an MP2 account', 'Choose your savings amount (min ₱500/month)', 'Set up auto-debit or regular bank transfers', 'Maturity is 5 years; you can renew or withdraw'],
  ),
  'uitf': ChecklistItem(
    id: 'uitf', title: 'Invest in UITFs', priority: 'medium',
    description: 'Unit Investment Trust Funds (UITFs) are professionally managed investment funds offered by banks. Good for beginners who want diversified exposure.',
    fee: 'Varies (₱1,000–₱10,000 minimum)',
    steps: ['Open an investment account at your bank', 'Choose a fund type: money market, bond, equity, or balanced', 'Start with a bond or balanced fund if you\'re new', 'Invest regularly (peso-cost averaging) rather than timing the market'],
  ),
  'stocks-pse': ChecklistItem(
    id: 'stocks-pse', title: 'Open a stock brokerage account', priority: 'low',
    description: 'Invest directly in Philippine Stock Exchange (PSE) listed companies through an online broker.',
    fee: '₱5,000 minimum (most brokers)',
    steps: ['Choose an online broker (COL Financial, First Metro Sec, etc.)', 'Open and fund your account', 'Start with blue-chip stocks or index funds', 'Learn to read financial statements before picking individual stocks'],
  ),
  'sss-voluntary': ChecklistItem(
    id: 'sss-voluntary', title: 'Increase voluntary SSS contributions', priority: 'medium',
    description: 'Higher SSS contributions mean a higher retirement pension. Consider voluntarily increasing your contribution bracket, especially during peak earning years.',
    steps: ['Log in to my.sss.gov.ph', 'Check your current contribution bracket', 'Evaluate if increasing contributions fits your budget', 'Apply for voluntary contribution increase through your employer or as a voluntary member'],
  ),
  // Paghahanda
  'beneficiaries': ChecklistItem(
    id: 'beneficiaries', title: 'Review all beneficiary designations', priority: 'high',
    description: 'Review and update beneficiaries on all your accounts: SSS, Pag-IBIG, insurance policies, bank accounts, and investments.',
    steps: ['List all accounts that have beneficiary designations', 'Log in to each and verify the named beneficiaries', 'Update if there have been life changes (marriage, children)', 'Keep a master list of all accounts and beneficiaries'],
  ),
  'will': ChecklistItem(
    id: 'will', title: 'Prepare a last will and testament', priority: 'high',
    description: 'A will ensures your assets are distributed according to your wishes. Without one, Philippine intestate succession laws apply.',
    fee: '₱5,000–₱50,000 (notarized/lawyer-prepared)',
    steps: ['List all your assets and their estimated values', 'Decide how to distribute beyond compulsory heirs\' shares', 'Have a lawyer draft a notarial will, or write a holographic will', 'Store it securely and tell your executor where it is'],
  ),
  'estate-tax': ChecklistItem(
    id: 'estate-tax', title: 'Plan for estate tax', priority: 'medium',
    description: 'The Philippine estate tax is 6% of the net estate (after deductions). Planning ahead prevents your heirs from scrambling to pay it.',
    steps: ['Calculate your estimated net estate value', 'Understand allowable deductions (standard deduction of ₱5M, family home up to ₱10M)', 'Consider life insurance to cover potential estate tax liability', 'Discuss with a tax professional for estates over ₱10M'],
  ),
};
