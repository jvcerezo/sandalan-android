/// Complete adulting journey content — all 6 stages, 23 articles, 44 checklist items.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/color_tokens.dart';
import 'content/unang_hakbang.dart';
import 'content/pundasyon.dart';
import 'content/tahanan.dart';
import 'content/tugatog.dart';
import 'content/paghahanda.dart';
import 'content/gintong_taon.dart';

// ─── Types ─────────────────────────────────────────────────────────────────────

class GuideSection {
  final String title;
  final String content;
  final String? callout;
  final String? calloutType; // tip, warning, info, ph-law
  final List<String> items;

  const GuideSection({required this.title, required this.content, this.callout, this.calloutType, this.items = const []});
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

// ─── Stage Definitions ─────────────────────────────────────────────────────────
// Guide content imported from content/ files (word-for-word port from web app)

final _unangHakbang = LifeStage(
  slug: 'unang-hakbang', title: 'Unang Hakbang', subtitle: 'First Steps',
  ageRange: '18–22', icon: LucideIcons.graduationCap, color: StageColors.blue,
  description: 'Your first job, first IDs, first payslip. Everything you need to start adulting in the Philippines.',
  guides: kUnangHakbangGuides,
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
  guides: kPundasyonGuides,
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
  guides: kTahananGuides,
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
  guides: kTugatogGuides,
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
  guides: kPaghahandaGuides,
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
  guides: kGintongTaonGuides,
  checklist: [], // No checklist items for this stage
);
