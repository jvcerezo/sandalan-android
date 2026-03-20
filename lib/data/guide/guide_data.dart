/// Complete adulting journey content — all 6 stages, 23 articles, 44 checklist items.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/color_tokens.dart';

// ─── Types ─────────────────────────────────────────────────────────────────────

class GuideSection {
  final String title;
  final String content;
  final String? callout;

  const GuideSection({required this.title, required this.content, this.callout});
}

class GuideArticle {
  final String slug;
  final String title;
  final int readMinutes;
  final String category;
  final List<GuideSection> sections;
  final List<String> toolLinks;

  const GuideArticle({
    required this.slug,
    required this.title,
    required this.readMinutes,
    required this.category,
    required this.sections,
    this.toolLinks = const [],
  });
}

class ChecklistItem {
  final String id;
  final String title;
  final String description;
  final String priority; // high, medium, low
  final List<String> steps;
  final String? fee;
  final String? processingTime;

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    this.priority = 'medium',
    this.steps = const [],
    this.fee,
    this.processingTime,
  });
}

class LifeStage {
  final String slug;
  final String title;
  final String subtitle;
  final String ageRange;
  final String description;
  final IconData icon;
  final Color color;
  final List<GuideArticle> guides;
  final List<ChecklistItem> checklist;

  const LifeStage({
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.ageRange,
    required this.description,
    required this.icon,
    required this.color,
    required this.guides,
    required this.checklist,
  });
}

// ─── All Stages ────────────────────────────────────────────────────────────────

final List<LifeStage> kLifeStages = [
  _unangHakbang,
  _pundasyon,
  _tahanan,
  _tugatog,
  _paghahanda,
  _gintongTaon,
];

int get kTotalChecklistItems => kLifeStages.fold(0, (s, stage) => s + stage.checklist.length);

// ─── Stage 1: Unang Hakbang ────────────────────────────────────────────────────

final _unangHakbang = LifeStage(
  slug: 'unang-hakbang', title: 'Unang Hakbang', subtitle: 'First Steps',
  ageRange: '18–22', icon: LucideIcons.graduationCap, color: StageColors.blue,
  description: 'Your first job, first IDs, first payslip. Everything you need to start adulting in the Philippines.',
  guides: [
    GuideArticle(slug: 'first-job-documents', title: 'Preparing Documents for Your First Job',
        readMinutes: 6, category: 'government', toolLinks: ['contributions'],
        sections: [
          GuideSection(title: 'Standard Requirements', content: 'Most employers will ask for: NBI Clearance, Barangay Clearance, SSS E-1 form, PhilHealth MDR, Pag-IBIG MID, TIN (BIR Form 1902), 2x2 ID photos, and a medical certificate.'),
          GuideSection(title: 'First Time Jobseeker Certificate', content: 'Under RA 11261, first-time jobseekers are exempt from fees for NBI, police clearance, barangay clearance, and other government documents. Get your FTJC from your barangay — it\'s valid for 1 year.',
              callout: 'Save thousands in fees by getting your FTJC before applying for IDs.'),
          GuideSection(title: 'NBI Clearance', content: 'Apply online at clearance.nbi.gov.ph. Pick a branch and schedule. Bring valid ID + reference number. Results in 1-10 days depending on hits. Cost: ₱155 (free with FTJC).'),
          GuideSection(title: 'BIR Registration', content: 'Your employer handles most BIR registration via Form 1902. You\'ll receive your TIN. Never get a second TIN — penalties apply.',
              callout: 'Getting multiple TINs is a criminal offense under NIRC. If you already have one, inform your employer.'),
        ]),
    GuideArticle(slug: 'first-payslip-decoded', title: 'Your First Payslip, Decoded',
        readMinutes: 5, category: 'financial-literacy', toolLinks: ['contributions'],
        sections: [
          GuideSection(title: 'Why Payslips Matter', content: 'Your payslip is a legal document. It shows your gross pay, all deductions, and net take-home. Understanding it helps you verify you\'re being paid correctly.'),
          GuideSection(title: 'Gross vs Net Pay', content: 'Gross pay is your total salary before deductions. Net pay is what you actually receive. The difference goes to mandatory contributions and taxes.'),
          GuideSection(title: 'Mandatory Deductions', content: 'SSS (4.5% employee share), PhilHealth (2.5%), Pag-IBIG (2%, max ₱100), and Withholding Tax (based on TRAIN Law brackets). For a ₱25,000 salary, total deductions are roughly ₱1,850/month.'),
        ]),
    GuideArticle(slug: 'government-id-roadmap', title: 'The Government ID Roadmap',
        readMinutes: 6, category: 'government',
        sections: [
          GuideSection(title: 'The Chicken-and-Egg Problem', content: 'Most government IDs require... another government ID. The trick is knowing the right order to apply.'),
          GuideSection(title: 'Recommended Order', content: '1. Philippine Statistics Authority (PSA) Birth Certificate\n2. Barangay ID (easiest, just need birth cert)\n3. Postal ID (accepts barangay ID)\n4. PhilSys National ID\n5. SSS / PhilHealth / Pag-IBIG\n6. TIN\n7. UMID Card\n8. Passport\n9. Driver\'s License\n10. Voter\'s ID',
              callout: 'Start with Postal ID or PhilSys — they\'re the easiest entry points.'),
        ]),
    GuideArticle(slug: 'your-first-budget', title: 'Your First Budget (That Actually Works)',
        readMinutes: 5, category: 'financial-literacy', toolLinks: ['budgets'],
        sections: [
          GuideSection(title: 'Why Budgets Fail for Filipinos', content: 'The biggest reason: budgets don\'t account for \'petsa de peligro\' — those days before payday when cash runs out. A good Filipino budget plans for irregular timing.'),
          GuideSection(title: 'The Filipino 4-Bucket System', content: 'Survive (50%): Rent, food, transpo, bills\nProtect (20%): Emergency fund, insurance, contributions\nSupport (20%): Family, debts, obligations\nLive (10%): Entertainment, treats, personal growth'),
          GuideSection(title: 'Start Tracking Today', content: 'Use Sandalan\'s expense tracker to log every peso for one month. You\'ll be surprised where your money actually goes.'),
        ]),
    GuideArticle(slug: 'understanding-deductions', title: 'Where Does My Salary Go?',
        readMinutes: 4, category: 'financial-literacy', toolLinks: ['contributions', 'taxes'],
        sections: [
          GuideSection(title: 'Deductions as Safety Net', content: 'Government deductions aren\'t just taken from you — they\'re building your safety net. SSS gives you a pension, PhilHealth covers hospitalization, and Pag-IBIG lets you take housing loans.'),
          GuideSection(title: 'Sample ₱25,000 Breakdown', content: 'Gross: ₱25,000\nSSS: -₱1,125\nPhilHealth: -₱625\nPag-IBIG: -₱100\nWithholding Tax: -₱0 (below ₱20,833/mo threshold)\nNet Take-Home: ₱23,150'),
        ]),
  ],
  checklist: [
    ChecklistItem(id: 'tin', title: 'Get your TIN from BIR', description: 'Tax Identification Number required for employment, banking, and business.',
        priority: 'high', steps: ['Get BIR Form 1902 from employer (employed) or 1901 (self-employed)', 'Submit to your RDO with valid ID', 'Receive TIN within the day'],
        fee: 'Free', processingTime: 'Same day'),
    ChecklistItem(id: 'sss', title: 'Register with SSS', description: 'Social Security System for pension, disability, maternity, and loan benefits.',
        priority: 'high', steps: ['Go to sss.gov.ph and click Register', 'Fill out online form with personal details', 'Visit nearest SSS branch to verify', 'Get your SS number'],
        fee: 'Free', processingTime: '1-2 weeks'),
    ChecklistItem(id: 'philhealth', title: 'Register with PhilHealth', description: 'Philippine Health Insurance for hospital and healthcare coverage.',
        priority: 'high', steps: ['Visit philhealth.gov.ph', 'Fill out PMRF (PhilHealth Member Registration Form)', 'Submit at nearest PhilHealth office', 'Get your PhilHealth ID number'],
        fee: 'Free', processingTime: '1-2 weeks'),
    ChecklistItem(id: 'pagibig', title: 'Register with Pag-IBIG', description: 'Home Development Mutual Fund for housing loans and MP2 savings.',
        priority: 'high', steps: ['Go to pagibigfund.gov.ph', 'Register as new member online', 'Visit branch for verification', 'Get your MID number'],
        fee: 'Free', processingTime: '1-2 weeks'),
    ChecklistItem(id: 'philsys', title: 'Get PhilSys National ID', description: 'The Philippine Identification System — your universal government ID.',
        priority: 'high', steps: ['Register at philsys.gov.ph', 'Book an appointment at registration center', 'Bring PSA birth certificate + 1 supporting document', 'Biometrics capture at the center', 'Wait for delivery'],
        fee: 'Free', processingTime: '2-6 months'),
    ChecklistItem(id: 'umid', title: 'Get UMID Card', description: 'Unified Multi-Purpose ID — combines SSS, PhilHealth, Pag-IBIG.',
        priority: 'medium', steps: ['Must be SSS member first', 'Apply at SSS branch', 'Biometrics capture', 'Wait for card delivery'],
        fee: 'Free', processingTime: '1-3 months'),
    ChecklistItem(id: 'passport', title: 'Get Philippine Passport', description: 'Required for international travel.',
        priority: 'medium', steps: ['Book appointment at passport.gov.ph', 'Bring PSA birth cert + valid ID', 'Pay fee at DFA office', 'Biometrics and photo capture', 'Wait for release'],
        fee: '₱950 (regular) / ₱1,200 (express)', processingTime: '15-20 working days'),
    ChecklistItem(id: 'drivers-license', title: "Get Driver's License", description: 'Required for driving. Also serves as valid government ID.',
        priority: 'low', steps: ['Get student permit at LTO', 'Attend driving school (15 hours TDC)', 'Pass written and practical exams', 'Get non-professional or professional license'],
        fee: '₱585 (student) + ₱585 (non-pro)', processingTime: '1-2 months total'),
    ChecklistItem(id: 'voters-id', title: "Get Voter's ID / Register to Vote", description: 'Exercise your right to vote. COMELEC registration.',
        priority: 'medium', steps: ['Visit nearest COMELEC office during registration period', 'Bring valid ID + 2 passport-size photos', 'Fill out voter registration form', 'Get biometrics captured'],
        fee: 'Free', processingTime: 'Immediate registration, ID mailed later'),
    ChecklistItem(id: 'first-time-jobseeker', title: 'Get First Time Jobseeker Certificate', description: 'Exempts you from government fees on first job applications.',
        priority: 'high', steps: ['Visit your barangay hall', 'Bring valid ID or birth certificate', 'Sign the FTJC oath', 'Get certified copy'],
        fee: 'Free', processingTime: 'Same day'),
    ChecklistItem(id: 'savings-account', title: 'Open a Savings Account', description: 'Your first bank account — foundation for financial management.',
        priority: 'high', steps: ['Choose a bank (BDO, BPI, or digital bank like CIMB/Tonik)', 'Bring 2 valid IDs + proof of address', 'Initial deposit (as low as ₱100 for digital banks)', 'Set up online/mobile banking'],
        fee: 'Varies (₱0-₱2,000 initial deposit)', processingTime: 'Same day'),
    ChecklistItem(id: 'understand-payslip', title: 'Understand Your Payslip', description: 'Know where every peso goes — gross, deductions, net.',
        priority: 'medium', steps: ['Request payslip from HR/employer', 'Identify gross pay, SSS, PhilHealth, Pag-IBIG, tax', 'Verify amounts match official rates', 'Keep copies for records']),
  ],
);

// ─── Stage 2: Pundasyon ────────────────────────────────────────────────────────

final _pundasyon = LifeStage(
  slug: 'pundasyon', title: 'Pundasyon', subtitle: 'Building the Foundation',
  ageRange: '23–28', icon: LucideIcons.toyBrick, color: StageColors.emerald,
  description: 'Emergency fund, first investments, credit building, and freelancer taxes. Build the financial habits that last a lifetime.',
  guides: [
    GuideArticle(slug: 'emergency-fund-101', title: 'Emergency Fund 101',
        readMinutes: 5, category: 'financial-literacy', toolLinks: ['goals'],
        sections: [
          GuideSection(title: 'Why You Need One', content: '60.7% of Filipino adults can\'t cover a ₱20,000 emergency. An emergency fund is your #1 financial priority.',
              callout: 'BSP survey: 6 in 10 Filipinos cannot handle a ₱20K emergency expense.'),
          GuideSection(title: 'How Much', content: 'Starter: ₱10,000 (covers small emergencies)\nMinimum: 3 months of expenses\nIdeal: 6 months of expenses\nFor freelancers: 6-12 months'),
          GuideSection(title: 'Where to Keep It', content: 'High-yield savings account (CIMB, Tonik, Maya) — NOT in stocks, NOT in time deposits. You need instant access.'),
        ]),
    GuideArticle(slug: 'investing-for-beginners', title: 'Investing 101 for Filipinos',
        readMinutes: 6, category: 'investing', toolLinks: ['calculators'],
        sections: [
          GuideSection(title: 'When to Start', content: 'Only invest AFTER you have: No high-interest debt, 3-month emergency fund, and stable income. Investing before these is gambling.'),
          GuideSection(title: 'The Investment Ladder', content: '1. Pag-IBIG MP2 (6-7% dividend, tax-free)\n2. Money Market UITFs (3-5%)\n3. Bond Funds / RTBs (5-7%)\n4. Balanced Funds (6-10%)\n5. Equity Index Funds / PSE (8-12% historical)'),
          GuideSection(title: 'The Power of Compound Interest', content: '₱3,000/month at 8% for 30 years = ₱4.5 million. Start early, even with small amounts.'),
        ]),
    GuideArticle(slug: 'credit-building', title: 'Building Your Credit Score',
        readMinutes: 4, category: 'financial-literacy',
        sections: [
          GuideSection(title: 'Philippine Credit Scores', content: 'Range: 300-850. Managed by CIC (Credit Information Corporation). Banks check this for loans and credit cards.'),
          GuideSection(title: 'How to Build From Scratch', content: '1. Get a secured credit card (₱10K deposit)\n2. Use it for small purchases (groceries, gas)\n3. Pay FULL balance every month\n4. Never use more than 30% of limit\n5. After 6 months, apply for regular card'),
        ]),
    GuideArticle(slug: 'freelancer-tax-guide', title: 'The Filipino Freelancer Tax Guide',
        readMinutes: 6, category: 'government', toolLinks: ['taxes'],
        sections: [
          GuideSection(title: 'Registration Requirement', content: 'ALL freelancers earning income must register with BIR. This includes online sellers, virtual assistants, content creators, and gig workers.',
              callout: 'BIR is actively pursuing unregistered digital earners. Register now to avoid penalties.'),
          GuideSection(title: '8% Flat Tax vs Graduated Rates', content: 'If gross income ≤ ₱3M/year, you can choose 8% flat tax on gross (minus ₱250K). This is usually simpler and often cheaper than graduated rates for most freelancers.'),
          GuideSection(title: 'Filing Deadlines', content: 'Q1 (Jan-Mar): Due May 15\nQ2 (Apr-Jun): Due Aug 15\nQ3 (Jul-Sep): Due Nov 15\nAnnual: Due April 15'),
        ]),
  ],
  checklist: [
    ChecklistItem(id: 'digital-savings', title: 'Open a Digital Savings Account', description: 'Higher interest rates than traditional banks. CIMB, Tonik, Maya.',
        priority: 'high', steps: ['Download CIMB, Tonik, or Maya app', 'Sign up with valid ID', 'Transfer initial deposit', 'Set up auto-save if available']),
    ChecklistItem(id: 'emergency-fund-3mo', title: 'Build 3-Month Emergency Fund', description: 'Save 3 months of living expenses in an accessible account.',
        priority: 'high', steps: ['Calculate monthly expenses', 'Set target = expenses × 3', 'Set up automatic transfers', 'Track progress in Goals']),
    ChecklistItem(id: 'credit-card', title: 'Get Your First Credit Card', description: 'Start building credit history. Use responsibly.',
        priority: 'medium', steps: ['Apply for secured card if no credit history', 'Use for small regular purchases', 'Pay FULL balance every month', 'Never exceed 30% utilization']),
    ChecklistItem(id: 'sss-active', title: 'Verify SSS Contributions Are Active', description: 'Check that employer is remitting your SSS contributions.',
        priority: 'high', steps: ['Log in to My.SSS', 'Check Contribution tab', 'Verify monthly postings match payslip', 'Report discrepancies to employer/SSS']),
    ChecklistItem(id: 'philhealth-active', title: 'Verify PhilHealth Contributions', description: 'Ensure employer is remitting PhilHealth premiums.',
        priority: 'high', steps: ['Log in to PhilHealth member portal', 'Check contribution history', 'Verify amounts match payslip deductions']),
    ChecklistItem(id: 'pagibig-active', title: 'Verify Pag-IBIG Contributions', description: 'Ensure contributions are posted for housing loan eligibility.',
        priority: 'high', steps: ['Log in to Pag-IBIG Virtual office', 'Check contribution history', 'Need 24 monthly contributions for housing loan']),
    ChecklistItem(id: '13th-month', title: 'Understand Your 13th Month Pay', description: 'Know your rights — mandatory for all rank-and-file employees.',
        priority: 'medium', steps: ['Verify with HR before December 24', 'Formula: (Basic Salary × Months Worked) ÷ 12', 'First ₱90K is tax-exempt']),
    ChecklistItem(id: 'bir-2316', title: 'Get BIR Form 2316', description: 'Certificate of tax withheld — needed for tax filing and loans.',
        priority: 'medium', steps: ['Request from employer by January 31', 'Verify amounts match payslips', 'Keep copies for at least 3 years']),
    ChecklistItem(id: 'substituted-filing', title: 'Check If You Qualify for Substituted Filing', description: 'Employed with single employer? You may not need to file tax returns.',
        priority: 'low', steps: ['Single employer only', 'No other income sources', 'Employer files on your behalf', 'Still get your 2316']),
    ChecklistItem(id: 'bir-freelancer', title: 'Register as Freelancer with BIR', description: 'If freelancing, register within 30 days of starting.',
        priority: 'high', steps: ['Get BIR Form 1901', 'Register at your RDO', 'Get COR and official receipts/invoices', 'File quarterly (1701Q) and annually (1701)']),
    ChecklistItem(id: 'bir-deductions', title: 'Learn About Tax Deductions', description: 'Reduce taxable income with legitimate deductions.',
        priority: 'low', steps: ['OSD: 40% of gross (simpler)', 'Itemized: actual expenses with receipts', 'Choose the method that saves more']),
  ],
);

// ─── Stage 3: Tahanan ──────────────────────────────────────────────────────────

final _tahanan = LifeStage(
  slug: 'tahanan', title: 'Tahanan', subtitle: 'Establishing a Home',
  ageRange: '29–35', icon: LucideIcons.home, color: StageColors.violet,
  description: 'Marriage, homeownership, insurance, and starting a family. The decisions that shape your next decades.',
  guides: [
    GuideArticle(slug: 'pagibig-housing-loan', title: 'Pag-IBIG Housing Loan Step-by-Step',
        readMinutes: 7, category: 'housing', toolLinks: ['rent-vs-buy', 'contributions'],
        sections: [
          GuideSection(title: 'Why Pag-IBIG is Best', content: 'At 5.75% interest (for ₱750K-₱6M loans), Pag-IBIG offers the lowest housing loan rates in the Philippines. Bank rates are typically 7-9%.'),
          GuideSection(title: 'Eligibility', content: 'At least 24 monthly Pag-IBIG contributions, under 65 at loan maturity, and legal capacity to acquire property.'),
          GuideSection(title: 'Required Documents', content: 'Pag-IBIG Housing Loan Application, proof of income (COE, ITR, payslips), valid IDs, property documents (title, tax declaration, lot plan).'),
        ]),
    GuideArticle(slug: 'insurance-layering', title: 'PhilHealth vs HMO vs Private Insurance',
        readMinutes: 5, category: 'insurance', toolLinks: ['insurance'],
        sections: [
          GuideSection(title: 'Three Layers of Protection', content: 'Layer 1: PhilHealth (mandatory, covers basic hospitalization)\nLayer 2: HMO (employer-provided or personal, covers outpatient)\nLayer 3: Life/critical illness insurance (optional but recommended)'),
          GuideSection(title: 'When to Get HMO', content: 'If your employer doesn\'t provide one, consider getting personal HMO when you have dependents or regular medical needs. Budget ₱15K-₱30K/year.'),
        ]),
    GuideArticle(slug: 'marriage-finances', title: 'Marriage Finances in the Philippines',
        readMinutes: 5, category: 'financial-literacy',
        sections: [
          GuideSection(title: 'Real Cost of Weddings', content: 'Simple civil: ₱5K-₱20K\nModest church wedding: ₱50K-₱150K\nMid-range: ₱200K-₱500K\nUpscale: ₱500K-₱1M+'),
          GuideSection(title: 'Financial Conversations Before Marriage', content: 'Discuss: debts, savings, family obligations (panganay duties), property ownership, prenup considerations.'),
        ]),
    GuideArticle(slug: 'education-fund', title: "Starting a Children's Education Fund",
        readMinutes: 4, category: 'financial-literacy',
        sections: [
          GuideSection(title: 'The Staggering Numbers', content: 'Private school tuition: ₱80K-₱200K/year (elementary), ₱100K-₱300K/year (high school), ₱200K-₱500K/year (college). Start saving NOW.',
              callout: 'Avoid insurance company "education plans" — their returns are usually below inflation.'),
          GuideSection(title: 'Best Investment Vehicles by Timeline', content: '10+ years: Equity index funds\n5-10 years: Balanced funds, bonds\nUnder 5 years: Money market, time deposits'),
        ]),
  ],
  checklist: [
    ChecklistItem(id: 'philhealth-benefits', title: 'Know Your PhilHealth Benefits', description: 'Understand what PhilHealth covers — room, medicines, procedures.',
        priority: 'high', steps: ['Check benefit packages at philhealth.gov.ph', 'Know your case rate for common procedures', 'Understand Z-Benefits for catastrophic illness']),
    ChecklistItem(id: 'hmo', title: 'Get HMO Coverage', description: 'Health Maintenance Organization for outpatient and preventive care.',
        priority: 'medium', steps: ['Check if employer provides HMO', 'Compare personal HMO plans if not', 'Budget ₱15K-₱30K/year', 'Maximize annual physical exam']),
    ChecklistItem(id: 'life-insurance', title: 'Get Life Insurance', description: 'Term life insurance — 10x annual income in coverage.',
        priority: 'medium', steps: ['Get term life (not VUL)', 'Coverage = 10× annual income', 'Name beneficiaries', 'Review annually']),
    ChecklistItem(id: 'ctpl', title: 'Get CTPL (Car Insurance)', description: 'Compulsory Third Party Liability — mandatory for all vehicles.',
        priority: 'low', steps: ['Required for LTO registration', 'Get comprehensive for newer vehicles', 'Compare quotes from 3+ insurers']),
    ChecklistItem(id: 'emergency-fund-6mo', title: 'Grow Emergency Fund to 6 Months', description: 'Upgrade from 3 to 6 months of expenses.',
        priority: 'high', steps: ['Calculate 6-month target', 'Increase monthly savings allocation', 'Keep in high-yield savings account']),
  ],
);

// ─── Stage 4: Tugatog ──────────────────────────────────────────────────────────

final _tugatog = LifeStage(
  slug: 'tugatog', title: 'Tugatog', subtitle: 'Career Peak',
  ageRange: '36–45', icon: LucideIcons.mountain, color: StageColors.amber,
  description: 'Peak earning years. Build wealth, diversify investments, and secure your children\'s future.',
  guides: [
    GuideArticle(slug: 'wealth-building', title: 'Building Wealth in Your Peak Years',
        readMinutes: 5, category: 'investing', toolLinks: ['calculators', 'retirement'],
        sections: [
          GuideSection(title: 'Why Peak Years Matter', content: 'Ages 36-45 are your highest earning years. Every peso invested now has 20-30 years to compound before retirement.'),
          GuideSection(title: 'Diversification Strategy', content: '30% Low-risk: MP2, bonds, time deposits\n40% Medium-risk: Balanced UITFs, REITs\n20% Higher-risk: Equity funds, individual stocks\n10% Alternative: Business, real estate'),
        ]),
    GuideArticle(slug: 'mid-career-review', title: 'Mid-Career Financial Review',
        readMinutes: 4, category: 'financial-literacy', toolLinks: ['retirement', 'insurance'],
        sections: [
          GuideSection(title: 'Annual Review Checklist', content: '1. Update insurance beneficiaries\n2. Rebalance investment portfolio\n3. Check retirement projection\n4. Review estate plan\n5. Maximize tax deductions\n6. Audit subscriptions and bills\n7. Update emergency fund target'),
          GuideSection(title: 'Common Mid-Career Traps', content: 'Lifestyle creep, over-reliance on single income, neglecting insurance, postponing retirement planning.'),
        ]),
    GuideArticle(slug: 'health-planning', title: 'Health Planning for Your Peak Years',
        readMinutes: 4, category: 'health',
        sections: [
          GuideSection(title: 'Prevention is Cheaper', content: 'Annual executive checkup: ₱5K-₱15K. One hospitalization without insurance: ₱50K-₱500K+. The math is clear.'),
          GuideSection(title: 'Essential Annual Checkups (Starting Age 35)', content: 'CBC, lipid panel, blood sugar, liver/kidney function, chest X-ray, ECG. Women: pap smear, breast exam. Men: PSA after 50.'),
        ]),
  ],
  checklist: [
    ChecklistItem(id: 'mp2', title: 'Open Pag-IBIG MP2 Account', description: 'Modified Pag-IBIG 2 — tax-free savings with 6-7% annual dividend.',
        priority: 'high', steps: ['Must be active Pag-IBIG member', 'Apply at any Pag-IBIG branch', 'Minimum ₱500 initial deposit', 'Save up to ₱10K/month', '5-year lock-in period']),
    ChecklistItem(id: 'uitf', title: 'Start Investing in UITFs', description: 'Unit Investment Trust Funds — professionally managed pooled funds.',
        priority: 'medium', steps: ['Open investment account at your bank', 'Start with money market or balanced fund', 'Minimum ₱10K initial investment', 'Set up regular monthly top-ups']),
    ChecklistItem(id: 'stocks-pse', title: 'Open a PSE Trading Account', description: 'Direct stock market investing via Philippine Stock Exchange.',
        priority: 'low', steps: ['Choose broker (COL Financial, First Metro)', 'Open account online', 'Fund with minimum ₱5,000', 'Start with PSE index funds (FMETF)']),
    ChecklistItem(id: 'sss-voluntary', title: 'Maximize SSS Voluntary Contributions', description: 'Increase your MSC to maximize future pension.',
        priority: 'medium', steps: ['Check current MSC at My.SSS', 'Voluntarily increase contributions', 'Target MSC of ₱25,000-₱30,000', 'Pay through online banking or bayad centers']),
  ],
);

// ─── Stage 5: Paghahanda ───────────────────────────────────────────────────────

final _paghahanda = LifeStage(
  slug: 'paghahanda', title: 'Paghahanda', subtitle: 'Preparing for the Future',
  ageRange: '46–55', icon: LucideIcons.clock, color: StageColors.rose,
  description: 'Retirement planning, estate planning, and managing the sandwich generation. Prepare for what\'s ahead.',
  guides: [
    GuideArticle(slug: 'maximize-sss-pension', title: 'Maximizing Your SSS Pension',
        readMinutes: 5, category: 'retirement', toolLinks: ['retirement', 'contributions'],
        sections: [
          GuideSection(title: 'How SSS Pension is Calculated', content: 'Formula: max of three:\n1. ₱300 + 20% × AMSC + 2% × AMSC × (CYS - 10)\n2. ₱1,200 minimum\n3. 40% × AMSC\n\nAMSC = Average Monthly Salary Credit\nCYS = Credited Years of Service (min 10, max 40)'),
          GuideSection(title: 'Strategies to Increase Pension', content: '1. Contribute for at least 20+ years\n2. Maximize your MSC (₱30,000 max)\n3. Voluntary contributions if between jobs\n4. Verify all contributions are posted'),
        ]),
    GuideArticle(slug: 'sandwich-generation', title: 'Surviving the Sandwich Generation',
        readMinutes: 5, category: 'family', toolLinks: ['panganay'],
        sections: [
          GuideSection(title: "You're Not Alone", content: 'Many Filipino adults support aging parents while raising children. This "sandwich" can be financially and emotionally exhausting.'),
          GuideSection(title: 'Setting Boundaries Without Guilt', content: 'You can\'t pour from an empty cup. Set a fixed monthly family support amount. Communicate it clearly. Stick to it. Use Sandalan\'s Panganay Mode to track.'),
        ]),
    GuideArticle(slug: 'estate-planning-basics', title: 'Estate Planning Basics for Filipinos',
        readMinutes: 5, category: 'retirement',
        sections: [
          GuideSection(title: 'Why You Need an Estate Plan', content: 'Without a will, Philippine law dictates who gets what (intestate succession). This may not match your wishes. Estate settlement can take years without preparation.'),
          GuideSection(title: 'Will Types', content: 'Notarial Will: Signed before notary + 3 witnesses\nHolographic Will: Entirely handwritten, dated, and signed by you\n\nBoth are legally valid. Holographic is simpler but easier to contest.'),
          GuideSection(title: 'Estate Tax', content: '6% flat rate on net estate (after deductions). Standard deduction: ₱5M. Family home deduction: up to ₱10M. File within 1 year of death.'),
        ]),
    GuideArticle(slug: 'debt-free-before-retirement', title: 'Paying Off All Debt Before Retirement',
        readMinutes: 4, category: 'financial-literacy', toolLinks: ['debts'],
        sections: [
          GuideSection(title: 'Why Debt-Free Matters', content: 'Retirement income is fixed (SSS pension + savings). Debt payments eat into that fixed income. Enter retirement with zero debt.'),
          GuideSection(title: 'Avalanche vs Snowball', content: 'Avalanche: Pay highest interest first (saves most money)\nSnowball: Pay smallest balance first (quick wins for motivation)\nBoth work — choose what keeps you motivated.'),
        ]),
  ],
  checklist: [
    ChecklistItem(id: 'beneficiaries', title: 'Update All Beneficiaries', description: 'Review and update beneficiaries on SSS, Pag-IBIG, insurance, and bank accounts.',
        priority: 'high', steps: ['List all accounts with beneficiaries', 'Update SSS beneficiaries at My.SSS', 'Update Pag-IBIG beneficiaries', 'Update insurance policies', 'Update bank accounts']),
    ChecklistItem(id: 'will', title: 'Draft a Will', description: 'Ensure your assets go where you want them.',
        priority: 'high', steps: ['List all assets and liabilities', 'Decide distribution among heirs', 'Choose notarial or holographic will', 'Consult a lawyer if complex', 'Store safely and inform executor']),
    ChecklistItem(id: 'estate-tax', title: 'Understand Estate Tax Obligations', description: 'Know the 6% flat rate and available deductions.',
        priority: 'medium', steps: ['Learn about 6% flat rate on net estate', 'Know standard deduction (₱5M)', 'Know family home deduction (up to ₱10M)', 'Consider gradual asset transfer while alive']),
  ],
);

// ─── Stage 6: Gintong Taon ─────────────────────────────────────────────────────

final _gintongTaon = LifeStage(
  slug: 'gintong-taon', title: 'Gintong Taon', subtitle: 'Golden Years',
  ageRange: '56+', icon: LucideIcons.gem, color: StageColors.yellow,
  description: 'Retirement, senior citizen benefits, healthcare, and passing wealth to the next generation.',
  guides: [
    GuideArticle(slug: 'senior-citizen-benefits', title: 'Senior Citizen Benefits Complete Guide',
        readMinutes: 5, category: 'retirement',
        sections: [
          GuideSection(title: 'Who Qualifies', content: 'Filipino citizens aged 60 and above. Get your OSCA (Office for Senior Citizens Affairs) ID from your city/municipality — it\'s free.'),
          GuideSection(title: 'Mandatory Discounts', content: '20% discount + VAT exemption on:\n• Medicines and medical services\n• Public transportation\n• Hotels and restaurants\n• Recreation and amusement\n• Funeral and burial services'),
          GuideSection(title: 'Social Pension', content: '₱1,000/month for indigent senior citizens (DSWD). Additional benefits: PhilHealth coverage (free for 60+), priority lanes everywhere.'),
        ]),
    GuideArticle(slug: 'healthcare-retirement', title: 'Healthcare Management in Retirement',
        readMinutes: 4, category: 'health',
        sections: [
          GuideSection(title: 'Healthcare Costs — Biggest Threat', content: 'Medical expenses are the #1 risk to retirement savings. A single hospitalization can wipe out years of savings.'),
          GuideSection(title: 'Building a Healthcare Fund', content: 'Set aside ₱200K-₱500K specifically for healthcare. Keep it in a separate, accessible account. This is in addition to your regular emergency fund and PhilHealth coverage.'),
        ]),
    GuideArticle(slug: 'passing-wealth', title: 'Passing Wealth to the Next Generation',
        readMinutes: 4, category: 'retirement',
        sections: [
          GuideSection(title: 'Planning the Transfer', content: 'Start transferring knowledge (not just money) now. Teach children about budgeting, investing, and financial responsibility.'),
          GuideSection(title: 'Strategies', content: '1. Updated will with clear instructions\n2. Named beneficiaries on all accounts\n3. Living donations (₱250K/year tax-free per donee)\n4. Life insurance with children as beneficiaries\n5. Family meetings about financial wishes'),
          GuideSection(title: 'Avoiding Common Pitfalls', content: 'Don\'t disinherit compulsory heirs (illegal in PH). Don\'t put all assets in one child\'s name. Document everything. Consult a lawyer for complex estates.'),
        ]),
  ],
  checklist: [], // No checklist items for this stage
);
