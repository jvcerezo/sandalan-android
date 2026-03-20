import '../guide_data.dart';

final List<GuideArticle> kPundasyonGuides = [
  GuideArticle(
    slug: 'emergency-fund-101',
    title: 'Emergency Fund 101',
    readMinutes: 5,
    category: 'financial-literacy',
    toolLinks: ['goals'],
    sections: [
      GuideSection(
        title: 'Why you need one before anything else',
        content:
            'An emergency fund is money set aside for the unexpected: a medical bill, job loss, broken phone, or urgent family need. Without one, any surprise expense forces you into debt \u2014 credit cards at 24\u201336% interest, 5-6 loans from coworkers, or predatory lending apps. Building an emergency fund is the single most important financial step you can take.',
        callout:
            '60.7% of Filipinos cannot cover a P20,000 emergency expense. Don\u2019t be part of that statistic.',
        calloutType: 'warning',
      ),
      GuideSection(
        title: 'How much do you need?',
        content:
            'The standard advice is 3\u20136 months of essential living expenses. But start with a more achievable target:',
        items: [
          'Starter goal: P10,000\u2013P20,000 (covers most common emergencies)',
          'Minimum target: 3 months of living expenses (single, stable job)',
          'Ideal target: 6 months of living expenses (freelancer, breadwinner, or dependents)',
          'Formula: Monthly expenses (rent + food + transport + utilities + insurance) \u00d7 target months',
        ],
      ),
      GuideSection(
        title: 'Where to keep it',
        content:
            'Your emergency fund must be liquid (accessible within 24 hours) but not too easy to spend. Best options:',
        items: [
          'High-yield digital savings: ING (4% p.a.), CIMB (4.5%), Maya (3.5%), Tonik (4%) \u2014 no maintaining balance, PDIC-insured',
          'Separate from your spending account \u2014 open a dedicated \u2018EF\u2019 savings account so you don\u2019t accidentally spend it',
          'Not in investments: Stocks, UITFs, or crypto are NOT emergency funds. They can lose value when you need them most',
          'Not in time deposits: You can\u2019t withdraw without penalty before maturity',
        ],
        callout:
            'Open a separate high-yield digital bank account just for your emergency fund. Name it \u2018DO NOT TOUCH\u2019 if that helps. The slight friction of transferring money out helps prevent impulse withdrawals.',
        calloutType: 'tip',
      ),
      GuideSection(
        title: 'Building it on a tight salary',
        content:
            'Even on P15,000\u2013P25,000/month, you can build an emergency fund. The key is automation and consistency, not large amounts:',
        items: [
          'P500/payday = P1,000/month = P12,000/year (a solid starter emergency fund)',
          'P1,000/payday = P2,000/month = P24,000/year (almost 2 months\u2019 expenses for a frugal lifestyle)',
          'Set up auto-transfer from your payroll bank on payday \u2014 \u2018pay yourself first\u2019 before you spend anything',
          'Funnel windfalls: 13th month, bonuses, tax refunds, and monetary gifts go straight to EF until it\u2019s funded',
        ],
      ),
      GuideSection(
        title: 'Track your runway',
        content:
            'Create an Emergency Fund goal in Sandalan. Set your target amount (monthly expenses \u00d7 3 or 6) and log every deposit. The goal tracker shows your progress and tells you how many months of coverage you have. Watching the bar fill up is genuinely motivating.',
      ),
    ],
  ),
  GuideArticle(
    slug: 'investing-for-beginners',
    title: 'Investing 101 for Filipinos',
    readMinutes: 6,
    category: 'investing',
    toolLinks: ['calculators', 'goals'],
    sections: [
      GuideSection(
        title: 'When to start investing',
        content:
            'Only invest after you have: (1) an emergency fund covering 3\u20136 months of expenses, (2) no high-interest debt (credit cards, lending apps), and (3) adequate insurance. Investing before these foundations are in place is like building a house on sand.',
        callout:
            'Never invest your emergency fund. Investments can lose value. Your EF must be 100% liquid and safe.',
        calloutType: 'warning',
      ),
      GuideSection(
        title: 'The investment ladder for Filipinos',
        content:
            'Start at the bottom (safest, lowest returns) and climb up as your knowledge and risk tolerance grow:',
        items: [
          'Rung 1 \u2014 Pag-IBIG MP2: 6\u20137% annual dividends, tax-free, government-backed. Minimum P500. Best guaranteed return in the Philippines. Start here.',
          'Rung 2 \u2014 Money Market Funds / Bond Funds: UITFs available through BDO, BPI, UnionBank. Low risk, 3\u20135% returns. Minimum P1,000\u2013P10,000.',
          'Rung 3 \u2014 Balanced Funds: Mix of bonds and stocks. Moderate risk, 5\u20138% historical returns. Good for 3\u20135 year goals.',
          'Rung 4 \u2014 Equity Funds / Index Funds: Invest in the Philippine stock market without picking stocks. Higher risk, 8\u201312% long-term returns. Minimum 5\u201310 year horizon.',
          'Rung 5 \u2014 Direct Stock Market (PSE): Buy individual stocks through COL Financial, BDO Nomura, or First Metro. Requires learning and monitoring. Only with money you won\u2019t need for 10+ years.',
        ],
      ),
      GuideSection(
        title: 'Pag-IBIG MP2: The best-kept secret',
        content:
            'MP2 is a voluntary savings program from Pag-IBIG that has consistently delivered 6\u20137% annual dividends \u2014 completely tax-free. It\u2019s arguably the best guaranteed return available to any Filipino. The 5-year maturity period locks your money in, but you can withdraw dividends annually. After 5 years, you can renew or withdraw everything.',
        callout:
            'You can enroll in MP2 through Virtual Pag-IBIG with just P500. Set up auto-debit and forget about it. In 5 years, you\u2019ll thank yourself.',
        calloutType: 'tip',
      ),
      GuideSection(
        title: 'The magic of compound interest',
        content:
            'If you invest P2,000/month starting at age 23 at 7% annual returns (MP2-equivalent), you\u2019ll have approximately P2,400,000 by age 45 \u2014 you only contributed P528,000. The rest is compound interest. Starting 5 years later (at 28) with the same amount gives you only P1,500,000. Time is your biggest advantage.',
      ),
      GuideSection(
        title: 'Common mistakes to avoid',
        content: 'Filipino investors frequently make these errors:',
        items: [
          'Buying VUL (Variable Universal Life) as your \u2018investment\u2019: VUL mixes insurance and investing, resulting in high fees and mediocre returns for both. Get term insurance + separate investments instead.',
          'Investing based on social media tips: Don\u2019t buy stocks because someone on TikTok said to. Do your own research.',
          'Panic selling during market drops: The PSE drops 10\u201320% regularly. If you\u2019re investing for 10+ years, downturns are buying opportunities.',
          'Not diversifying: Don\u2019t put everything in one stock or one investment type. Spread across MP2, UITFs, and equities.',
        ],
      ),
    ],
  ),
  GuideArticle(
    slug: 'credit-building',
    title: 'Building Your Credit Score',
    readMinutes: 4,
    category: 'financial-literacy',
    toolLinks: ['debts'],
    sections: [
      GuideSection(
        title: 'Philippine credit scores explained',
        content:
            'The Credit Information Corporation (CIC) maintains credit records for all Filipinos. Your score ranges from 300\u2013850. Banks and lenders check this score when you apply for credit cards, personal loans, home loans, and car loans. A score above 700 is considered good for approval with favorable rates.',
      ),
      GuideSection(
        title: 'How to check your score',
        content:
            'You can check your CIC credit score for free twice per year using the CIC App 3.0 (available on Android and iOS). You\u2019ll need a valid government ID to register. Your report shows all credit accounts, payment history, and inquiries from lenders.',
        callout:
            'Under Republic Act No. 9510, every Filipino has the right to access their credit information from the CIC. Lenders must report to the CIC and are required to inform you if they deny credit based on your CIC record.',
        calloutType: 'ph-law',
      ),
      GuideSection(
        title: 'Building credit from scratch',
        content:
            'If you have no credit history (common for fresh graduates), here\u2019s how to build it:',
        items: [
          'Start with a secured credit card: Deposit P2,000\u2013P10,000 as collateral and get a credit card with that limit. BPI, Security Bank, and RCBC offer these.',
          'Use it for small, regular purchases: Groceries, gas, subscriptions. Spend 10\u201330% of your limit.',
          'Pay the full balance every billing cycle: This costs you P0 in interest and builds a perfect payment history.',
          'After 6\u201312 months: Apply for a regular credit card. Your payment history from the secured card will support your application.',
        ],
      ),
      GuideSection(
        title: 'The golden rules of credit',
        content:
            'Credit is a powerful tool when used correctly, and a dangerous trap when misused:',
        items: [
          'Always pay the full balance \u2014 minimum payments trap you in 24\u201336% annual interest',
          'Never use more than 30% of your credit limit (utilization ratio affects your score)',
          'Never use credit cards for cash advances (25\u201330% interest + additional fees)',
          'Set up auto-pay for at least the minimum payment to avoid late fees',
          'Don\u2019t apply for multiple credit cards at once \u2014 each application creates an inquiry that temporarily lowers your score',
        ],
      ),
    ],
  ),
  GuideArticle(
    slug: 'freelancer-tax-guide',
    title: 'The Filipino Freelancer Tax Guide',
    readMinutes: 6,
    category: 'government',
    toolLinks: ['taxes', 'calculators'],
    sections: [
      GuideSection(
        title: 'If you earn outside of employment, you must register',
        content:
            'Any income from freelancing, consulting, online selling, content creation, or side businesses requires BIR registration. The BIR has been actively cracking down on unregistered digital earners and influencers. Penalties for non-compliance include 25% surcharge, 12% annual interest, and potential criminal charges going back 3\u201310 years.',
        callout:
            'Saying \u2018I didn\u2019t know\u2019 is not a defense. The BIR has filed cases against freelancers and online sellers who failed to register. Register now before you get caught.',
        calloutType: 'warning',
      ),
      GuideSection(
        title: 'How to register as a freelancer',
        content:
            'Step-by-step BIR registration for self-employed individuals:',
        items: [
          '1. Go to your local Revenue District Office (RDO) based on your home address',
          '2. File BIR Form 1901 with: TIN, valid government ID, birth certificate, proof of business address',
          '3. Pay the P500 annual registration fee (abolished from 2025 onward) and P30 documentary stamp tax',
          '4. Register your books of accounts (you can buy blank books from bookstores)',
          '5. Get authority to print Official Receipts (OR) or use BIR\u2019s electronic invoicing system',
          '6. You\u2019re now registered. File quarterly and annual tax returns on time.',
        ],
      ),
      GuideSection(
        title: '8% flat tax vs graduated rates',
        content:
            'If your annual gross receipts are P3,000,000 or below, you can choose the 8% flat income tax rate instead of the graduated rates (0\u201335%). The 8% rate is computed on gross receipts exceeding P250,000 (the tax-free threshold). For most freelancers earning under P3M/year, the 8% option is simpler and often cheaper.',
        items: [
          '8% flat tax: 8% \u00d7 (gross receipts - P250,000). No need to track itemized expenses.',
          'Graduated rates + OSD: Net income \u00d7 tax bracket rate. You can deduct 40% of gross as Optional Standard Deduction.',
          'Example: P500,000 gross receipts \u2192 8% flat tax = P20,000. Graduated with OSD \u2192 P17,500. Compare both before choosing.',
        ],
        callout:
            'You must elect your tax option at the start of the year. Once chosen, you can\u2019t switch until the next tax year. Use the Tax Calculator to compare both options for your income level.',
        calloutType: 'tip',
      ),
      GuideSection(
        title: 'Filing deadlines (don\u2019t miss these)',
        content:
            'Self-employed individuals must file these returns on time. Late filing incurs automatic penalties:',
        items: [
          'Quarterly Income Tax (Form 1701Q): May 15, August 15, November 15',
          'Annual Income Tax (Form 1701): April 15',
          'Quarterly Percentage Tax (Form 2551Q): April 25, July 25, October 25, January 25 \u2014 only if NOT using 8% flat tax',
          'You must file even if you had zero income for the quarter',
        ],
      ),
    ],
  ),
];
