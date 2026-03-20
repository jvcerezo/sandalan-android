import '../guide_data.dart';

final List<GuideArticle> kPaghahandaGuides = [
  GuideArticle(
    slug: 'maximize-sss-pension',
    title: 'Maximizing Your SSS Pension',
    readMinutes: 5,
    category: 'retirement',
    toolLinks: ['retirement-projection', 'contributions'],
    sections: [
      GuideSection(
        title: 'How SSS pension is calculated',
        content:
            'Your SSS monthly pension is based on three factors: your Average Monthly Salary Credit (AMSC), the number of credited years of service (CYS), and the pension formula. The formula is: P300 + 20% of AMSC + (2% of AMSC \u00d7 CYS beyond 10 years). Higher AMSC and more years of contribution mean a higher pension.',
      ),
      GuideSection(
        title: 'Strategies to increase your pension',
        content:
            'You can take action now to significantly boost your retirement income:',
        items: [
          'Maximize your Monthly Salary Credit: Contribute at the highest MSC bracket possible (up to P35,000)',
          'Don\u2019t have gaps: Every month without a contribution is a missed opportunity. Voluntary members can pay during unemployment',
          'Contribute for as long as possible: The minimum is 120 months (10 years), but 30+ years of contributions dramatically increases your pension',
          'Consider voluntary contributions above the mandatory: The MySSS Pension Booster takes contributions above P20,000 MSC',
        ],
        callout:
            'Use the Retirement Projection tool to see how increasing your MSC or adding more years of contributions affects your estimated pension.',
        calloutType: 'tip',
      ),
      GuideSection(
        title: 'SSS pension alone is not enough',
        content:
            'Even at the maximum pension, SSS will not cover a comfortable retirement. You need supplementary income from personal savings, investments (MP2, UITFs, stocks), rental income, or a small business. Start planning your retirement income sources now \u2014 don\u2019t wait until you\u2019re 60.',
      ),
    ],
  ),
  GuideArticle(
    slug: 'sandwich-generation',
    title: 'Surviving the Sandwich Generation',
    readMinutes: 5,
    category: 'family',
    toolLinks: ['panganay-mode', 'budgets'],
    sections: [
      GuideSection(
        title: 'You\u2019re not alone',
        content:
            'A rising number of Filipinos belong to the sandwich generation \u2014 supporting aging parents while also raising their own children. Philippine culture makes this uniquely intense: filial duty (utang na loob), limited social safety nets, and insufficient SSS pensions mean the financial burden falls squarely on working adults.',
      ),
      GuideSection(
        title: 'Setting boundaries without guilt',
        content:
            'Supporting family doesn\u2019t mean sacrificing your own financial future. You can\u2019t help others from a position of financial ruin:',
        items: [
          'Set a fixed monthly amount for family support \u2014 communicate it clearly and stick to it',
          'Protect your emergency fund and retirement savings first \u2014 these are non-negotiable',
          'Help siblings become self-sufficient rather than perpetuating dependency',
          'It\u2019s okay to say no to extended family requests that would put you in debt',
          'Use Panganay Mode in Sandalan to track family obligations separately from personal spending',
        ],
        callout:
            'Setting financial boundaries is not selfishness \u2014 it\u2019s sustainability. You can\u2019t give from an empty cup.',
        calloutType: 'info',
      ),
      GuideSection(
        title: 'Practical budgeting for sandwich generation',
        content:
            'Use the 4-bucket system adapted for your situation:',
        items: [
          'Bucket 1 \u2014 Your household: Rent, utilities, food, transport, children\u2019s needs',
          'Bucket 2 \u2014 Your protection: Emergency fund, retirement, insurance',
          'Bucket 3 \u2014 Parent support: Fixed monthly amount for parents\u2019 needs',
          'Bucket 4 \u2014 Everything else: Personal spending, wants, treats',
        ],
      ),
    ],
  ),
  GuideArticle(
    slug: 'estate-planning-basics',
    title: 'Estate Planning Basics for Filipinos',
    readMinutes: 5,
    category: 'retirement',
    toolLinks: ['paghahanda'],
    sections: [
      GuideSection(
        title: 'Why you need an estate plan now',
        content:
            'Most Filipinos think estate planning is only for the wealthy. It\u2019s not. If you own any property, have savings, or have dependents, you need a basic estate plan. Without one, your assets get tied up in courts for years, family disputes arise, and the government takes 6% estate tax before your heirs see a peso.',
      ),
      GuideSection(
        title: 'The basics: will types in the Philippines',
        content: 'Philippine law recognizes two types of wills:',
        items: [
          'Notarial will: Typed or printed, signed by you and 3 witnesses, notarized. Most common and safest option. Cost: P3,000\u2013P8,000 with a lawyer.',
          'Holographic will: Entirely handwritten by you, dated, and signed. No witnesses or notarization needed. Free but can be contested more easily.',
        ],
        callout:
            'The Philippines follows forced heirship (legitimes). You cannot disinherit legitimate children, your spouse, or parents from their legal share. A will distributes the \u2018free portion\u2019 of your estate \u2014 typically 25\u201350% depending on surviving heirs.',
        calloutType: 'ph-law',
      ),
      GuideSection(
        title: 'Estate tax: the 6% rule',
        content:
            'The estate tax in the Philippines is a flat 6% of the net estate (total assets minus deductions like debts, funeral expenses, and the standard deduction of P5,000,000). The estate tax return must be filed within 1 year of death. Failure to file incurs 25% surcharge + 12% annual interest.',
      ),
      GuideSection(
        title: 'Action items you can do today',
        content:
            'Estate planning doesn\u2019t require a lawyer on day one. Start with these steps:',
        items: [
          'Update all beneficiaries: SSS (Form E-4), Pag-IBIG (MDF), bank accounts, insurance policies',
          'Create an asset inventory: List all bank accounts, investments, properties, and valuable items',
          'Organize documents: Keep titles, insurance policies, and financial records in one secure place',
          'Tell a trusted person: At minimum, one family member should know where your documents are',
          'Consider a holographic will: It\u2019s free, legally valid, and takes 30 minutes to write',
        ],
      ),
    ],
  ),
  GuideArticle(
    slug: 'debt-free-before-retirement',
    title: 'Paying Off All Debt Before Retirement',
    readMinutes: 4,
    category: 'financial-literacy',
    toolLinks: ['debts'],
    sections: [
      GuideSection(
        title: 'Why debt-free retirement matters',
        content:
            'Your SSS pension will likely be P6,000\u2013P12,000/month. If you\u2019re still paying P8,000/month on a housing loan and P3,000/month on credit cards, your pension is consumed before you buy groceries. The goal: zero debt by age 60.',
      ),
      GuideSection(
        title: 'Debt payoff strategies',
        content: 'Two proven approaches:',
        items: [
          'Avalanche method: Pay minimums on all debts, throw extra money at the highest-interest debt first. Mathematically optimal \u2014 saves the most on interest.',
          'Snowball method: Pay minimums on all debts, throw extra money at the smallest balance first. Psychologically motivating \u2014 you see debts disappear faster.',
          'Either method works. Pick the one you\u2019ll stick with. Consistency beats optimization.',
        ],
      ),
      GuideSection(
        title: 'Accelerating payoff in your 40s-50s',
        content: 'Strategies specific to this life stage:',
        items: [
          'Redirect 13th month pay and bonuses to debt payoff',
          'If children are independent, redirect their education fund contributions to debt',
          'Consider refinancing high-interest loans (credit cards at 24% \u2192 personal loan at 12%)',
          'Use the Debt Manager tool to track balances and visualize your payoff timeline',
          'Avoid taking on new debt \u2014 no new car loans or credit cards',
        ],
        callout:
            'Never borrow from your retirement savings or emergency fund to pay off debt. That trades one problem for a worse one.',
        calloutType: 'warning',
      ),
    ],
  ),
];
