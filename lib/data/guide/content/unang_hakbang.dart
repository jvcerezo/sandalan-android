import '../guide_data.dart';

final List<GuideArticle> kUnangHakbangGuides = [
  GuideArticle(
    slug: 'first-job-documents',
    title: 'Preparing Documents for Your First Job',
    readMinutes: 6,
    category: 'government',
    toolLinks: ['unang-hakbang'],
    sections: [
      GuideSection(
        title: 'The standard requirements',
        content:
            'Almost every employer in the Philippines asks for the same set of documents. Having these ready before you even start applying puts you ahead of 90% of fresh graduates.',
        items: [
          'Resume/CV (updated, 1-2 pages max)',
          'PSA Birth Certificate (not the local civil registrar copy \u2014 must be PSA-issued)',
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
        title: 'Get your First Time Jobseeker Certificate first',
        content:
            'Before applying for NBI clearance, police clearance, or any other document \u2014 go to your Barangay Hall and get a First Time Jobseeker Certificate under RA 11261. This exempts you from paying fees on most employment requirements. It typically saves \u20B1500\u2013\u20B11,500.',
        callout:
            'Get the First Time Jobseeker Certificate BEFORE anything else. It makes NBI Clearance, Police Clearance, Barangay Clearance, and even your PSA Birth Certificate FREE. Valid for 1 year.',
        calloutType: 'tip',
      ),
      GuideSection(
        title: 'NBI Clearance \u2014 step by step',
        content:
            'The NBI Clearance is the most commonly required pre-employment document. Here\u2019s how to get it:',
        items: [
          'Go to clearance.nbi.gov.ph and create an account',
          'Fill out the online application form',
          'Select your preferred NBI branch and appointment date',
          'Pay the fee online (\u20B1155) or present your First Time Jobseeker Certificate for exemption',
          'On your appointment date, bring: valid ID, printed reference number, and First Time Jobseeker Certificate (if applicable)',
          'Biometrics capture (fingerprints and photo) takes about 10-15 minutes',
          'If no \u2018hit\u2019 (name match in records): clearance is released same day',
          'If there\u2019s a \u2018hit\u2019: you\u2019ll need to return after 7-14 business days for verification',
        ],
      ),
      GuideSection(
        title: 'BIR Form 1902 \u2014 for new employees',
        content:
            'When you get hired, your employer will ask you to fill out BIR Form 1902. This registers you as a new employee with the Bureau of Internal Revenue and generates your TIN if you don\u2019t already have one.',
        items: [
          'Your employer\u2019s HR department provides the form \u2014 don\u2019t go to BIR yourself',
          'Fill it out completely: personal info, employer details, and tax status',
          'Tax status: \u2018S\u2019 for single with no dependents, \u2018S1\u2019 for single with 1 dependent, \u2018ME\u2019 for married',
          'If you already have a TIN from a previous registration (e.g., freelancing), inform HR immediately \u2014 do NOT get a second TIN',
          'Your employer submits this to BIR within 10 days of your start date',
        ],
        callout:
            'Never apply for a second TIN. If you already have one (from freelancing, OJT, or scholarship), tell your employer. Having multiple TINs is a criminal offense under the Tax Code.',
        calloutType: 'warning',
      ),
      GuideSection(
        title: 'Pro tips for first-time applicants',
        content: 'Save time and avoid common mistakes:',
        items: [
          'Process all documents in one week: Day 1 \u2014 Barangay (FTJC), Day 2 \u2014 NBI, Day 3 \u2014 SSS/PhilHealth/Pag-IBIG, Day 4 \u2014 PSA birth cert, Day 5 \u2014 photos',
          'Bring at least 5 photocopies of every document \u2014 employers, banks, and government offices all ask for copies',
          'Wear a collared shirt for your ID photos \u2014 some companies require this for their employee IDs',
          'Save digital copies (photos/scans) of all documents on your phone and cloud storage',
          'Create a folder (physical and digital) labeled \u2018Employment Documents\u2019 \u2014 you\u2019ll need these for your entire career',
        ],
      ),
    ],
  ),
  GuideArticle(
    slug: 'first-payslip-decoded',
    title: 'Your First Payslip, Decoded',
    readMinutes: 5,
    category: 'financial-literacy',
    toolLinks: ['contributions'],
    sections: [
      GuideSection(
        title: 'Why your payslip matters',
        content:
            'Your payslip is a map of your money. Every peso deducted has a purpose \u2014 from funding your future retirement pension to covering hospitalization costs. Most fresh graduates glance at the net pay and ignore the rest. That\u2019s a mistake. Understanding your payslip is the first step to taking control of your finances.',
      ),
      GuideSection(
        title: 'Gross pay vs. net pay',
        content:
            'Gross pay is your salary before deductions. Net pay (take-home pay) is what actually lands in your bank account. The difference? Mandatory government contributions and income tax. On a P25,000 gross salary, expect roughly P2,500\u2013P3,000 in total deductions, leaving you with around P22,000\u2013P22,500 net.',
        callout:
            'Use the Gov\u2019t Contributions calculator to see the exact breakdown for your salary \u2014 it computes your SSS, PhilHealth, Pag-IBIG deductions, and withholding tax automatically based on current 2024 rates.',
        calloutType: 'tip',
      ),
      GuideSection(
        title: 'SSS (Social Security System)',
        content:
            'Your SSS contribution is split between you and your employer. The employee share is 5% of your Monthly Salary Credit (MSC). This funds your retirement pension, maternity/sickness benefits, disability coverage, and salary/calamity loans. The more you contribute over your career, the higher your pension will be.',
        items: [
          'Retirement pension after 120 months (10 years) of contributions',
          'Salary loan up to 2 months\u2019 salary after 36 contributions',
          'Maternity benefit: 100% of daily salary credit for 105 days',
          'Sickness benefit: 90% of daily salary credit for up to 120 days',
        ],
      ),
      GuideSection(
        title: 'PhilHealth',
        content:
            'PhilHealth is your national health insurance. The premium is 5% of your basic salary, split equally between you and your employer. It covers inpatient hospitalization, outpatient consultations, and selected medicines. A single hospital stay without PhilHealth can cost P50,000\u2013P200,000+ out of pocket.',
        callout:
            'PhilHealth contributions are mandatory for all employed Filipinos under Republic Act No. 11223 (Universal Health Care Act).',
        calloutType: 'ph-law',
      ),
      GuideSection(
        title: 'Pag-IBIG (HDMF)',
        content:
            'Pag-IBIG contributions are P200/month for most employees. Your employer matches this amount. While it seems small, Pag-IBIG opens the door to housing loans (up to P6,000,000 at 5.75% interest) and the MP2 savings program that earns 6\u20137% tax-free annually.',
        callout:
            'After 24 months of Pag-IBIG contributions, you\u2019re eligible for housing loans. Start tracking your contributions now so you know exactly when you qualify.',
        calloutType: 'tip',
      ),
      GuideSection(
        title: 'Withholding tax',
        content:
            'Under the TRAIN Law, you pay 0% income tax if your annual taxable income is P250,000 or below (roughly P20,833/month). Above that threshold, tax rates range from 15% to 35% on a graduated scale. Your employer withholds this tax from each paycheck and remits it to the BIR on your behalf.',
      ),
      GuideSection(
        title: 'What to do right now',
        content:
            'Don\u2019t just look at your payslip \u2014 verify it. Check that your SSS, PhilHealth, and Pag-IBIG deductions match the official contribution tables. Some employers make errors or, worse, deduct but fail to remit. Track your contributions monthly using Sandalan.',
        items: [
          'Open the Gov\u2019t Contributions calculator and enter your gross salary',
          'Compare the calculated deductions with your actual payslip',
          'Start logging your contributions in the Contributions Tracker',
          'Set a monthly reminder to verify your contributions are posted',
        ],
      ),
    ],
  ),
  GuideArticle(
    slug: 'government-id-roadmap',
    title: 'The Government ID Roadmap',
    readMinutes: 6,
    category: 'government',
    toolLinks: ['unang-hakbang'],
    sections: [
      GuideSection(
        title: 'The chicken-and-egg problem',
        content:
            'Fresh graduates often face a frustrating loop: you need a valid ID to get a valid ID. Most government agencies require at least one government-issued ID for registration. If you have zero IDs, where do you even start?',
        callout:
            'Start with a Postal ID (P504, requires only a birth certificate) or PhilSys National ID (free, requires birth certificate + biometrics). These are the easiest \u2018starter\u2019 IDs.',
        calloutType: 'tip',
      ),
      GuideSection(
        title: 'The recommended order',
        content:
            'Based on ease of acquisition and usefulness, here\u2019s the optimal order to get your IDs:',
        items: [
          '1. PhilSys National ID \u2014 free, lifetime validity, biometric-linked, accepted everywhere once fully rolled out',
          '2. TIN (BIR) \u2014 required before employment. Your employer can process this for you via Form 1902',
          '3. SSS Number \u2014 mandatory for employment. Register online at my.sss.gov.ph',
          '4. PhilHealth \u2014 mandatory. Employer enrolls you, or self-register at PhilHealth office',
          '5. Pag-IBIG MID \u2014 mandatory. Register at Virtual Pag-IBIG or any branch',
          '6. Postal ID \u2014 backup ID, P504, available at any post office',
          '7. UMID \u2014 combines SSS/PhilHealth/Pag-IBIG into one card. Apply after 1+ SSS contribution',
          '8. Passport \u2014 most powerful ID. Apply at DFA (P950 regular, P1,200 expedited)',
        ],
      ),
      GuideSection(
        title: 'Documents you need for almost everything',
        content:
            'Keep certified true copies of these documents ready. You\u2019ll need them repeatedly across all government applications:',
        items: [
          'PSA Birth Certificate (order at psaserbilis.com.ph, P365)',
          'Two 1x1 and two 2x2 ID photos (white background)',
          'Proof of address (barangay certificate, utility bill, or rent contract)',
          'Any existing valid government ID (for subsequent applications)',
        ],
      ),
      GuideSection(
        title: 'Common pitfalls to avoid',
        content:
            'Government ID processes in the Philippines have known friction points. Here\u2019s how to navigate them:',
        items: [
          'NBI Clearance \u2018hits\u2019: Common Filipino surnames trigger false positives. Bring extra valid IDs and be prepared to return for verification',
          'DFA passport appointments: Slots fill up fast. Book 2\u20133 weeks ahead on dfa.gov.ph. Avoid fixers \u2014 it\u2019s a criminal offense',
          'Multiple TINs: Having more than one TIN is illegal (up to P1,000 fine and/or imprisonment). If your employer issues you a new TIN, inform BIR immediately to merge records',
          'SSS/PhilHealth/Pag-IBIG portals: These go down frequently. Try during off-peak hours (early morning or late evening)',
        ],
        callout:
            'Never surrender your original PSA birth certificate. Government agencies only need to see the original \u2014 they should accept a photocopy for their records.',
        calloutType: 'warning',
      ),
      GuideSection(
        title: 'Track your progress',
        content:
            'Use the Adulting Checklist in Sandalan to track which IDs you\u2019ve obtained and which are still pending. Each ID is marked with a priority level \u2014 start with the \u2018Must Do\u2019 items and work your way down.',
      ),
    ],
  ),
  GuideArticle(
    slug: 'your-first-budget',
    title: 'Your First Budget (That Actually Works)',
    readMinutes: 5,
    category: 'financial-literacy',
    toolLinks: ['budgets', 'transactions'],
    sections: [
      GuideSection(
        title: 'Why most budgets fail for Filipinos',
        content:
            'The popular 50/30/20 rule (50% needs, 30% wants, 20% savings) was designed for Western households. It doesn\u2019t account for Filipino realities: family obligations (utang na loob), irregular income, the \u2018petsa de peligro\u2019 cycle, and the cultural expectation that breadwinners support extended family. Let\u2019s build a budget that actually works.',
      ),
      GuideSection(
        title: 'The Filipino 4-Bucket System',
        content:
            'Instead of percentages, think in four buckets that you fill in priority order every payday:',
        items: [
          'Bucket 1 \u2014 SURVIVE (fixed costs): Rent, utilities, food, transport, phone/internet. These are non-negotiable. Know this number exactly.',
          'Bucket 2 \u2014 PROTECT (savings & insurance): Emergency fund, SSS/PhilHealth/Pag-IBIG (if voluntary), insurance premiums. Pay yourself second, not last.',
          'Bucket 3 \u2014 SUPPORT (family obligations): Monthly padala to parents, sibling tuition, family emergencies. Set a fixed amount you can actually afford \u2014 don\u2019t give until you\u2019re broke.',
          'Bucket 4 \u2014 LIVE (everything else): Social, dating, hobbies, shopping, subscriptions. Whatever\u2019s left after the first three buckets.',
        ],
        callout:
            'The magic is in the order. Most Filipinos do Survive \u2192 Support \u2192 Live \u2192 (nothing left for) Protect. Flip the script: Survive \u2192 Protect \u2192 Support \u2192 Live.',
        calloutType: 'tip',
      ),
      GuideSection(
        title: 'Beating \u2018petsa de peligro\u2019',
        content:
            'The \u2018danger payday\u2019 cycle happens when you spend freely after payday and scrape by before the next one. The fix: divide your monthly budget by 2 (for bi-monthly paydays) or 4 (for weekly budgeting). Allocate your four buckets per pay period, not per month. This way you never have a \u2018feast or famine\u2019 cycle.',
      ),
      GuideSection(
        title: 'Start tracking today',
        content:
            'You don\u2019t need a perfect budget on day one. Start by tracking every peso for 30 days \u2014 just record what you spend. After one month, you\u2019ll know exactly where your money goes. Then set realistic budget limits based on actual data, not guesses.',
        items: [
          'Log every expense in Sandalan (even P20 jeepney fares)',
          'After 30 days, review your spending by category',
          'Set budget limits in the Budgets tab based on your actual patterns',
          'Adjust monthly until you find a rhythm that works for your income',
        ],
      ),
    ],
  ),
  GuideArticle(
    slug: 'understanding-deductions',
    title: 'Where Does My Salary Go?',
    readMinutes: 4,
    category: 'financial-literacy',
    toolLinks: ['contributions'],
    sections: [
      GuideSection(
        title: 'It\u2019s not just deductions \u2014 it\u2019s your safety net',
        content:
            'Most fresh grads see salary deductions as money taken away. In reality, these deductions build your personal safety net: retirement income, health coverage, housing eligibility, and emergency loans. Think of them as forced savings managed by the government on your behalf.',
      ),
      GuideSection(
        title: 'Sample breakdown: P25,000 monthly salary',
        content:
            'Here\u2019s what happens to a P25,000 gross monthly salary for a regular employee:',
        items: [
          'SSS (employee share): ~P1,125 \u2014 funds your pension, loans, maternity/sickness benefits',
          'PhilHealth (employee share): ~P625 \u2014 covers hospitalization and outpatient care',
          'Pag-IBIG (employee share): P200 \u2014 housing loans and MP2 savings eligibility',
          'Withholding tax: ~P416 \u2014 income tax on earnings above P20,833/month',
          'Total deductions: ~P2,366',
          'Net take-home: ~P22,634',
        ],
        callout:
            'Your employer also contributes on top of your deductions: ~P2,250 for SSS, ~P625 for PhilHealth, and P200 for Pag-IBIG. Your total compensation is actually higher than your gross salary.',
        calloutType: 'info',
      ),
      GuideSection(
        title: 'What you get back',
        content:
            'These aren\u2019t just costs \u2014 they\u2019re benefits you can claim:',
        items: [
          'SSS: Retirement pension (after 120 months of contributions), salary loan (up to 2x monthly salary), maternity leave pay, sickness benefit',
          'PhilHealth: Hospital bill coverage through case rates, outpatient consultations, Z-benefits for cancer and other conditions',
          'Pag-IBIG: Housing loan at 5.75% (after 24 contributions), multi-purpose loan, MP2 savings at 6\u20137% tax-free dividends',
          'Income tax: Funds public services \u2014 roads, schools, healthcare. Under TRAIN Law, the first P250,000/year is tax-free',
        ],
      ),
      GuideSection(
        title: 'Verify your deductions',
        content:
            'Don\u2019t blindly trust your payslip. Use the Gov\u2019t Contributions calculator to check if your deductions are computed correctly. Then log your contributions monthly to catch any discrepancies early \u2014 some employers deduct but fail to remit to SSS/PhilHealth/Pag-IBIG.',
      ),
    ],
  ),
];
