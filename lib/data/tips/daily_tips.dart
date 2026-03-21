/// Daily tip model and collection of 100 financial tips.

class DailyTip {
  final String text;
  final String category;
  final String? learnMoreRoute;

  const DailyTip({
    required this.text,
    required this.category,
    this.learnMoreRoute,
  });
}

/// 100 tips across 8 categories:
/// budgeting (15), government (15), saving (15), debt (10),
/// filipino_finance (15), insurance (10), investing (10), adulting (10)
const List<DailyTip> dailyTips = [
  // ── Budgeting (15) ────────────────────────────────────────────────────────
  DailyTip(
    text: 'The 50-30-20 rule: 50% needs, 30% wants, 20% savings. Adjust based on your actual salary.',
    category: 'budgeting',
    learnMoreRoute: '/guide',
  ),
  DailyTip(
    text: 'Track every peso for one week. You\'ll be surprised where your money actually goes.',
    category: 'budgeting',
  ),
  DailyTip(
    text: 'Set up separate "envelopes" — physical or digital — for rent, food, transpo, and wants.',
    category: 'budgeting',
  ),
  DailyTip(
    text: 'Review your subscriptions monthly. Cancel anything you haven\'t used in 30 days.',
    category: 'budgeting',
  ),
  DailyTip(
    text: 'Meal prepping on Sundays can save you PHP 2,000-5,000 per month vs. eating out daily.',
    category: 'budgeting',
  ),
  DailyTip(
    text: 'Use the 24-hour rule: wait a day before buying anything over PHP 1,000. Still want it? Go ahead.',
    category: 'budgeting',
  ),
  DailyTip(
    text: 'Your budget should be realistic, not aspirational. Base it on actual spending, then adjust.',
    category: 'budgeting',
  ),
  DailyTip(
    text: 'Automate your savings — transfer to a separate account right after payday, before spending.',
    category: 'budgeting',
  ),
  DailyTip(
    text: 'Zero-based budgeting: assign every peso a job. Walang natitira na walang purpose.',
    category: 'budgeting',
  ),
  DailyTip(
    text: 'Track your "latte factor" — small daily expenses that add up. PHP 150/day coffee = PHP 4,500/month.',
    category: 'budgeting',
  ),
  DailyTip(
    text: 'Review your budget every payday, not just once a month. Kasi may 2 cutoffs ka.',
    category: 'budgeting',
  ),
  DailyTip(
    text: 'Include a "fun money" budget. Deprivation leads to binge spending.',
    category: 'budgeting',
  ),
  DailyTip(
    text: 'Use cash for categories you tend to overspend on. Harder to swipe = less spending.',
    category: 'budgeting',
  ),
  DailyTip(
    text: 'Holiday spending? Budget for it months ahead. Set aside PHP 500-1,000/month starting January.',
    category: 'budgeting',
  ),
  DailyTip(
    text: 'Your budget is a plan, not a prison. Adjust when life happens — just track the changes.',
    category: 'budgeting',
  ),

  // ── Government (15) ───────────────────────────────────────────────────────
  DailyTip(
    text: 'Pwede ka mag-volunteer sa SSS contribution — kahit hindi ka employed.',
    category: 'government',
    learnMoreRoute: '/tools',
  ),
  DailyTip(
    text: 'Your Pag-IBIG MP2 fund earns 6-7% dividends annually — tax-free. Better than most savings accounts.',
    category: 'government',
    learnMoreRoute: '/tools',
  ),
  DailyTip(
    text: 'SSS salary loan: borrow up to 2 months\' salary at 10% interest per year. Lower than most banks.',
    category: 'government',
  ),
  DailyTip(
    text: 'PhilHealth covers up to PHP 140,000 for major surgeries. Make sure your contributions are updated.',
    category: 'government',
  ),
  DailyTip(
    text: 'Register your TIN online at BIR eReg — no need to visit a BIR office.',
    category: 'government',
    learnMoreRoute: '/guide',
  ),
  DailyTip(
    text: 'SSS sickness benefit: get 90% of your daily salary for up to 120 days if hospitalized.',
    category: 'government',
  ),
  DailyTip(
    text: 'Pag-IBIG housing loan rates start at 6.5% — much lower than bank housing loans at 7-9%.',
    category: 'government',
  ),
  DailyTip(
    text: 'You can check your SSS contributions online at My.SSS — create an account if you haven\'t.',
    category: 'government',
  ),
  DailyTip(
    text: 'PhilHealth premiums are income-based now. Even minimum wage earners get full coverage.',
    category: 'government',
  ),
  DailyTip(
    text: 'SSS maternity benefit: 100% of daily salary for 105 days (live birth). File before delivery.',
    category: 'government',
  ),
  DailyTip(
    text: 'Pag-IBIG calamity loan: borrow up to 80% of your total savings at 5.95% interest after a calamity.',
    category: 'government',
  ),
  DailyTip(
    text: 'Your employer must remit your SSS, PhilHealth, and Pag-IBIG contributions. Check your records.',
    category: 'government',
  ),
  DailyTip(
    text: 'SSS retirement pension requires at least 120 monthly contributions. Start early para malaki pension mo.',
    category: 'government',
  ),
  DailyTip(
    text: 'Freelancers can register as voluntary members for SSS, PhilHealth, and Pag-IBIG.',
    category: 'government',
    learnMoreRoute: '/guide',
  ),
  DailyTip(
    text: 'Pag-IBIG regular savings can be withdrawn after 20 years or at age 60 — with dividends.',
    category: 'government',
  ),

  // ── Saving (15) ───────────────────────────────────────────────────────────
  DailyTip(
    text: 'Build a 3-6 month emergency fund first before investing. Cover your basics.',
    category: 'saving',
    learnMoreRoute: '/guide',
  ),
  DailyTip(
    text: 'High-yield digital bank accounts offer 4-6% interest vs. 0.25% at traditional banks.',
    category: 'saving',
  ),
  DailyTip(
    text: 'Pay yourself first: save BEFORE spending, not after. Treat savings like a non-negotiable bill.',
    category: 'saving',
  ),
  DailyTip(
    text: 'The PHP 20 challenge: save PHP 20 on day 1, PHP 40 on day 2... That\'s PHP 10,100 in 30 days!',
    category: 'saving',
  ),
  DailyTip(
    text: 'Keep your emergency fund in a separate bank — out of sight, out of mind, out of temptation.',
    category: 'saving',
  ),
  DailyTip(
    text: 'Automate transfers to your savings account every payday. Remove the decision from the equation.',
    category: 'saving',
  ),
  DailyTip(
    text: 'Save your windfalls: bonuses, 13th month, tax refunds. Pretend you never got them.',
    category: 'saving',
  ),
  DailyTip(
    text: 'A "sinking fund" is savings for planned expenses — gadgets, travel, gifts. Not an emergency fund.',
    category: 'saving',
  ),
  DailyTip(
    text: 'Round up your expenses and save the difference. PHP 247 lunch? Save PHP 3. It adds up.',
    category: 'saving',
  ),
  DailyTip(
    text: 'Your 13th month pay is legally mandated. Save at least half of it — future you will thank you.',
    category: 'saving',
  ),
  DailyTip(
    text: 'No-spend days: pick 1-2 days a week where you spend nothing. Great for building the habit.',
    category: 'saving',
  ),
  DailyTip(
    text: 'Set specific savings goals with deadlines. "PHP 50,000 by December" beats "I want to save more."',
    category: 'saving',
  ),
  DailyTip(
    text: 'Compare prices before buying anything over PHP 500. A quick search can save you 20-40%.',
    category: 'saving',
  ),
  DailyTip(
    text: 'Unsubscribe from sale notifications. You don\'t save 50% — you spend 50%.',
    category: 'saving',
  ),
  DailyTip(
    text: 'Cook at home more. Pag nagluto ka, nase-save mo PHP 100-200 per meal vs. food delivery.',
    category: 'saving',
  ),

  // ── Debt (10) ─────────────────────────────────────────────────────────────
  DailyTip(
    text: 'Pay more than the minimum on credit cards. Minimum payments can take 10+ years to pay off.',
    category: 'debt',
    learnMoreRoute: '/tools',
  ),
  DailyTip(
    text: 'Avalanche method: pay off highest-interest debt first. Saves the most money overall.',
    category: 'debt',
  ),
  DailyTip(
    text: 'Snowball method: pay off smallest debt first for quick wins. Great for motivation.',
    category: 'debt',
  ),
  DailyTip(
    text: 'Credit card interest rates in PH average 2-3.5% per MONTH — that\'s 24-42% per year.',
    category: 'debt',
  ),
  DailyTip(
    text: 'Balance transfer promos can save you thousands. Move high-interest debt to a 0% intro rate card.',
    category: 'debt',
  ),
  DailyTip(
    text: 'Never borrow from 5-6 (informal lenders). 20% monthly interest = 240% per year.',
    category: 'debt',
  ),
  DailyTip(
    text: 'Consolidate multiple debts into one lower-interest loan. Simplify and save.',
    category: 'debt',
  ),
  DailyTip(
    text: 'Before taking on debt, ask: "Will this make me money or cost me money?" Only borrow for assets.',
    category: 'debt',
  ),
  DailyTip(
    text: 'Your SSS salary loan has one of the lowest rates available. Consider it before banks.',
    category: 'debt',
  ),
  DailyTip(
    text: 'If you\'re drowning in debt, list everything out. Knowing the full picture is step one.',
    category: 'debt',
    learnMoreRoute: '/tools',
  ),

  // ── Filipino Finance (15) ─────────────────────────────────────────────────
  DailyTip(
    text: 'Ang 13th month pay ay mandatory sa lahat ng rank-and-file employees. Know your rights.',
    category: 'filipino_finance',
  ),
  DailyTip(
    text: 'GCash and Maya savings features earn 4-6% interest — way better than regular savings accounts.',
    category: 'filipino_finance',
  ),
  DailyTip(
    text: 'If your annual income is under PHP 250,000, you\'re exempt from income tax.',
    category: 'filipino_finance',
  ),
  DailyTip(
    text: 'Retail Treasury Bonds (RTBs) from the government start at PHP 5,000. Low risk, decent returns.',
    category: 'filipino_finance',
  ),
  DailyTip(
    text: 'Padala fees eat into OFW remittances. Compare rates — some services charge 50% less than others.',
    category: 'filipino_finance',
  ),
  DailyTip(
    text: 'CIMB, Maya, and Tonik offer higher interest rates than BDO or BPI. Insured by PDIC up to PHP 500K.',
    category: 'filipino_finance',
  ),
  DailyTip(
    text: 'Salary loans from your company are usually interest-free. Check your HR policies.',
    category: 'filipino_finance',
  ),
  DailyTip(
    text: 'If you\'re a freelancer, register as a self-employed individual with BIR to file taxes properly.',
    category: 'filipino_finance',
  ),
  DailyTip(
    text: 'The BSP has a free financial literacy program. Check their website for schedules.',
    category: 'filipino_finance',
  ),
  DailyTip(
    text: 'Cooperatives often offer better loan rates than banks. Check NATCCO member coops near you.',
    category: 'filipino_finance',
  ),
  DailyTip(
    text: 'PDIC insures your bank deposits up to PHP 500,000 per bank. Spread larger amounts across banks.',
    category: 'filipino_finance',
  ),
  DailyTip(
    text: 'Service charge in restaurants is not the same as tip. It goes to the company, not the server.',
    category: 'filipino_finance',
  ),
  DailyTip(
    text: 'E-wallet limits: GCash fully verified = PHP 500K monthly. Make sure your account is verified.',
    category: 'filipino_finance',
  ),
  DailyTip(
    text: 'Your separation pay = 1 month salary per year of service if terminated without just cause.',
    category: 'filipino_finance',
  ),
  DailyTip(
    text: 'Night differential pay: 10% extra for work between 10 PM and 6 AM. Check your payslip.',
    category: 'filipino_finance',
  ),

  // ── Insurance (10) ────────────────────────────────────────────────────────
  DailyTip(
    text: 'Term life insurance is cheaper and simpler than VUL. Consider it if you just need coverage.',
    category: 'insurance',
    learnMoreRoute: '/tools',
  ),
  DailyTip(
    text: 'Your ideal life insurance coverage = 10x your annual income. Enough to replace your earnings.',
    category: 'insurance',
  ),
  DailyTip(
    text: 'Health insurance (HMO) is different from PhilHealth. HMO covers outpatient; PhilHealth is for inpatient.',
    category: 'insurance',
  ),
  DailyTip(
    text: 'Read your insurance policy\'s exclusions. Pre-existing conditions are often not covered initially.',
    category: 'insurance',
  ),
  DailyTip(
    text: 'VUL (Variable Unit-Linked) = insurance + investment. Often has high fees — understand before buying.',
    category: 'insurance',
  ),
  DailyTip(
    text: 'Get insurance while you\'re young and healthy. Premiums increase with age and health conditions.',
    category: 'insurance',
  ),
  DailyTip(
    text: 'Critical illness coverage pays a lump sum upon diagnosis. Separate from hospitalization benefits.',
    category: 'insurance',
  ),
  DailyTip(
    text: 'If you have dependents, life insurance is not optional — it\'s a responsibility.',
    category: 'insurance',
  ),
  DailyTip(
    text: 'Group insurance from your employer is a perk, not a permanent plan. Get your own policy too.',
    category: 'insurance',
  ),
  DailyTip(
    text: 'Car insurance: comprehensive > third-party liability only. The price difference is worth it.',
    category: 'insurance',
  ),

  // ── Investing (10) ────────────────────────────────────────────────────────
  DailyTip(
    text: 'Start investing with as little as PHP 1,000 through UITF or mutual funds from your bank.',
    category: 'investing',
  ),
  DailyTip(
    text: 'Index funds have lower fees than actively managed funds — and often perform better long-term.',
    category: 'investing',
  ),
  DailyTip(
    text: 'Peso cost averaging: invest a fixed amount regularly regardless of market price. Removes emotion.',
    category: 'investing',
  ),
  DailyTip(
    text: 'Never invest money you\'ll need within 5 years. The stock market is for long-term goals.',
    category: 'investing',
  ),
  DailyTip(
    text: 'Diversify: don\'t put all your money in one stock or one type of investment.',
    category: 'investing',
  ),
  DailyTip(
    text: 'GInvest, SeedIn, and Tonik TD are easy ways to start investing with small amounts.',
    category: 'investing',
  ),
  DailyTip(
    text: 'Time in the market beats timing the market. Start now, stay consistent.',
    category: 'investing',
  ),
  DailyTip(
    text: 'Government bonds (T-bills, RTBs) are the safest investments in the Philippines.',
    category: 'investing',
  ),
  DailyTip(
    text: 'FMETF is the only exchange-traded fund in PSE. Low fees, tracks the PSEi index.',
    category: 'investing',
  ),
  DailyTip(
    text: 'Know your risk tolerance before investing. Aggressive? Stocks. Conservative? Bonds and TDs.',
    category: 'investing',
  ),

  // ── Adulting (10) ─────────────────────────────────────────────────────────
  DailyTip(
    text: 'Get your government IDs early: SSS, PhilHealth, Pag-IBIG, TIN, postal ID, national ID.',
    category: 'adulting',
    learnMoreRoute: '/guide',
  ),
  DailyTip(
    text: 'Keep digital copies of all your important documents. Store in a secure cloud folder.',
    category: 'adulting',
  ),
  DailyTip(
    text: 'Learn to cook 5 basic meals. Saves money and keeps you healthier than fast food every day.',
    category: 'adulting',
  ),
  DailyTip(
    text: 'Build your credit history early. A simple credit card paid in full monthly does the trick.',
    category: 'adulting',
  ),
  DailyTip(
    text: 'Create a simple filing system for receipts, contracts, and important papers. Digital or physical.',
    category: 'adulting',
  ),
  DailyTip(
    text: 'Know your employment contract. Understand your benefits, leave credits, and termination clauses.',
    category: 'adulting',
  ),
  DailyTip(
    text: 'Set up autopay for regular bills to avoid late fees and maintain good payment history.',
    category: 'adulting',
  ),
  DailyTip(
    text: 'Your first apartment? Budget for deposit (2 months), advance (1 month), AND moving costs.',
    category: 'adulting',
  ),
  DailyTip(
    text: 'Negotiate your salary. Research market rates on JobStreet, Glassdoor, or Kalibrr before interviews.',
    category: 'adulting',
  ),
  DailyTip(
    text: 'Regularly update your resume even when not job hunting. You never know when opportunity knocks.',
    category: 'adulting',
  ),
];
