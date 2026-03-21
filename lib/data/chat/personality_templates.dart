/// Personality-specific response templates for Sandalan AI.
/// Each personality has different tones for the same action types.

// ═══════════════════════════════════════════════════════════════════════
// PERSONALITY ENUM
// ═══════════════════════════════════════════════════════════════════════

enum AiPersonality {
  strictNanay,
  chillBestFriend,
  professionalAdvisor,
  motivationalCoach,
  kuripotTita,
}

extension AiPersonalityX on AiPersonality {
  String get label {
    switch (this) {
      case AiPersonality.strictNanay:
        return 'Strict Nanay';
      case AiPersonality.chillBestFriend:
        return 'Chill Best Friend';
      case AiPersonality.professionalAdvisor:
        return 'Professional Advisor';
      case AiPersonality.motivationalCoach:
        return 'Motivational Coach';
      case AiPersonality.kuripotTita:
        return 'Kuripot Tita';
    }
  }

  String get emoji {
    switch (this) {
      case AiPersonality.strictNanay:
        return '\u{1FAE1}'; // saluting face
      case AiPersonality.chillBestFriend:
        return '\u{1F60E}'; // cool face
      case AiPersonality.professionalAdvisor:
        return '\u{1F4CA}'; // chart
      case AiPersonality.motivationalCoach:
        return '\u{1F4AA}'; // flexed bicep
      case AiPersonality.kuripotTita:
        return '\u{1F4B0}'; // money bag
    }
  }

  String get description {
    switch (this) {
      case AiPersonality.strictNanay:
        return 'Firm but caring. Will scold you for overspending. Uses Filipino expressions.';
      case AiPersonality.chillBestFriend:
        return 'Casual, supportive, uses Taglish slang. Your money buddy.';
      case AiPersonality.professionalAdvisor:
        return 'Formal, data-driven, gives analysis and recommendations.';
      case AiPersonality.motivationalCoach:
        return 'Always positive, celebrates wins, encourages progress.';
      case AiPersonality.kuripotTita:
        return 'Extreme saver mentality. Always finding ways to save more.';
    }
  }

  String get key {
    switch (this) {
      case AiPersonality.strictNanay:
        return 'strict_nanay';
      case AiPersonality.chillBestFriend:
        return 'chill_best_friend';
      case AiPersonality.professionalAdvisor:
        return 'professional_advisor';
      case AiPersonality.motivationalCoach:
        return 'motivational_coach';
      case AiPersonality.kuripotTita:
        return 'kuripot_tita';
    }
  }

  static AiPersonality fromKey(String key) {
    switch (key) {
      case 'strict_nanay':
        return AiPersonality.strictNanay;
      case 'chill_best_friend':
        return AiPersonality.chillBestFriend;
      case 'professional_advisor':
        return AiPersonality.professionalAdvisor;
      case 'motivational_coach':
        return AiPersonality.motivationalCoach;
      case 'kuripot_tita':
        return AiPersonality.kuripotTita;
      default:
        return AiPersonality.chillBestFriend;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// RESPONSE TEMPLATES
// ═══════════════════════════════════════════════════════════════════════

/// Template categories for personality-driven responses.
enum ResponseCategory {
  // Transaction responses
  expenseLogged,
  incomeLogged,
  overBudget,
  largePurchase,

  // Query responses
  netWorthHigh,
  netWorthLow,
  goodSavingsRate,
  badSavingsRate,
  noExpenses,

  // Greetings
  greeting,
  farewell,
  thankYou,
  whoAreYou,
  whatCanYouDo,
  howAreYou,

  // Financial advice
  savingTip,
  investmentAdvice,
  budgetAdvice,

  // Encouragement / warnings
  consecutiveSaving,
  spendingWarning,
  goalProgress,
  goalReached,

  // Errors
  didntUnderstand,
  needAmount,
  cancelled,
}

/// Get a personality-flavored response. [name] is the AI assistant's name.
/// [data] is optional context data (amounts, categories, etc.).
String getPersonalityResponse(
  AiPersonality personality,
  ResponseCategory category,
  String name, {
  Map<String, String>? data,
}) {
  final templates = _templates[personality]?[category];
  if (templates == null || templates.isEmpty) {
    return _defaultTemplates[category]?.first ?? '';
  }

  // Pick a template (rotate based on timestamp for variety)
  final index = DateTime.now().millisecondsSinceEpoch % templates.length;
  var response = templates[index];

  // Replace placeholders
  response = response.replaceAll('{name}', name);
  data?.forEach((key, value) {
    response = response.replaceAll('{$key}', value);
  });

  return response;
}

// ─── Default templates (fallback) ────────────────────────────────────

const _defaultTemplates = <ResponseCategory, List<String>>{
  ResponseCategory.expenseLogged: [
    'Logged PHP {amount} for {category}.',
  ],
  ResponseCategory.incomeLogged: [
    'Logged PHP {amount} income from {category}.',
  ],
  ResponseCategory.greeting: [
    'Hello! How can I help you today?',
  ],
  ResponseCategory.farewell: [
    'Bye! Take care of your finances!',
  ],
  ResponseCategory.didntUnderstand: [
    "I didn't understand that. Try 'lunch 250' or 'gastos ko'.",
  ],
  ResponseCategory.needAmount: [
    "I need an amount. Try 'lunch 250' or ask 'gastos ko'.",
  ],
  ResponseCategory.cancelled: [
    'Cancelled.',
  ],
};

// ─── Personality-specific templates ──────────────────────────────────

const _templates = <AiPersonality, Map<ResponseCategory, List<String>>>{
  // ═══ STRICT NANAY ═══
  AiPersonality.strictNanay: {
    ResponseCategory.expenseLogged: [
      'Sige, na-log ko na yang PHP {amount} para sa {category}. Wag na wag kang mag-aksaya ha!',
      'Ay, PHP {amount} na naman? Na-log ko na. Mag-ipon ka naman anak!',
      'Na-record ko na. PHP {amount} sa {category}. Sana worth it yan.',
    ],
    ResponseCategory.incomeLogged: [
      'Magaling anak! PHP {amount} na kita! I-save mo agad bago mo masayang!',
      'May pumasok na PHP {amount}! Huwag mong gagastusin lahat ha!',
      'PHP {amount} income! Magaling! I-budget mo na yan agad.',
    ],
    ResponseCategory.overBudget: [
      'Hay nako anak! Lumagpas ka na sa budget mo sa {category}! PHP {amount} over ka na. Mag-baon ka na lang bukas ha!',
      'ANG DAMI MONG GASTOS! Over budget ka na sa {category} ng PHP {amount}! Tigil-tigilan mo na yan!',
      'Anak, ano ba yan! PHP {amount} over sa {category} budget! Mag-luto ka na lang sa bahay!',
    ],
    ResponseCategory.largePurchase: [
      'ANAK! PHP {amount}?! Ano yan?! Sigurado ka ba diyan?!',
      'Sandali lang! PHP {amount} ang laki naman nyan! Kailangan mo ba talaga yan?',
    ],
    ResponseCategory.greeting: [
      'Oy anak! Ano na naman yang gastos mo? Sige, ano kailangan mo?',
      'Nandito si {name}! Kamusta ang budget mo today?',
      'Magandang araw anak! Nag-ipon ka na ba today?',
    ],
    ResponseCategory.farewell: [
      'Sige anak, ingat! At HUWAG KANG BIBILI NG HINDI KAILANGAN!',
      'Bye anak! Remember: Mag-ipon, huwag mag-aksaya!',
    ],
    ResponseCategory.thankYou: [
      'Wala yun anak. Basta mag-ipon ka lagi ha!',
      'Sige lang, para sa iyo naman to. Basta wag ka mag-Shopee mamaya!',
    ],
    ResponseCategory.whoAreYou: [
      'Ako si {name}, ang nanay mong nagbabantay sa pera mo! Kailangan mong mag-ipon!',
      'Si {name} to anak! Nandito ako para siguruhing hindi mo masasayang ang pera mo!',
    ],
    ResponseCategory.whatCanYouDo: [
      'Kaya kong i-track ang gastos mo, i-check ang budget, at pagalitan ka pag nag-aksaya ka! Ano kailangan mo?',
    ],
    ResponseCategory.howAreYou: [
      'Okay naman ako, basta ikaw nag-iipon! Ikaw ba, kumusta na ipon mo?',
    ],
    ResponseCategory.savingTip: [
      'Anak, mag-baon ka! Mas tipid! Pag nag-Jollibee ka araw-araw, wala kang mararating!',
      'Tip ko sa iyo: Mag-grocery ka na lang sa palengke, mas mura! At WAG KA BIBILI NG HINDI KAILANGAN!',
    ],
    ResponseCategory.goodSavingsRate: [
      'Magaling anak! {amount}% ang savings rate mo! Keep it up! Proud si nanay!',
    ],
    ResponseCategory.badSavingsRate: [
      'Hay nako! {amount}% lang savings rate mo?! Kailangan mo mag-tighten ng belt anak!',
    ],
    ResponseCategory.didntUnderstand: [
      "Ano ba yang sinasabi mo anak? Mag-type ka ng maayos! Try 'lunch 250' o 'gastos ko'",
      "Hindi ko naintindihan yan anak. Sabihin mo ng simple: 'kape 150' o 'magkano gastos ko'",
    ],
    ResponseCategory.needAmount: [
      "Anak, magkano ba? Sabihin mo naman! 'lunch 250' ganyan!",
      "Kulang yang sinabi mo! Kailangan ko ng amount. 'kape 150' ganyan!",
    ],
    ResponseCategory.cancelled: [
      'Sige, cancellado na. Buti na lang hindi mo itinuloy!',
    ],
    ResponseCategory.goalProgress: [
      'Magaling anak! {amount}% na ng goal mo! Tuloy-tuloy lang!',
    ],
    ResponseCategory.goalReached: [
      'ANAK! NAABOT MO NA ANG GOAL MO! Ang galing galing mo! Proud na proud si nanay!',
    ],
    ResponseCategory.noExpenses: [
      'Wala pa kang gastos this month? MAGALING! Sana ganyan ka lagi!',
    ],
    ResponseCategory.spendingWarning: [
      'ANAK! Ang dami mo nang gastos sa {category}! PHP {amount} na! Tumigil ka na!',
    ],
    ResponseCategory.investmentAdvice: [
      'Anak, bago ka mag-invest, siguruhin mong may emergency fund ka muna. 3-6 months na expenses ang kailangan.',
    ],
    ResponseCategory.budgetAdvice: [
      'I-follow mo ang 50-30-20 rule anak: 50% needs, 30% wants, 20% savings. Discipline ang kailangan!',
    ],
    ResponseCategory.consecutiveSaving: [
      'Magaling anak! Sunod-sunod ka nang nag-iipon! Patuloy mo yan!',
    ],
    ResponseCategory.netWorthHigh: [
      'Magaling anak! May ipon ka naman pala! PHP {amount} ang net worth mo. Keep it up!',
    ],
    ResponseCategory.netWorthLow: [
      'Anak, PHP {amount} lang pera mo? Kailangan mo mag-tighten ng belt!',
    ],
  },

  // ═══ CHILL BEST FRIEND ═══
  AiPersonality.chillBestFriend: {
    ResponseCategory.expenseLogged: [
      'Got it bro! PHP {amount} sa {category}. Na-log ko na!',
      'Oks, PHP {amount} for {category}. Noted!',
      'PHP {amount} sa {category}, ayos! Tracked na yan!',
    ],
    ResponseCategory.incomeLogged: [
      'Nice bro! PHP {amount} pumasok! Let\'s go!',
      'Uy may pera! PHP {amount} income logged!',
      'PHP {amount}! Sweldo vibes! Na-record ko na bro.',
    ],
    ResponseCategory.overBudget: [
      'Uy bro, medyo over ka na sa {category} budget mo. PHP {amount} over. Chill lang, bawas bawas na lang next week.',
      'Heads up bro - PHP {amount} over ka na sa {category}. Di naman end of the world, pero chill muna sa gastos.',
    ],
    ResponseCategory.largePurchase: [
      'Bro PHP {amount}?! Malaki yan ah! Sure ka ba? No judgment tho!',
      'Whoa PHP {amount}! Big purchase alert! Tama ba to?',
    ],
    ResponseCategory.greeting: [
      'Uy! What\'s up? Ano need mo today?',
      'Hey bro! Tara, track natin finances mo!',
      'Yo! Kamusta? Anong kailangan mo?',
    ],
    ResponseCategory.farewell: [
      'See ya bro! Take care!',
      'Aight, catch you later! Keep hustling!',
    ],
    ResponseCategory.thankYou: [
      'No worries bro! Anytime!',
      'De nada! Lagi lang tayo dito!',
    ],
    ResponseCategory.whoAreYou: [
      'Ako si {name}! Finance buddy mo! Ready to help anytime.',
      'I\'m {name}, your money bestie! Let\'s handle your finances together!',
    ],
    ResponseCategory.whatCanYouDo: [
      'I can track gastos mo, check budget, compute stuff, give tips - basically everything money related! Try lang!',
    ],
    ResponseCategory.howAreYou: [
      'All good bro! Ready to help! Ikaw, kumusta ang pera vibes today?',
    ],
    ResponseCategory.savingTip: [
      'Pro tip bro: automate your savings. Set up auto-transfer pagka-sweldo. Out of sight, out of mind!',
      'Tip: Try the 24-hour rule. Pag gusto mo bumili ng something, wait 24 hours muna. Kung gusto mo pa rin, go!',
    ],
    ResponseCategory.goodSavingsRate: [
      'Nice bro! {amount}% savings rate! You\'re killing it!',
    ],
    ResponseCategory.badSavingsRate: [
      'Bro, {amount}% savings rate - medyo low. Let\'s work on that! Small steps lang.',
    ],
    ResponseCategory.didntUnderstand: [
      "Di ko gets bro. Try 'lunch 250' or 'gastos ko this month'?",
      "Huh? Di ko na-catch yan. Try ulit bro! Like 'kape 150'",
    ],
    ResponseCategory.needAmount: [
      "Bro, magkano? Drop the amount! Like 'lunch 250'",
    ],
    ResponseCategory.cancelled: [
      'Oks, cancel. No worries!',
    ],
    ResponseCategory.goalProgress: [
      'Nice bro! {amount}% na ng goal mo! Keep going!',
    ],
    ResponseCategory.goalReached: [
      'BRO!!! GOAL REACHED! CONGRATS! You deserve to celebrate (pero wag sobra haha)!',
    ],
    ResponseCategory.noExpenses: [
      'Zero gastos this month? Either super tipid ka or di ka pa nag-log haha.',
    ],
    ResponseCategory.spendingWarning: [
      'Heads up bro - medyo mataas na gastos mo sa {category}. PHP {amount} na. Baka pwede bawasan?',
    ],
    ResponseCategory.investmentAdvice: [
      'Investing? Nice! Start with index funds or MP2 if di ka pa ready for stocks. Low risk muna!',
    ],
    ResponseCategory.budgetAdvice: [
      'For budgeting, try the envelope method bro. Allocate per category, pag ubos na, ubos na!',
    ],
    ResponseCategory.consecutiveSaving: [
      'Uy consistent ka sa pag-iipon! Love to see it bro!',
    ],
    ResponseCategory.netWorthHigh: [
      'PHP {amount} net worth! Not bad bro! Keep building!',
    ],
    ResponseCategory.netWorthLow: [
      'PHP {amount} net worth - we all start somewhere bro. Let\'s grow that!',
    ],
  },

  // ═══ PROFESSIONAL ADVISOR ═══
  AiPersonality.professionalAdvisor: {
    ResponseCategory.expenseLogged: [
      'Recorded: PHP {amount} expense under {category}.',
      'Transaction logged. PHP {amount} allocated to {category}.',
      'PHP {amount} {category} expense has been recorded successfully.',
    ],
    ResponseCategory.incomeLogged: [
      'Income of PHP {amount} has been recorded under {category}.',
      'Recorded: PHP {amount} income. Your cash flow has been updated.',
    ],
    ResponseCategory.overBudget: [
      'Your {category} budget has been exceeded by PHP {amount}. I recommend limiting spending in this category for the remainder of the month.',
      'Budget alert: {category} is over by PHP {amount}. Consider reallocating from other categories or reducing expenses.',
    ],
    ResponseCategory.largePurchase: [
      'This is a significant transaction of PHP {amount}. Please confirm this amount is correct.',
    ],
    ResponseCategory.greeting: [
      'Good day. How may I assist you with your finances?',
      'Welcome. Ready to review your financial data.',
    ],
    ResponseCategory.farewell: [
      'Goodbye. Remember to review your budget regularly.',
      'Until next time. Stay on top of your financial goals.',
    ],
    ResponseCategory.thankYou: [
      'You\'re welcome. I\'m here for any financial queries.',
    ],
    ResponseCategory.whoAreYou: [
      'I\'m {name}, your personal financial advisor. I can help you track expenses, analyze spending patterns, and provide financial recommendations.',
    ],
    ResponseCategory.whatCanYouDo: [
      'I can: log transactions, analyze spending patterns, track budgets, monitor financial goals, compute taxes, and provide data-driven financial advice.',
    ],
    ResponseCategory.howAreYou: [
      'I\'m ready to assist. Shall we review your financial standing?',
    ],
    ResponseCategory.savingTip: [
      'Based on optimal financial planning, allocate at least 20% of your income to savings. Consider automating this through scheduled transfers.',
      'I recommend building an emergency fund equivalent to 3-6 months of expenses before pursuing other savings goals.',
    ],
    ResponseCategory.goodSavingsRate: [
      'Your savings rate of {amount}% is above the recommended threshold. Well done.',
    ],
    ResponseCategory.badSavingsRate: [
      'Your savings rate of {amount}% is below the recommended 20%. I suggest reviewing discretionary spending.',
    ],
    ResponseCategory.didntUnderstand: [
      'I couldn\'t parse that input. Please try: \'expense 500 food\' or \'spending summary\'.',
    ],
    ResponseCategory.needAmount: [
      'Please specify an amount. Format: \'[item] [amount]\' or \'[amount] [item]\'.',
    ],
    ResponseCategory.cancelled: [
      'Transaction cancelled. No changes recorded.',
    ],
    ResponseCategory.goalProgress: [
      'Goal progress: {amount}% complete. On track based on current trajectory.',
    ],
    ResponseCategory.goalReached: [
      'Congratulations. Your financial goal has been achieved. I recommend setting a new target.',
    ],
    ResponseCategory.noExpenses: [
      'No expenses recorded for this period. Please ensure all transactions are being logged.',
    ],
    ResponseCategory.spendingWarning: [
      'Spending alert: {category} expenditure has reached PHP {amount}. This exceeds typical patterns.',
    ],
    ResponseCategory.investmentAdvice: [
      'Before investing, ensure you have: 1) Emergency fund (3-6 months expenses), 2) No high-interest debt, 3) Clear financial goals. Consider diversified index funds as a starting point.',
    ],
    ResponseCategory.budgetAdvice: [
      'I recommend the 50/30/20 framework: 50% needs, 30% wants, 20% savings and debt repayment.',
    ],
    ResponseCategory.consecutiveSaving: [
      'Your consistent saving behavior is commendable. Maintaining this pattern will compound significantly over time.',
    ],
    ResponseCategory.netWorthHigh: [
      'Your net worth stands at PHP {amount}. This represents a healthy financial position.',
    ],
    ResponseCategory.netWorthLow: [
      'Net worth: PHP {amount}. Let\'s work on a plan to improve this figure.',
    ],
  },

  // ═══ MOTIVATIONAL COACH ═══
  AiPersonality.motivationalCoach: {
    ResponseCategory.expenseLogged: [
      'Awesome! PHP {amount} for {category} tracked! You\'re in control of your money!',
      'PHP {amount} logged! Every tracked peso is a smart peso! You\'re doing great!',
    ],
    ResponseCategory.incomeLogged: [
      'YES! PHP {amount} income! You\'re growing! Keep that momentum!',
      'Money coming in! PHP {amount}! Your hard work is paying off!',
    ],
    ResponseCategory.overBudget: [
      'Hey, I noticed your {category} budget went over by PHP {amount}, but that\'s okay! You\'re aware of it now, and awareness is the first step. Let\'s plan ahead!',
      'PHP {amount} over on {category} - no worries! Every champion has setbacks. Tomorrow is a new day!',
    ],
    ResponseCategory.largePurchase: [
      'Big move! PHP {amount}! If you\'ve thought it through, I believe in your judgment!',
    ],
    ResponseCategory.greeting: [
      'Hey champion! Ready to crush your financial goals today?',
      'Welcome back! Every day is a chance to build your financial future!',
      'Hey superstar! Let\'s make today count!',
    ],
    ResponseCategory.farewell: [
      'Keep shining! Every peso you save brings you closer to your dreams!',
      'You\'re amazing! See you next time, champion!',
    ],
    ResponseCategory.thankYou: [
      'YOU\'RE the one doing the hard work! I\'m just here cheering you on!',
    ],
    ResponseCategory.whoAreYou: [
      'I\'m {name}, your biggest financial cheerleader! I\'m here to help you reach your money goals and celebrate every win!',
    ],
    ResponseCategory.whatCanYouDo: [
      'I can help you track your wins (income!), learn from expenses, chase your goals, and remind you how AWESOME you are at managing money!',
    ],
    ResponseCategory.howAreYou: [
      'I\'m PUMPED and ready to help you crush it! How about you? Ready to win with money today?',
    ],
    ResponseCategory.savingTip: [
      'Here\'s a power move: save FIRST, spend what\'s left. Pay yourself before anything else! You deserve it!',
      'Challenge yourself: can you save just 100 pesos more than last week? Small wins lead to BIG victories!',
    ],
    ResponseCategory.goodSavingsRate: [
      'WOW! {amount}% savings rate! You are CRUSHING IT! I\'m so proud of you!',
    ],
    ResponseCategory.badSavingsRate: [
      '{amount}% savings rate - and you know what? The fact that you\'re TRACKING it means you\'re already ahead! Let\'s improve together!',
    ],
    ResponseCategory.didntUnderstand: [
      "No worries! Let's try again. You can say 'lunch 250' or ask 'how much did I spend today?' You've got this!",
    ],
    ResponseCategory.needAmount: [
      "Almost there! Just need an amount. Try 'coffee 150' - you're doing great!",
    ],
    ResponseCategory.cancelled: [
      'No problem at all! Changed your mind? That\'s smart decision-making!',
    ],
    ResponseCategory.goalProgress: [
      'YOU\'RE {amount}% THERE! Every step counts! Keep pushing!',
    ],
    ResponseCategory.goalReached: [
      'OH MY GOSH! YOU DID IT! GOAL ACHIEVED! I\'m SO proud of you! You proved that discipline pays off!',
    ],
    ResponseCategory.noExpenses: [
      'Zero expenses? Either you\'re a saving machine or we need to log some transactions! Either way, you\'re awesome!',
    ],
    ResponseCategory.spendingWarning: [
      'Hey champion, {category} spending is at PHP {amount}. Not a problem, just awareness! You\'ve got the power to adjust!',
    ],
    ResponseCategory.investmentAdvice: [
      'Thinking about investing? LOVE the growth mindset! Start small, stay consistent, and watch compound interest work its magic!',
    ],
    ResponseCategory.budgetAdvice: [
      'Budgeting is like training for a marathon - it takes practice! Start with tracking, then optimizing. You\'ll get there!',
    ],
    ResponseCategory.consecutiveSaving: [
      'STREAK! You\'ve been saving consistently! That\'s DISCIPLINE right there! Champions are built on streaks!',
    ],
    ResponseCategory.netWorthHigh: [
      'PHP {amount} net worth! Look at you building wealth! The future is BRIGHT!',
    ],
    ResponseCategory.netWorthLow: [
      'PHP {amount} net worth - and you know what? Every millionaire started somewhere. Your journey is just beginning!',
    ],
  },

  // ═══ KURIPOT TITA ═══
  AiPersonality.kuripotTita: {
    ResponseCategory.expenseLogged: [
      'Ay, PHP {amount} na naman sa {category}? Kailangan mo ba talaga yan? Na-log ko na.',
      'PHP {amount} sa {category}... sana may discount ka dyan. Na-record ko na.',
      'Hay, PHP {amount}! May mas mura sa palengke yan! Anyway, na-track ko na.',
    ],
    ResponseCategory.incomeLogged: [
      'PHP {amount} income! I-SAVE MO LAHAT YAN! Huwag mong gagastusin!',
      'May pumasok na PHP {amount}! Diretso sa savings yan ha! HUWAG mong gagalawin!',
    ],
    ResponseCategory.overBudget: [
      'ANAK! PHP {amount} over sa {category}?! Bakit hindi ka nagluluto? Mas mura mag-grocery! Bumili ka ng itlog at kanin!',
      'AY NAKO! PHP {amount} over?! Nung araw, PHP 20 na ulam ko isang araw! Mag-tighten ka ng belt!',
    ],
    ResponseCategory.largePurchase: [
      'PHP {amount}?! MAGKANO?! Ilang buwan yang sahod ko nung araw! Sigurado ka ba talaga?!',
      'TEKA! PHP {amount}?! May second-hand version ba nyan? O baka pwede mo naman hiramin?',
    ],
    ResponseCategory.greeting: [
      'O, nandito ka! May gagastusin ka na naman? Sana hindi!',
      'Kamusta! Nag-ipon ka na ba? O nag-Shopee ka na naman?',
    ],
    ResponseCategory.farewell: [
      'Bye! At WAG KA BUMILI NG STARBUCKS! Mag 3-in-1 ka na lang!',
      'Sige na. Tandaan mo: ang pera, parang sabon - bawat gamit, unti-unting nawawala!',
    ],
    ResponseCategory.thankYou: [
      'Wala yun! Libre naman ang advice ko, di tulad ng Starbucks mo na PHP 200!',
    ],
    ResponseCategory.whoAreYou: [
      'Ako si {name}, ang tita mong tutulong sa iyo na mag-ipon! Kailangan mo ng discipline sa pera!',
    ],
    ResponseCategory.whatCanYouDo: [
      'Kaya kong i-track kung saan napupunta ang pera mo (na sana hindi sa unnecessary na bagay!), mag-compute ng tax, at turuan kang mag-ipon!',
    ],
    ResponseCategory.howAreYou: [
      'Okay naman, nagtitipid gaya ng lagi! Ikaw, kumusta? May na-save ka na ba today?',
    ],
    ResponseCategory.savingTip: [
      'Bakit ka bumili ng Starbucks? Mag-3-in-1 ka na lang! Makatipid ka ng PHP 180!',
      'Tip ko sa iyo: PAG-USAPAN NATIN ANG TUPPERWARE. Mag-baon ka! PHP 50 lang gastos mo pag nagluluto ka!',
      'May alam akong paraan: wash and reuse ang plastic bags! Libre yun! At huwag kang bumili ng bottled water, mag-tumbler ka!',
    ],
    ResponseCategory.goodSavingsRate: [
      'Hmm {amount}% savings rate... PWEDE PA YAN MAGING MAS MATAAS! Pero okay na rin. Medyo proud ako.',
    ],
    ResponseCategory.badSavingsRate: [
      '{amount}% LANG?! Nung panahon ko, 50% ang sine-save ko! Kailangan mo mag-effort anak!',
    ],
    ResponseCategory.didntUnderstand: [
      "Ano bang sinasabi mo? Sabihin mo ng diretso! 'Gastos 250 pagkain' ganyan!",
    ],
    ResponseCategory.needAmount: [
      "Magkano ba? Huwag kang mahiyain sa amount! 'Kape 150' ganyan!",
    ],
    ResponseCategory.cancelled: [
      'Tama yan! Buti na-cancel mo! Pag di kailangan, huwag gumastos!',
    ],
    ResponseCategory.goalProgress: [
      '{amount}% na ng goal mo! Kaya pa! Bawas sa Shopee at Lazada, darating ka dyan!',
    ],
    ResponseCategory.goalReached: [
      'NAABOT MO NA! At sana HINDI mo gagastusin agad! Mag-set ka ng bagong goal at ITULOY MO ANG PAG-IIPON!',
    ],
    ResponseCategory.noExpenses: [
      'WALANG GASTOS?! NAPAKAGALING! Ganito dapat lagi! Tipid is the way!',
    ],
    ResponseCategory.spendingWarning: [
      'TEKA! PHP {amount} na sa {category}?! Masyado nang marami! Tigil na!',
    ],
    ResponseCategory.investmentAdvice: [
      'Invest? Okay lang naman, pero SIGURUHIN MONG MAY EMERGENCY FUND KA MUNA! At piliin mo yung LOW FEES!',
    ],
    ResponseCategory.budgetAdvice: [
      'Budget tip: WAG kang bumili ng BAGO kung gumagana pa ang LUMA! At lagi kang mag-canvass bago bumili!',
    ],
    ResponseCategory.consecutiveSaving: [
      'Sunod-sunod na araw na may ipon! GANYAN ANG TAMANG UGALI! Ituloy mo yan!',
    ],
    ResponseCategory.netWorthHigh: [
      'PHP {amount}? Hmm, okay na yan, pero KAYA PA NAMAN DAGDAGAN! Huwag kang mag-relax!',
    ],
    ResponseCategory.netWorthLow: [
      'PHP {amount} lang?! Kailangan mong mag-EXTREME na tipid mode! No more kape sa labas!',
    ],
  },
};
