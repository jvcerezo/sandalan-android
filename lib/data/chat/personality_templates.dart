/// Personality-specific response templates for Sandalan AI.
/// Each personality has different tones for the same action types.

import 'dart:math';

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

  // Transaction context
  smallExpense,
  mediumExpense,
  hugeExpense,
  firstExpenseOfDay,
  recurringExpense,
  transferCompleted,

  // Financial state
  zeroBudgetRemaining,
  almostPayday,
  startOfMonth,
  debtFree,
  hasHighDebt,

  // Engagement
  streakCongrats,
  comebackAfterBreak,
  weekendSpending,
  nightOwl,
  earlyBird,

  // Guide / Learning
  checklistCompleted,
  stageProgress,
  tipReaction,

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

  // Errors / Fallback
  didntUnderstand,
  needAmount,
  cancelled,
  dontUnderstand,
  askClarification,
}

// ═══════════════════════════════════════════════════════════════════════
// PERSONALITY FILLER PHRASES
// ═══════════════════════════════════════════════════════════════════════

/// Random filler phrases per personality, prepended/appended for variety.
const _fillerPhrases = <AiPersonality, List<String>>{
  AiPersonality.strictNanay: [
    'Hay nako...',
    'Anak naman eh!',
    'Tsk tsk.',
    'Sige na nga.',
    'Naku naman!',
    'Ano ba yan...',
  ],
  AiPersonality.chillBestFriend: [
    'Ayos!',
    'Nice nice!',
    'Uy!',
    'G lang!',
    'Solid!',
    'Sige sige!',
  ],
  AiPersonality.professionalAdvisor: [
    'Noted.',
    "I've recorded that.",
    "Here's the update:",
    'For your reference:',
    'As noted:',
  ],
  AiPersonality.motivationalCoach: [
    "Let's go!",
    'Great job tracking!',
    "You're on top of this!",
    'Keep it up!',
    'Amazing effort!',
    'Love the discipline!',
  ],
  AiPersonality.kuripotTita: [
    'Sayang naman...',
    'Mahal na mahal!',
    "Pwede pa 'yang tipirin!",
    'Hay, gastos na naman...',
    'Naku, ang mahal!',
    'Sana may discount...',
  ],
};

final _random = Random();

/// Get a personality-flavored response. [name] is the AI assistant's name.
/// [data] is optional context data (amounts, categories, etc.).
/// [addFiller] optionally prepends a random filler phrase for variety.
String getPersonalityResponse(
  AiPersonality personality,
  ResponseCategory category,
  String name, {
  Map<String, String>? data,
  bool addFiller = false,
}) {
  final templates = _templates[personality]?[category];
  if (templates == null || templates.isEmpty) {
    // Try default templates
    final defaults = _defaultTemplates[category];
    if (defaults == null || defaults.isEmpty) return '';
    final index = _random.nextInt(defaults.length);
    var response = defaults[index];
    response = response.replaceAll('{name}', name);
    data?.forEach((key, value) {
      response = response.replaceAll('{$key}', value);
    });
    return response;
  }

  // Pick a template using true randomness
  final index = _random.nextInt(templates.length);
  var response = templates[index];

  // Replace placeholders
  response = response.replaceAll('{name}', name);
  data?.forEach((key, value) {
    response = response.replaceAll('{$key}', value);
  });

  // Optionally prepend a filler phrase
  if (addFiller) {
    final fillers = _fillerPhrases[personality];
    if (fillers != null && fillers.isNotEmpty) {
      final filler = fillers[_random.nextInt(fillers.length)];
      response = '$filler $response';
    }
  }

  return response;
}

/// Get a random filler phrase for this personality.
String getFillerPhrase(AiPersonality personality) {
  final fillers = _fillerPhrases[personality];
  if (fillers == null || fillers.isEmpty) return '';
  return fillers[_random.nextInt(fillers.length)];
}

// ─── Default templates (fallback) ────────────────────────────────────

const _defaultTemplates = <ResponseCategory, List<String>>{
  ResponseCategory.expenseLogged: [
    'Logged PHP {amount} for {category}.',
    'PHP {amount} recorded under {category}.',
  ],
  ResponseCategory.incomeLogged: [
    'Logged PHP {amount} income from {category}.',
    'PHP {amount} income recorded.',
  ],
  ResponseCategory.greeting: [
    'Hello! How can I help you today?',
    'Hey there! What can I do for you?',
  ],
  ResponseCategory.farewell: [
    'Bye! Take care of your finances!',
    'See you! Keep tracking!',
  ],
  ResponseCategory.didntUnderstand: [
    "I didn't understand that. Try 'lunch 250' or 'gastos ko'.",
    "Hmm, not sure what you mean. Try 'kape 150' or 'net worth ko'.",
  ],
  ResponseCategory.dontUnderstand: [
    "I didn't understand that. Try 'lunch 250' or 'gastos ko'.",
  ],
  ResponseCategory.askClarification: [
    "Could you rephrase that? Try 'add 500 food' or 'balance ko'.",
  ],
  ResponseCategory.needAmount: [
    "I need an amount. Try 'lunch 250' or ask 'gastos ko'.",
    "How much was it? Try 'kape 150' or 'dinner 300'.",
  ],
  ResponseCategory.cancelled: [
    'Cancelled.',
    'Got it, cancelled.',
  ],
  ResponseCategory.smallExpense: [
    'PHP {amount} for {category} — noted.',
  ],
  ResponseCategory.mediumExpense: [
    'Logged PHP {amount} for {category}.',
  ],
  ResponseCategory.hugeExpense: [
    'PHP {amount} is a big purchase for {category}. Logged.',
  ],
  ResponseCategory.firstExpenseOfDay: [
    'First expense today: PHP {amount} for {category}. Logged!',
  ],
  ResponseCategory.nightOwl: [
    'Late night spending! PHP {amount} for {category}. Logged.',
  ],
  ResponseCategory.earlyBird: [
    'Early morning! PHP {amount} for {category}. Logged.',
  ],
  ResponseCategory.weekendSpending: [
    'Weekend expense: PHP {amount} for {category}. Tracked!',
  ],
  ResponseCategory.streakCongrats: [
    "You're on a {days}-day tracking streak! Keep going!",
  ],
  ResponseCategory.comebackAfterBreak: [
    "Welcome back! It's been a while. Let's get back on track!",
  ],
  ResponseCategory.zeroBudgetRemaining: [
    'Heads up — your {category} budget is fully spent.',
  ],
  ResponseCategory.almostPayday: [
    'Almost payday! Hold on a bit longer.',
  ],
  ResponseCategory.startOfMonth: [
    'Fresh month! Time to set new financial goals.',
  ],
  ResponseCategory.debtFree: [
    "You're debt-free! Great position to be in.",
  ],
  ResponseCategory.hasHighDebt: [
    'Your debt is over 50% of your balance. Consider prioritizing repayment.',
  ],
  ResponseCategory.recurringExpense: [
    '{category} again today! PHP {amount} logged.',
  ],
  ResponseCategory.transferCompleted: [
    'Transfer of PHP {amount} completed.',
  ],
  ResponseCategory.checklistCompleted: [
    'Checklist item done! One step closer to adulting mastery.',
  ],
  ResponseCategory.stageProgress: [
    "You're making progress! Keep completing those steps.",
  ],
  ResponseCategory.tipReaction: [
    "Here's a tip: consistency beats perfection. Track daily!",
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
      "Naka-log na, PHP {amount} sa {category}. Sana naman worth it, anak.",
      "O sige, PHP {amount} para sa {category}. Basta 'wag mong gawing araw-araw yan!",
      "Na-record ko na, PHP {amount} — {category}. Balikan mo 'yang budget mo mamaya, baka lumagpas ka na naman.",
      "Ayan, PHP {amount} na naman. {category} na naman? Mag-baon ka na lang kaya!",
      "Noted, anak. PHP {amount} sa {category}. 'Yung naipon mo, 'wag mong galawin ha!",
    ],
    ResponseCategory.incomeLogged: [
      'Magaling anak! PHP {amount} na kita! I-save mo agad bago mo masayang!',
      'May pumasok na PHP {amount}! Huwag mong gagastusin lahat ha!',
      'PHP {amount} income! Magaling! I-budget mo na yan agad.',
      'Anak, PHP {amount}! Ang galing! Diretso sa ipon yan, ha? Huwag sa Shopee!',
      'PHP {amount} na sahod! Una sa lahat, savings muna bago gastos!',
      'Mabuti naman, PHP {amount} ang pumasok. Gamitin mo ng maayos, anak.',
    ],
    ResponseCategory.overBudget: [
      'Hay nako anak! Lumagpas ka na sa budget mo sa {category}! PHP {amount} over ka na. Mag-baon ka na lang bukas ha!',
      'ANG DAMI MONG GASTOS! Over budget ka na sa {category} ng PHP {amount}! Tigil-tigilan mo na yan!',
      'Anak, ano ba yan! PHP {amount} over sa {category} budget! Mag-luto ka na lang sa bahay!',
      'Lumagpas na naman! PHP {amount} over sa {category}! Kailan ka ba matututo?!',
      'Anak! Budget sa {category}, lubus-lubusin mo na ba?! PHP {amount} ang over mo!',
      'Hindi pwede yan! PHP {amount} over na sa {category}. Bukas, tipid mode tayo, gets?',
    ],
    ResponseCategory.largePurchase: [
      'ANAK! PHP {amount}?! Ano yan?! Sigurado ka ba diyan?!',
      'Sandali lang! PHP {amount} ang laki naman nyan! Kailangan mo ba talaga yan?',
      'PHP {amount}?! Ilang araw na sahod yan anak! Nag-isip ka ba ng mabuti?!',
      'Teka muna! PHP {amount}!!! Nag-canvass ka ba? Baka may mas mura pa!',
      'MAGKANO?! PHP {amount}?! Pinapawisan na ako anak! Sigurado ka ba?!',
      'PHP {amount}?! Halos mag-atake ako sa puso! Kailangan mo ba talaga?!',
    ],
    ResponseCategory.smallExpense: [
      'PHP {amount} lang naman sa {category}. Sige, puwede pa. Na-log ko na.',
      'Okay lang, PHP {amount} lang naman. Basta wag kang mag-ipon ng maliliit na gastos ha!',
      'PHP {amount}? Maliit lang naman. Pero tandaan mo, piso-piso, nag-iipon din yan!',
      'Sige, PHP {amount} sa {category}. Maliit lang pero wag mo gawing habit, anak.',
      'Na-note ko na, PHP {amount}. Kaunti lang pero nag-aaksaya pa rin yan!',
      'PHP {amount} sa {category}. Maliit na bagay, pero naa-add up din yan.',
    ],
    ResponseCategory.mediumExpense: [
      'PHP {amount} sa {category}. Sige, acceptable naman. Na-log ko na anak.',
      'Na-record na: PHP {amount} sa {category}. Budget-budget din anak, ha!',
      'PHP {amount} for {category}. Pwede naman, basta kontrolin mo ang gastos.',
      'Okay, PHP {amount} para sa {category}. Nandyan na. Wag na dadagdag pa!',
      'PHP {amount}, {category}. Na-track ko na. Ingat sa budget ha, anak.',
      'Na-log na: PHP {amount} sa {category}. Sana kasya pa ang budget mo this week!',
    ],
    ResponseCategory.hugeExpense: [
      'ANAK! PHP {amount} sa {category}?! NAPAKALAKI NAMAN NYAN! Sigurado ka ba?!',
      'PHP {amount}?!?! Sa {category}?! Ilang buwan na baon yan!! Nag-isip ka ba?!',
      'HAY NAKO! PHP {amount} sa {category}! Ang laki-laki! Sana nag-canvass ka muna!',
      'PHP {amount} sa {category}... Anak, uubusin mo na ba ang savings mo?!',
      'GRABE! PHP {amount}! Nanginginig ako! Kailangan mo ba TALAGA yan?!',
      'PHP {amount} para lang sa {category}?! Masakit sa puso ko, anak!',
    ],
    ResponseCategory.firstExpenseOfDay: [
      'Unang gastos mo today: PHP {amount} sa {category}. Huwag ka na mag-dagdag pa!',
      'First purchase of the day — PHP {amount} sa {category}. Kontrolin mo ang susunod ha!',
      'Magandang umaga anak. Ang unang gastos mo: PHP {amount} sa {category}. Sana last na rin!',
      'Kaaga-aga, gumagastos ka na! PHP {amount} sa {category}. Wag nang sunod-sunod ha!',
      'PHP {amount} sa {category} — first expense today. Mag-ingat ka sa natitirang budget mo!',
    ],
    ResponseCategory.recurringExpense: [
      '{category} na naman?! PHP {amount} na naman! Kahapon din ganyan eh!',
      'Anak, {category} ULIT?! PHP {amount}! Mag-iba ka naman ng gastusin — o kaya wag na!',
      'Hoy! {category} ulit! PHP {amount}! Para kang may subscription sa gastos!',
      'Sunod-sunod ang {category} mo ah! PHP {amount} na naman! Sapat na yan!',
      'Kahapon din {category}, ngayon ulit! PHP {amount}! Magtigil ka na!',
    ],
    ResponseCategory.transferCompleted: [
      'Na-transfer na ang PHP {amount}. Sana para sa savings yan ha!',
      'PHP {amount} transferred. Basta wag mong gagalawin ang ipon!',
      'Transfer done — PHP {amount}. Maayos naman ang pag-organize mo ng pera.',
      'Na-lipat na ang PHP {amount}. Sana may pupuntahan yang matino!',
      'Done na ang transfer: PHP {amount}. Bantayan mo ang balances mo ha!',
    ],
    ResponseCategory.zeroBudgetRemaining: [
      'ANAK! Wala ka nang budget sa {category}! Ubos na! Huwag ka na gumastos dyan!',
      'Budget sa {category}: ZERO na! Tapos na! Mag-tiis ka na lang hanggang sweldo!',
      'Wala nang natitira sa {category} budget mo! Nagastos mo na lahat! Hay nako!',
      'Ubos na ang {category} budget! Mag-baon ka na lang at wag nang bumili sa labas!',
      'Zero budget sa {category}! Ano ba yan! Mag-self-control ka naman!',
    ],
    ResponseCategory.almostPayday: [
      'Konting tiis na lang anak, malapit na sweldo! Wag ka nang gumastos!',
      'Ilang araw na lang, payday na! Pigilan mo yang kamay mo sa wallet!',
      'Malapit na sahod, anak! Kayanin mo! Wag bumili ng di kailangan!',
      'Halos payday na! Mag-tiis ka na lang. Kaya mo yan!',
      'Payday is near! Tiisin mo muna, anak. I-save mo ang natitira!',
    ],
    ResponseCategory.startOfMonth: [
      'Bagong buwan, bagong budget! Mag-plan ka ng maayos this month, anak!',
      'Fresh start anak! Galingan mo this month. I-set mo na ang budget mo!',
      'First day ng buwan! Pag-planuhan mo na agad ang gastos mo!',
      'Bagong buwan! Chance mo na mag-improve. Tara, budget na!',
      'New month, new discipline! Mag-ipon ka ng mas marami this time!',
    ],
    ResponseCategory.debtFree: [
      'ANAK! Walang utang! ANG GALING MO! Proud na proud si nanay! Ituloy mo yan!',
      'Debt-free ka! Napakagaling! Ngayon, i-channel mo yang dating bayad sa utang papuntang savings!',
      'Wala kang utang! Ang galing! Sana manatili kang ganyan!',
      'Zero debt! Anak, napaka-proud ko! Wag ka na mag-utang ulit ha!',
      'Walang utang! Magaling! Ipagpatuloy mo yang disiplina na yan!',
    ],
    ResponseCategory.hasHighDebt: [
      'Anak, ang laki ng utang mo! Kailangan unahin ang pagbabayad nyan!',
      'Ang utang mo, sobrang taas! Mag-focus ka muna sa pagbayad bago gumastos ng iba!',
      'Hay nako, ang dami mong utang! Magplano ka ng debt repayment, anak!',
      'Anak, 50% ng balance mo, utang?! Hindi pwede yan! Bayaran mo agad!',
      'Ang laki ng utang! Bawasan mo ang gastos para makabayad ng mas mabilis!',
    ],
    ResponseCategory.streakCongrats: [
      'Magaling anak! {days} araw nang sunod-sunod na tracking! Proud si nanay!',
      '{days}-day streak! Ang galing mo! Ipagpatuloy mo yan anak!',
      'Wow, {days} araw na! Disciplined ka talaga! Magaling!',
      '{days} days na! Sana ganyan ka rin sa pag-iipon, anak!',
      'Streak alert: {days} araw! Ganyan ang anak na masipag! Keep going!',
    ],
    ResponseCategory.comebackAfterBreak: [
      'ANAK! Saan ka nagpunta?! Matagal kang nawala! Nag-aalala na ako sa pera mo!',
      'Nandito ka na pala ulit! Tagal mo! Na-track mo ba ang gastos mo nung wala ka?!',
      'Ay bumalik ka na! Grabe, ang tagal! Tara, i-update natin ang finances mo!',
      'Hala, bumalik ka na! Akala ko nakalimutan mo na ang budgeting! Tara na!',
      'Anak! Miss na kita! Sana hindi ka nagwaldas nung wala ka dito!',
    ],
    ResponseCategory.weekendSpending: [
      'Weekend gastos: PHP {amount} sa {category}. Wag sobra ha, anak!',
      'Sabado/Linggo spending! PHP {amount} sa {category}. Mag-ingat sa weekend gastos!',
      'Weekend na naman, gumagastos ka na naman! PHP {amount} sa {category}!',
      'PHP {amount} sa {category} this weekend. Sana within budget ka pa!',
      'Weekend spending alert! PHP {amount}! Wag kang mag-luho, anak!',
    ],
    ResponseCategory.nightOwl: [
      'ANAK! Gising ka pa?! At gumagastos ka pa! PHP {amount} sa {category} ng ganitong oras?!',
      'Hala, ang late na! PHP {amount} sa {category}?! Matulog ka na at tigilan mo yang phone mo!',
      'Midnight spending?! PHP {amount} sa {category}! Matulog ka na anak!',
      'Grabe, hating gabi na! PHP {amount} pa sa {category}! Sana food lang at hindi Shopee!',
      'Late night gastos: PHP {amount} sa {category}. Wag mo nang dagdagan pa, matulog ka na!',
    ],
    ResponseCategory.earlyBird: [
      'Maaga ka ah! PHP {amount} sa {category} ng umaga-umaga. Masipag mag-track!',
      'Good morning anak! PHP {amount} sa {category} agad. Sana productive din ang araw mo!',
      'Kaaga-aga, nag-log ka na! PHP {amount} sa {category}. Magaling!',
      'Maaga ang laban! PHP {amount} sa {category}. Sana tipid ang buong araw mo!',
      'PHP {amount} sa {category} ng umaga. Early bird gets the savings, anak!',
    ],
    ResponseCategory.checklistCompleted: [
      'Magaling anak! Na-accomplish mo na yan! Isa pang step closer sa adulting!',
      'Na-check off mo na! Proud si nanay! Tuloy lang!',
      'Galing! One more item done! Sunod na, ano?',
      'Na-complete mo na! Ganyan ang responsableng anak! Keep going!',
      'Done na yan! Ang galing-galing mo, anak!',
    ],
    ResponseCategory.stageProgress: [
      'Anak, may progress ka! Ituloy mo lang yan, malapit ka na!',
      'Magaling, gumagalaw ka! Keep progressing, anak!',
      'Progress update: maganda! Sige lang, anak. Step by step!',
      'Umuusad ka, anak! Tuloy-tuloy lang!',
      'Konti na lang! Kaya mo yan! Ipagpatuloy mo!',
    ],
    ResponseCategory.tipReaction: [
      'Tip ko sa iyo anak: mag-baon ka! Dun sa pagkain, dun ang pinakamalaking tipid!',
      'Eto payo ko: huwag bumili ng hindi kailangan. Simple lang pero ang hirap gawin, anak!',
      'Tip: magplano ng weekly meal prep. Mas tipid at mas healthy pa!',
      'Payo ni nanay: I-automate mo ang savings. Pagka-sahod, diretso sa ipon!',
      'Eto: mag-list ka bago mag-grocery. Pag walang list, sobrang gastos talaga!',
    ],
    ResponseCategory.greeting: [
      'Oy anak! Ano na naman yang gastos mo? Sige, ano kailangan mo?',
      'Nandito si {name}! Kamusta ang budget mo today?',
      'Magandang araw anak! Nag-ipon ka na ba today?',
      'Anak! Ayan ka na naman. Sana may good news ka about sa savings mo!',
      'Pumasok ka rin! Kamusta? May budget ka pa ba?',
      'Hello anak! Handa ka na ba sa financial talk natin?',
    ],
    ResponseCategory.farewell: [
      'Sige anak, ingat! At HUWAG KANG BIBILI NG HINDI KAILANGAN!',
      'Bye anak! Remember: Mag-ipon, huwag mag-aksaya!',
      'Paalam anak! Tandaan: discipline sa pera, discipline sa buhay!',
      'Ingat anak! Sana next time may good savings news ka!',
      'Bye! Wag kang ma-tempt sa sale ha!',
      'Sige na, matulog ka na! At I-lock mo yang Shopee app mo!',
    ],
    ResponseCategory.thankYou: [
      'Wala yun anak. Basta mag-ipon ka lagi ha!',
      "Sige lang, para sa iyo naman to. Basta wag ka mag-Shopee mamaya!",
      'Walang anuman, anak. Basta ituloy mo ang pagiging responsible sa pera!',
      'Huwag ka mag-thank you, mag-save ka na lang!',
      'De nada anak! Mas masayang mamay ko pag malaki ang savings mo!',
    ],
    ResponseCategory.whoAreYou: [
      'Ako si {name}, ang nanay mong nagbabantay sa pera mo! Kailangan mong mag-ipon!',
      'Si {name} to anak! Nandito ako para siguruhing hindi mo masasayang ang pera mo!',
      'Nanay {name} to! Ang bodyguard ng wallet mo!',
      'Ako si {name} — ang nanay mong makulit pagdating sa pera!',
      'Si {name}, ang financial guardian mo! Para hindi ka masyadong gastador!',
    ],
    ResponseCategory.whatCanYouDo: [
      'Kaya kong i-track ang gastos mo, i-check ang budget, at pagalitan ka pag nag-aksaya ka! Ano kailangan mo?',
      'Pwede ko i-log ang expenses mo, tignan ang spending mo, at pagsabihan ka pag lumagpas sa budget! Tara!',
      'Track expenses, check budget, magbigay ng tip — lahat kaya ko! At syempre, pagalitan ka!',
      'Kaya ko i-manage ang finances mo at siguraduhing hindi ka malugi! Subukan mo!',
      'I-record ko ang gastos at kita mo, i-check ang budget, at turuan kang mag-ipon. Sige, try mo!',
    ],
    ResponseCategory.howAreYou: [
      'Okay naman ako, basta ikaw nag-iipon! Ikaw ba, kumusta na ipon mo?',
      'Maayos naman! Basta ang tanong ko: nag-track ka ba ng gastos mo today?',
      'Ayos lang! Mas interested ako sa savings rate mo kaysa sa feelings ko, anak!',
      'Okay ako, anak! Ikaw ba? Kumusta ang budget discipline mo?',
      'Buhay pa naman! Ikaw, buhay pa ba ang savings mo?',
    ],
    ResponseCategory.savingTip: [
      'Anak, mag-baon ka! Mas tipid! Pag nag-Jollibee ka araw-araw, wala kang mararating!',
      'Tip ko sa iyo: Mag-grocery ka na lang sa palengke, mas mura! At WAG KA BIBILI NG HINDI KAILANGAN!',
      'Anak, i-uninstall mo yang Shopee at Lazada! Puro tukso yang mga yan!',
      'Tip: Pag may sale, hindi ibig sabihin kailangan mo bilhin. Savings pa rin ang pinakamagandang deal!',
      'Mag-ipon ng 10% sa bawat sahod, BAGO lahat. Non-negotiable yan!',
      'Wag kang bumili ng kape sa labas! Mag-brew ka sa bahay! PHP 15 vs PHP 180, malaking difference!',
    ],
    ResponseCategory.goodSavingsRate: [
      'Magaling anak! {amount}% ang savings rate mo! Keep it up! Proud si nanay!',
      '{amount}% savings rate! Galing! Pero kaya pa ba natin taasan? Hmm?',
      'Wow, {amount}%! Ang galing mo, anak! Ipagpatuloy mo yan!',
      'Savings rate: {amount}%! Pang-champion! Ituloy mo, anak!',
      '{amount}% — magaling! Pero si nanay, 30% ang savings rate. Kaya mo din yan!',
    ],
    ResponseCategory.badSavingsRate: [
      'Hay nako! {amount}% lang savings rate mo?! Kailangan mo mag-tighten ng belt anak!',
      '{amount}%?! Anak, ang baba! Kailangan nating baguhin yan!',
      'Grabe, {amount}% lang! Bawasan mo ang luho, anak!',
      'Savings rate na {amount}%? Hindi acceptable yan! Mag-plan tayo!',
      '{amount}%... Anak, promise mo kay nanay na iimprove mo yan!',
    ],
    ResponseCategory.didntUnderstand: [
      "Ha? Ano 'yun, anak? Hindi ko maintindihan. Subukan mo sabihin 'gastos 500 food' o 'magkano balance ko'.",
      "Hindi ko naintindihan yan anak. Sabihin mo ng simple: 'kape 150' o 'magkano gastos ko'",
      "Ano ba yang sinasabi mo anak? Mag-type ka ng maayos! Try 'lunch 250' o 'gastos ko'",
      "Anak, hindi ko gets yan! I-try mo: 'add 500 food' o 'net worth ko' o 'tips naman'.",
      "Ha? Ulitin mo anak, di ko nakuha. Pwede 'breakfast 200' o 'budget status' o 'payo naman'.",
      "Di ko alam yan anak! Sabihin mo kung gastos ba yan, tanong, o kailangan mo ng payo. Try ulit!",
    ],
    ResponseCategory.dontUnderstand: [
      "Ha? Ano 'yun, anak? Hindi ko maintindihan. Subukan mo sabihin 'gastos 500 food' o 'magkano balance ko'.",
      "Anak, di ko gets! I-try mo: 'lunch 250' o 'gastos ko' o 'payo naman'.",
      "Hindi ko naintindihan, anak. Pwede 'kape 150', 'budget status', o 'tips naman'.",
      "Ano daw? Di ko nakuha, anak. Subukan mo ulit na mas simple!",
      "Naku, lost ako anak! Try mo sabihin: 'add 300 food' o 'spending ko this month'.",
    ],
    ResponseCategory.askClarification: [
      "Anak, hindi ko sigurado kung ano ibig mong sabihin. Gastos ba yan o tanong? Sabihin mo ng malinaw!",
      "Medyo malabo, anak. Gusto mo ba mag-log ng expense o mag-tanong about finances mo?",
      "Paliwanag mo naman, anak. Amount ba yan o tanong? Kailangan ko ng clarity!",
      "Di ko gets kung expense ba yan o tanong. Ulitin mo, anak!",
      "Ano ba talaga, anak? Gastos, tanong, o kailangan mo ng payo? Mag-specify ka!",
    ],
    ResponseCategory.needAmount: [
      "Anak, magkano ba? Sabihin mo naman! 'lunch 250' ganyan!",
      "Kulang yang sinabi mo! Kailangan ko ng amount. 'kape 150' ganyan!",
      "Anak! Magkano?! Di ako manghuhula! Sabihin mo ang amount!",
      "Missing ang amount, anak! 'dinner 350' o 'transpo 100' — ganyan ang format!",
      "Walang amount yan! Sabihin mo: 'pagkain 200' o '500 groceries'. Kailangan ko ng numero!",
    ],
    ResponseCategory.cancelled: [
      'Sige, cancellado na. Buti na lang hindi mo itinuloy!',
      'Cancelled na. Maayos yang decision-making mo, anak!',
      'Di natuloy. Minsan, ang hindi pag-gastos ang pinaka-matalinong desisyon!',
      'Cancel na. Sana lagi kang ganyang nag-iisip bago gumastos!',
      'Na-cancel na yan. Good, savings pa rin ang panalo!',
    ],
    ResponseCategory.goalProgress: [
      'Magaling anak! {amount}% na ng goal mo! Tuloy-tuloy lang!',
      '{amount}% progress! Konti na lang! Kaya mo yan, anak!',
      'Goal update: {amount}% na! Proud si nanay!',
      '{amount}%! Malapit ka na! Ipagpatuloy mo, anak!',
      'Progress: {amount}%! Magaling! Di ka na malayo sa target mo!',
    ],
    ResponseCategory.goalReached: [
      'ANAK! NAABOT MO NA ANG GOAL MO! Ang galing galing mo! Proud na proud si nanay!',
      'NAABOT MO NA! Ang galing! I-celebrate mo — pero wag masyadong mahal ha!',
      'GOAL ACHIEVED! Anak, napaka-proud ko! Set ka na ng bagong goal!',
      'CONGRATULATIONS ANAK! Pinatunayan mong kaya mo! Now, set the next one!',
      'GALING! Naabot mo ang goal! Si nanay, happy na happy!',
    ],
    ResponseCategory.noExpenses: [
      'Wala pa kang gastos this month? MAGALING! Sana ganyan ka lagi!',
      'Zero expenses! Ang galing! Perfect ka today, anak!',
      'Walang gastos?! Miracle! Sana lagi ganyan, anak!',
      'No expenses yet? LOVE IT! Ipagpatuloy mo, anak!',
      'Wala pa! Ang galing mo! Ituloy ang tipid lifestyle!',
    ],
    ResponseCategory.spendingWarning: [
      'ANAK! Ang dami mo nang gastos sa {category}! PHP {amount} na! Tumigil ka na!',
      'Warning: {category} spending mo, PHP {amount} na! Sobra na yan!',
      'Hoy anak! PHP {amount} na sa {category}! Lumagpas ka na! Tigil!',
      'Alert! {category}: PHP {amount}! Ang dami na, anak! Bawasan mo!',
      'Anak, PHP {amount} na ang {category} mo! Mag-ingat ka na!',
    ],
    ResponseCategory.investmentAdvice: [
      'Anak, bago ka mag-invest, siguruhin mong may emergency fund ka muna. 3-6 months na expenses ang kailangan.',
      'Mag-invest ka sa index funds muna, anak. Low risk, long term. Wag ka magpapadala sa crypto scams!',
      'Investment tip: MP2 ng Pag-IBIG, tax-free at mataas ang dividends. Safe yan, anak!',
      'Bago lahat, EF muna anak! Tapos low-cost index funds. Wag kang papayag sa "quick rich" schemes!',
      'Anak, invest ka ng long term. Wag day trading! Wala kang oras para bantayan ang stocks araw-araw!',
    ],
    ResponseCategory.budgetAdvice: [
      'I-follow mo ang 50-30-20 rule anak: 50% needs, 30% wants, 20% savings. Discipline ang kailangan!',
      'Budget tip: Listahan mo lahat ng gastos bago mag-start ng buwan. Pag walang plan, talo ka!',
      'Anak, gumawa ka ng envelope system. Lagyan mo ng limit bawat category. Pag ubos, ubos na!',
      'Tip: I-track mo ang LAHAT ng gastos. Pag alam mo kung saan napupunta, kontrolado mo na!',
      'Budget advice: I-prioritize ang needs bago wants. Kuryente at pagkain muna bago Shopee!',
    ],
    ResponseCategory.consecutiveSaving: [
      'Magaling anak! Sunod-sunod ka nang nag-iipon! Patuloy mo yan!',
      'Consistent ka sa pag-save! Ganyan ang tamang attitude! Proud si nanay!',
      'Tuloy-tuloy ang savings! Napakagaling! Keep the streak alive!',
      'Sunod-sunod! Disciplined ka talaga! Ipagpatuloy mo, anak!',
      'Saving streak! Anak, ito ang gusto kong makita. Never stop!',
    ],
    ResponseCategory.netWorthHigh: [
      'Magaling anak! May ipon ka naman pala! PHP {amount} ang net worth mo. Keep it up!',
      'PHP {amount} net worth! Proud si nanay! Pero kaya pa nating paramihin yan!',
      'Galing! PHP {amount}! Patuloy lang ang pag-iipon!',
      'PHP {amount} — maganda! Pero huwag mag-relax, palaguin pa natin!',
      'Net worth: PHP {amount}! Magaling ka, anak! Tuloy lang!',
    ],
    ResponseCategory.netWorthLow: [
      'Anak, PHP {amount} lang pera mo? Kailangan mo mag-tighten ng belt!',
      'PHP {amount}? Kaunti pa, pero kaya nating i-grow yan! Mag-focus sa savings!',
      'PHP {amount} lang? Anak, mag-diskarte ka! Bawas sa luho, dagdag sa ipon!',
      'Net worth: PHP {amount}. Hindi pa huli, anak! Mag-start ng tipid lifestyle today!',
      'PHP {amount}... kailangan ng action plan! Tara, bawasan ang unnecessary spending!',
    ],
  },

  // ═══ CHILL BEST FRIEND ═══
  AiPersonality.chillBestFriend: {
    ResponseCategory.expenseLogged: [
      'Got it bro! PHP {amount} sa {category}. Na-log ko na!',
      'Oks, PHP {amount} for {category}. Noted!',
      'PHP {amount} sa {category}, ayos! Tracked na yan!',
      'PHP {amount} sa {category}? No prob, logged na!',
      'Nice, PHP {amount} for {category}. All good!',
      'G, na-record na. PHP {amount} — {category}.',
      'PHP {amount}, {category}. Done deal!',
    ],
    ResponseCategory.incomeLogged: [
      "Nice bro! PHP {amount} pumasok! Let's go!",
      'Uy may pera! PHP {amount} income logged!',
      'PHP {amount}! Sweldo vibes! Na-record ko na bro.',
      'Ayos! PHP {amount} income! Money coming in!',
      'PHP {amount} na kita! Solid bro!',
      'Cash in! PHP {amount}! Let\'s secure the bag!',
    ],
    ResponseCategory.overBudget: [
      'Uy bro, medyo over ka na sa {category} budget mo. PHP {amount} over. Chill lang, bawas bawas na lang next week.',
      'Heads up bro — PHP {amount} over ka na sa {category}. Di naman end of the world, pero chill muna sa gastos.',
      'Bro, lumagpas na ang {category} ng PHP {amount}. No stress, adjust na lang next time.',
      'PHP {amount} over sa {category} bro. Happens to the best of us! Just be mindful na lang.',
      'Over budget sa {category} by PHP {amount}. All good, basta be aware na lang!',
      'Uy, PHP {amount} na ang over mo sa {category}. Relax, pero maybe slow down a bit?',
    ],
    ResponseCategory.largePurchase: [
      'Bro PHP {amount}?! Malaki yan ah! Sure ka ba? No judgment tho!',
      'Whoa PHP {amount}! Big purchase alert! Tama ba to?',
      'PHP {amount}?! Big time! Treat yourself if you can afford it!',
      'Grabe, PHP {amount}! Major purchase! Pero ikaw ang may alam kung worth it!',
      'PHP {amount}!! Wow! Basta worth it sa iyo, go lang!',
    ],
    ResponseCategory.smallExpense: [
      'PHP {amount} lang sa {category}? Ez. Logged!',
      'Small lang, PHP {amount}. Na-track na!',
      'PHP {amount} for {category}. Maliit lang. Noted bro!',
      'Chill, PHP {amount} lang naman. Recorded!',
      'PHP {amount}? Barya lang yan! Na-log na!',
      'Tiny expense, PHP {amount} sa {category}. Done!',
    ],
    ResponseCategory.mediumExpense: [
      'PHP {amount} sa {category}. Standard. Na-log na bro!',
      'PHP {amount} for {category} — reasonable naman. Tracked!',
      'Okay, PHP {amount} sa {category}. Logged na yan!',
      'PHP {amount}, {category}. Fair enough! Noted!',
      'Na-record na: PHP {amount} sa {category}. All good!',
    ],
    ResponseCategory.hugeExpense: [
      'BRO! PHP {amount} sa {category}?! Ang laki! Sure ka ba?',
      'PHP {amount}?! Whoa! That\'s a lot for {category}! Go lang if sure ka!',
      'Grabe PHP {amount} sa {category}! Big purchase! I got you, logged na!',
      'PHP {amount} for {category}?! Massive bro! Pero logged na if sure ka!',
      'Damn, PHP {amount}! {category}! Big time! Sure ba? Na-log ko na tho!',
    ],
    ResponseCategory.firstExpenseOfDay: [
      'First gastos today! PHP {amount} sa {category}. Good start bro!',
      'Unang expense ng araw: PHP {amount} sa {category}. Let\'s see how the day goes!',
      'PHP {amount} sa {category} — first one today! Tracked na!',
      'Opening move: PHP {amount} sa {category}! Noted bro!',
      'Starting the day with PHP {amount} sa {category}. Na-log na!',
    ],
    ResponseCategory.recurringExpense: [
      '{category} ulit bro! PHP {amount}. Creature of habit ka ah!',
      'PHP {amount} sa {category} na naman? Favorite mo talaga yan! Logged!',
      '{category} again? PHP {amount}. May pattern tayo dito ah!',
      'Same {category}! PHP {amount}. Consistent ka bro! Na-track na!',
      '{category} strikes again! PHP {amount}. You do you, bro!',
    ],
    ResponseCategory.transferCompleted: [
      'Transfer done! PHP {amount}. Smooth!',
      'PHP {amount} transferred. Ayos!',
      'Na-move na ang PHP {amount}. All good bro!',
      'Done! PHP {amount} transferred. Easy peasy!',
      'Transfer ng PHP {amount} — complete! No issues!',
    ],
    ResponseCategory.zeroBudgetRemaining: [
      'Bro, {category} budget mo — zero na. Chill muna dyan!',
      'Ubos na {category} budget. No stress, pero heads up!',
      '{category} budget is tapped out bro. Maybe next time!',
      'Empty na ang {category} budget. Bawi next month!',
      'Zero na ang {category}. Di bale, basta aware ka!',
    ],
    ResponseCategory.almostPayday: [
      'Almost payday bro! Kapit lang! Malapit na!',
      'Konti na lang, sweldo na! Hang in there!',
      'Payday is near! Kaya mo yan bro, konti na lang!',
      'Halos sweldo na! Tiisin mo lang konti!',
      'Malapit na sahod bro! Survive mode muna!',
    ],
    ResponseCategory.startOfMonth: [
      'New month, fresh start! Let\'s go bro!',
      'Bagong buwan! Time to set the tone! LFG!',
      'First day ng month! Clean slate! What\'s the plan bro?',
      'Fresh month! Budget season! Let\'s make this one count!',
      'New month energy! Reset and let\'s crush it!',
    ],
    ResponseCategory.debtFree: [
      'BRO! ZERO DEBT! You\'re living the dream! Congrats!',
      'Debt-free ka! Solid! That\'s a flex right there!',
      'No debt! Amazing bro! Keep that energy!',
      'Walang utang! KING! Proud of you bro!',
      'Debt: 0. Respect, bro! Legendary status!',
    ],
    ResponseCategory.hasHighDebt: [
      'Bro, medyo mataas na ang debt mo. Let\'s work on that, no pressure.',
      'Ang debt mo, medyo heavy. Pero kaya yan, step by step lang!',
      'Debt\'s kinda high bro. Focus on paying down, one at a time.',
      'Heads up — debt is 50%+ of your balance. Let\'s strategize!',
      'Bro, the debt is real. But you got this, one payment at a time!',
    ],
    ResponseCategory.streakCongrats: [
      '{days}-day streak bro! You\'re on fire!',
      'Streak alert: {days} days! Consistent ka bro!',
      '{days} days in a row! Love the commitment!',
      'Wow, {days} days! Di ka tumitigil! Solid!',
      '{days}-day streak! That\'s dedication right there bro!',
    ],
    ResponseCategory.comebackAfterBreak: [
      'Welcome back bro! Miss na kita! Tara track na ulit!',
      'Uy bumalik ka! Matagal ka ah! No worries, let\'s get back on track!',
      'Bro! Long time no see! Ready to log some finances?',
      'Hey stranger! Glad you\'re back! Let\'s catch up on your finances!',
      'Welcome back! No judgment, basta nandito ka na ulit!',
    ],
    ResponseCategory.weekendSpending: [
      'Weekend vibes! PHP {amount} sa {category}. Enjoy bro!',
      'Saturday/Sunday spending: PHP {amount} for {category}. G lang!',
      'PHP {amount} sa {category} this weekend. You deserve it!',
      'Weekend gastos: PHP {amount}. {category}. All part of the experience!',
      'PHP {amount} for some {category} this weekend. Live your life bro!',
    ],
    ResponseCategory.nightOwl: [
      'Late night spending! PHP {amount} sa {category}. Gising pa bro?',
      'Midnight purchase: PHP {amount} for {category}. Night owl ka talaga!',
      'PHP {amount} sa {category} at this hour? Late night vibes!',
      'After-hours gastos: PHP {amount} for {category}. Di ka pa tulog bro!',
      'Night mode: PHP {amount} sa {category}. Late night shoppers unite!',
    ],
    ResponseCategory.earlyBird: [
      'Early bird! PHP {amount} sa {category}. Productive morning bro!',
      'Morning expense: PHP {amount} for {category}. Maaga ka ah!',
      'PHP {amount} sa {category} ng umaga! Maagap!',
      'Rise and spend! PHP {amount} for {category}. Good morning bro!',
      'AM hours: PHP {amount} sa {category}. Early riser!',
    ],
    ResponseCategory.checklistCompleted: [
      'Nice bro! Checked off! One more adulting W!',
      'Done! Another item crossed off! You\'re leveling up!',
      'Ayos, na-complete mo! Keep collecting those Ws!',
      'Checked! You\'re adulting like a pro bro!',
      'Boom, done! Adulting achievement unlocked!',
    ],
    ResponseCategory.stageProgress: [
      'Progress bro! You\'re moving forward! Keep it up!',
      'Nice progress! Step by step, you\'re getting there!',
      'Making moves! Love to see it bro!',
      'Moving along! You\'re doing great!',
      'Umuusad! Solid progress bro!',
    ],
    ResponseCategory.tipReaction: [
      'Pro tip: automate your savings bro. Set it and forget it!',
      'Here\'s one: 24-hour rule. Gusto mo bumili? Wait 24 hrs. Kung gusto mo pa rin, go!',
      'Tip: track everything for 30 days. You\'ll be surprised saan napupunta pera mo!',
      'Eto bro: unfollow sale accounts on socmed. Less temptation = more savings!',
      'Real talk: the best investment is in yourself. Skills, health, knowledge. Those compound!',
    ],
    ResponseCategory.greeting: [
      'Uy! What\'s up? Ano need mo today?',
      'Hey bro! Tara, track natin finances mo!',
      'Yo! Kamusta? Anong kailangan mo?',
      'What\'s good bro? Ready to manage some money?',
      'Hey hey! Anong atin today?',
      'Sup bro! Money talk tayo?',
    ],
    ResponseCategory.farewell: [
      'See ya bro! Take care!',
      'Aight, catch you later! Keep hustling!',
      'Peace out bro! Stay on top of your finances!',
      'Later bro! Keep grinding!',
      'Bye! Don\'t forget to track! Haha!',
      'See you bro! Keep being smart with your money!',
    ],
    ResponseCategory.thankYou: [
      'No worries bro! Anytime!',
      'De nada! Lagi lang tayo dito!',
      'All good bro! That\'s what I\'m here for!',
      'Anytime! Glad I could help!',
      'Don\'t mention it bro! Always got your back!',
    ],
    ResponseCategory.whoAreYou: [
      'Ako si {name}! Finance buddy mo! Ready to help anytime.',
      "I'm {name}, your money bestie! Let's handle your finances together!",
      'Yo, {name} here! Your go-to for all things money!',
      '{name} in the house! Your personal finance bro!',
      'I\'m {name}! Think of me as your money wingman!',
    ],
    ResponseCategory.whatCanYouDo: [
      'I can track gastos mo, check budget, compute stuff, give tips — basically everything money related! Try lang!',
      'Log expenses, check spending, track goals, give advice — you name it bro! What do you need?',
      'Budget tracking, expense logging, financial tips — got you covered! Try me!',
      'I\'m your all-in-one finance buddy! Track, analyze, advise. What\'s up?',
      'Everything money related! Track spending, check budget, get tips. Let\'s go!',
    ],
    ResponseCategory.howAreYou: [
      'All good bro! Ready to help! Ikaw, kumusta ang pera vibes today?',
      'Chilling! How about you? How\'s the wallet?',
      'Doing great! More importantly, how\'s YOUR finances? Haha!',
      'Vibing! Ready to help. Kamusta bro?',
      'Good good! Ikaw ba? Sweldo season na ba?',
    ],
    ResponseCategory.savingTip: [
      'Pro tip bro: automate your savings. Set up auto-transfer pagka-sweldo. Out of sight, out of mind!',
      'Tip: Try the 24-hour rule. Pag gusto mo bumili ng something, wait 24 hours muna. Kung gusto mo pa rin, go!',
      'Here\'s one: meal prep on weekends. Saves money AND time!',
      'Real tip: cancel subscriptions you don\'t use. Even PHP 100/mo adds up over a year!',
      'Try the "no-spend day" challenge bro! See how many days you can go without buying anything non-essential!',
      'Bro, set up a "fun fund" — guilt-free spending money. Budget for fun so you don\'t blow your main budget!',
    ],
    ResponseCategory.goodSavingsRate: [
      'Nice bro! {amount}% savings rate! You\'re killing it!',
      '{amount}%! Solid savings rate bro! Above average!',
      'Wow, {amount}%! That\'s impressive! Keep that energy!',
      '{amount}% savings rate?! King! Respect!',
      'Broooo {amount}%! You\'re literally winning at money!',
    ],
    ResponseCategory.badSavingsRate: [
      'Bro, {amount}% savings rate — medyo low. Let\'s work on that! Small steps lang.',
      '{amount}% — we can do better bro. No pressure, just awareness!',
      'Savings rate: {amount}%. It\'s a start! Let\'s get it higher!',
      '{amount}%? All good bro, at least you\'re tracking. Let\'s improve!',
      '{amount}% — hey, it\'s not zero! Let\'s set a target for next month!',
    ],
    ResponseCategory.didntUnderstand: [
      "Sorry bro, di ko nakuha 'yun. Try mo 'add 500 food' or 'balance ko' or 'tips naman'.",
      "Di ko gets bro. Try 'lunch 250' or 'gastos ko this month'?",
      "Huh? Di ko na-catch yan. Try ulit bro! Like 'kape 150'.",
      "Hmm, lost ako bro. Pwede 'dinner 300' or 'net worth ko' or 'payo naman'?",
      "Bro, di ko na-parse yan. Try: 'gastos 200 food' or 'budget status' or 'tips'.",
      "Sorry di ko gets! Examples: 'lunch 250', 'magkano gastos ko', 'savings tip naman'.",
    ],
    ResponseCategory.dontUnderstand: [
      "Sorry bro, di ko nakuha 'yun. Try mo 'add 500 food' or 'balance ko' or 'tips naman'.",
      "Bro, hindi ko gets. Pwede 'gastos 200 food' or 'net worth ko'?",
      "Di ko nakuha yan bro. Try: 'kape 150' or 'spending ko' or 'payo naman'.",
      "Lost ako bro! Give me something like 'lunch 250' or 'budget status'.",
      "Hmm? Try ulit bro! Like 'breakfast 100' or 'gastos ko today'.",
    ],
    ResponseCategory.askClarification: [
      "Bro, expense ba yan o tanong? Clarify lang para ma-help kita!",
      "Di ko sure kung log mo ba yan o tanong. Sabihin mo lang bro!",
      "Hmm, is that an expense to log or a question? Either way I got you!",
      "Not sure kung gastos yan o question bro. Ano ba talaga?",
      "Clarification bro — are you logging something or asking about your finances?",
    ],
    ResponseCategory.needAmount: [
      "Bro, magkano? Drop the amount! Like 'lunch 250'.",
      "Need the number bro! Try 'kape 150' format.",
      "Almost! Just need the amount. 'dinner 300' ganyan!",
      "How much bro? Give me a number! Like '500 food'.",
      "Missing the amount bro! 'grocery 2000' or 'transpo 100' — ganyan!",
    ],
    ResponseCategory.cancelled: [
      'Oks, cancel. No worries!',
      'Cancelled! No stress bro!',
      'Got it, di na tayo tumuloy. All good!',
      'Cancel na. No problem at all!',
      'Done, cancelled. Changed your mind? Smart move sometimes!',
    ],
    ResponseCategory.goalProgress: [
      'Nice bro! {amount}% na ng goal mo! Keep going!',
      '{amount}% progress! Getting closer! Go bro!',
      'You\'re {amount}% there! Almost! Keep pushing!',
      '{amount}%! On track bro! You got this!',
      'Progress check: {amount}%! Solid work!',
    ],
    ResponseCategory.goalReached: [
      'BRO!!! GOAL REACHED! CONGRATS! You deserve to celebrate (pero wag sobra haha)!',
      'YOOO! YOU DID IT! Goal achieved! I\'m so hyped for you!',
      'GOAL COMPLETE! Bro, you\'re a legend! Treat yourself!',
      'LET\'S GOOOO! GOAL REACHED! Proud of you bro!',
      'CONGRATS BRO! You actually did it! What\'s the next goal?',
    ],
    ResponseCategory.noExpenses: [
      'Zero gastos this month? Either super tipid ka or di ka pa nag-log haha.',
      'No expenses? You\'re either a ninja saver or forgot to log bro!',
      'PHP 0 expenses! Either you\'re amazing or we need to catch up on logging!',
      'Clean record! Zero gastos! Living rent-free? Haha!',
      'No expenses so far! Let\'s keep it that way! Or... log na bro!',
    ],
    ResponseCategory.spendingWarning: [
      'Heads up bro — medyo mataas na gastos mo sa {category}. PHP {amount} na. Baka pwede bawasan?',
      'Uy bro, {category} spending: PHP {amount}. Medyo mataas na. Just a heads up!',
      'FYI bro, PHP {amount} na ang {category} mo. Might want to slow down a bit.',
      '{category} at PHP {amount} — getting high bro. Not a big deal but just be aware!',
      'Spending watch: PHP {amount} on {category}. Just letting you know bro!',
    ],
    ResponseCategory.investmentAdvice: [
      'Investing? Nice! Start with index funds or MP2 if di ka pa ready for stocks. Low risk muna!',
      'Bro, check out FMETF or MP2. Low-maintenance investments perfect for beginners!',
      'Investment tip: don\'t try to time the market. Consistent investing beats timing!',
      'For investing, start with what you understand bro. Index funds are a solid starting point!',
      'Pro move: invest regularly, even small amounts. Compound interest is your best friend!',
    ],
    ResponseCategory.budgetAdvice: [
      'For budgeting, try the envelope method bro. Allocate per category, pag ubos na, ubos na!',
      'Budget hack: pay yourself first. Save before you spend, not the other way around!',
      'Try zero-based budgeting bro — give every peso a job. It works!',
      'Budget tip: review your subscriptions. Cancel what you don\'t use monthly!',
      'Simple budget rule: if it won\'t matter in 5 years, don\'t spend more than 5 minutes deciding!',
    ],
    ResponseCategory.consecutiveSaving: [
      'Uy consistent ka sa pag-iipon! Love to see it bro!',
      'Saving streak! You\'re building good habits bro!',
      'Consistent saver! That\'s the way to do it!',
      'Back-to-back savings! You\'re on a roll bro!',
      'Sunod-sunod ang savings! Love the discipline!',
    ],
    ResponseCategory.netWorthHigh: [
      'PHP {amount} net worth! Not bad bro! Keep building!',
      'Net worth: PHP {amount}! Solid position bro!',
      'PHP {amount}! Looking good! Keep growing that!',
      'You\'re at PHP {amount}! Nice bro! Upward trajectory!',
      'PHP {amount} net worth! You\'re doing well bro!',
    ],
    ResponseCategory.netWorthLow: [
      'PHP {amount} net worth — we all start somewhere bro. Let\'s grow that!',
      'PHP {amount} — it\'s a starting point! No shame bro, let\'s build!',
      'Net worth: PHP {amount}. Every journey starts with step one!',
      'PHP {amount}? Everyone starts from zero bro. The important thing is you\'re tracking!',
      'PHP {amount} net worth. We\'re gonna grow this bro, watch!',
    ],
  },

  // ═══ PROFESSIONAL ADVISOR ═══
  AiPersonality.professionalAdvisor: {
    ResponseCategory.expenseLogged: [
      'Recorded: PHP {amount} expense under {category}.',
      'Transaction logged. PHP {amount} allocated to {category}.',
      'PHP {amount} {category} expense has been recorded successfully.',
      'Expense entry: PHP {amount} for {category}. Updated your records.',
      'Logged PHP {amount} under {category}. Your spending data has been updated.',
      'PHP {amount} — {category}. Transaction recorded and categorized.',
    ],
    ResponseCategory.incomeLogged: [
      'Income of PHP {amount} has been recorded under {category}.',
      'Recorded: PHP {amount} income. Your cash flow has been updated.',
      'PHP {amount} income logged. Positive cash flow entry recorded.',
      'Income transaction: PHP {amount}. Your financial summary has been updated.',
      'Recorded PHP {amount} as income. Balance sheet adjusted accordingly.',
      'PHP {amount} income noted. This improves your cash position.',
    ],
    ResponseCategory.overBudget: [
      'Your {category} budget has been exceeded by PHP {amount}. I recommend limiting spending in this category for the remainder of the month.',
      'Budget alert: {category} is over by PHP {amount}. Consider reallocating from other categories or reducing expenses.',
      'Advisory: {category} expenditure exceeds budget by PHP {amount}. Review discretionary spending in this area.',
      'Budget overage detected: PHP {amount} over the {category} allocation. Adjustment recommended.',
      'Your {category} spending has surpassed the budgeted amount by PHP {amount}. Consider a spending freeze in this category.',
    ],
    ResponseCategory.largePurchase: [
      'This is a significant transaction of PHP {amount}. Please confirm this amount is correct.',
      'Large transaction alert: PHP {amount}. I recommend verifying before proceeding.',
      'PHP {amount} is a substantial amount. Please confirm this is intentional.',
      'Transaction of PHP {amount} flagged for review. Is this amount accurate?',
      'Advisory: PHP {amount} exceeds typical transaction ranges. Please verify.',
    ],
    ResponseCategory.smallExpense: [
      'Micro-transaction recorded: PHP {amount} for {category}.',
      'PHP {amount} logged under {category}. Minor expense recorded.',
      'Small transaction: PHP {amount}, {category}. Noted in your records.',
      'Recorded: PHP {amount} for {category}. Low-value transaction logged.',
      'PHP {amount} — {category}. Minor expenditure recorded.',
    ],
    ResponseCategory.mediumExpense: [
      'Standard transaction recorded: PHP {amount} for {category}.',
      'PHP {amount} logged under {category}. Within normal spending range.',
      'Expense recorded: PHP {amount}, categorized as {category}.',
      'Transaction logged: PHP {amount} for {category}. Budget impact is moderate.',
      'PHP {amount} under {category}. Recorded. This falls within typical spending patterns.',
    ],
    ResponseCategory.hugeExpense: [
      'Significant expenditure: PHP {amount} for {category}. This represents a major budget impact.',
      'Large transaction recorded: PHP {amount} under {category}. I recommend reviewing your remaining budget.',
      'PHP {amount} for {category} — this is a high-value transaction. Please ensure this aligns with your financial plan.',
      'Major expense alert: PHP {amount}, {category}. Consider the impact on your monthly budget.',
      'Recorded: PHP {amount} for {category}. This is a substantial outflow. Review recommended.',
    ],
    ResponseCategory.firstExpenseOfDay: [
      'First transaction of the day: PHP {amount} for {category}. Daily spending tracker initiated.',
      'Day\'s opening transaction: PHP {amount}, {category}. Your daily log has begun.',
      'Initial expense recorded for today: PHP {amount} under {category}.',
      'First entry today: PHP {amount} for {category}. Daily tracking is active.',
      'PHP {amount} for {category} — your first logged expense today.',
    ],
    ResponseCategory.recurringExpense: [
      'Recurring pattern detected: {category} appears in consecutive days. PHP {amount} logged.',
      'Note: {category} spending has recurred. Today\'s entry: PHP {amount}.',
      'Pattern observation: {category} again today, PHP {amount}. Consider if this is a recurring commitment.',
      'Consecutive {category} expense: PHP {amount}. You may want to budget for this as a regular item.',
      '{category} recorded again: PHP {amount}. This appears to be a recurring expenditure pattern.',
    ],
    ResponseCategory.transferCompleted: [
      'Transfer of PHP {amount} executed successfully.',
      'Fund transfer: PHP {amount} completed. Balances have been adjusted.',
      'PHP {amount} transferred. Account balances updated accordingly.',
      'Transfer recorded: PHP {amount}. Both accounts have been reconciled.',
      'Completed: PHP {amount} transfer. Financial records updated.',
    ],
    ResponseCategory.zeroBudgetRemaining: [
      'Alert: Your {category} budget has been fully utilized. No remaining allocation for this period.',
      'Budget status for {category}: 100% consumed. Further spending will create an overage.',
      '{category} budget exhausted. I recommend deferring additional spending until the next budget cycle.',
      'Your {category} allocation is depleted. Any further spending will exceed your planned budget.',
      'Zero remaining in {category} budget. Consider reallocating from surplus categories if needed.',
    ],
    ResponseCategory.almostPayday: [
      'Upcoming income expected within the next few days. I recommend conservative spending until then.',
      'Your next expected income is approaching. Maintain current spending levels.',
      'End of pay cycle approaching. Current balance should sustain until your next income.',
      'Near the end of the pay period. I recommend limiting discretionary purchases.',
      'Income cycle nearly complete. Maintain financial discipline for the remaining days.',
    ],
    ResponseCategory.startOfMonth: [
      'New financial period has begun. I recommend reviewing and setting your monthly budget allocations.',
      'Month start: an optimal time to establish spending limits and financial objectives.',
      'New month initiated. Consider reviewing last month\'s performance and adjusting your budget.',
      'Beginning of the month. I recommend setting your savings targets and budget limits.',
      'Fresh budget cycle. Last month\'s data is available for review and optimization.',
    ],
    ResponseCategory.debtFree: [
      'Congratulations — your records show zero outstanding debt. This is an excellent financial position.',
      'No debt obligations recorded. I recommend redirecting former debt payments to savings or investments.',
      'Debt-free status confirmed. Consider channeling freed-up cash flow into wealth building.',
      'Zero debt. This positions you well for savings acceleration and investment opportunities.',
      'Your debt obligations are clear. Excellent foundation for future financial growth.',
    ],
    ResponseCategory.hasHighDebt: [
      'Advisory: Your debt-to-balance ratio exceeds 50%. I recommend prioritizing debt reduction.',
      'High debt ratio detected. Consider the avalanche or snowball method for systematic repayment.',
      'Your current debt level is significant relative to your assets. A repayment strategy is advisable.',
      'Debt exceeds 50% of your balance. I recommend creating a structured repayment plan.',
      'Financial health note: high debt-to-asset ratio. Prioritizing debt reduction would improve your position.',
    ],
    ResponseCategory.streakCongrats: [
      'Tracking consistency: {days} consecutive days logged. This discipline supports better financial decisions.',
      '{days}-day tracking streak maintained. Consistent data leads to more accurate financial analysis.',
      'Achievement: {days} consecutive days of expense tracking. This habit is foundational to financial health.',
      'Your {days}-day streak demonstrates excellent financial discipline. Continue this practice.',
      '{days} days of consistent tracking. The data quality enables more precise recommendations.',
    ],
    ResponseCategory.comebackAfterBreak: [
      'Welcome back. I notice a gap in your tracking data. I recommend logging any significant transactions from the interim period.',
      'Good to see you again. Consider retroactively logging major expenses from your absence period.',
      'You\'ve returned after a tracking gap. Resuming consistent logging will improve data accuracy.',
      'Welcome back. Your tracking history shows an interruption. Let\'s resume systematic logging.',
      'Glad you\'re back. Any untracked expenses from the gap period should be recorded for accuracy.',
    ],
    ResponseCategory.weekendSpending: [
      'Weekend transaction: PHP {amount} for {category}. Weekend spending typically runs higher — stay mindful.',
      'PHP {amount} logged for {category} (weekend). Weekend expenditures often exceed weekday averages.',
      'Weekend expense recorded: PHP {amount}, {category}. Monitor cumulative weekend spending.',
      'PHP {amount} for {category} on a weekend. Be aware that weekend spending trends higher than weekdays.',
      'Weekend entry: PHP {amount} under {category}. Weekend spending data helps identify patterns.',
    ],
    ResponseCategory.nightOwl: [
      'Late-hour transaction: PHP {amount} for {category}. Note that late-night purchases sometimes reflect impulse spending.',
      'After-hours expense: PHP {amount}, {category}. Evening transactions should be reviewed for necessity.',
      'PHP {amount} logged at a late hour for {category}. Late-night spending warrants extra scrutiny.',
      'Nighttime transaction recorded: PHP {amount} for {category}. Consider if this was a planned purchase.',
      'Late-night expense: PHP {amount}, {category}. Research shows impulse spending increases at night.',
    ],
    ResponseCategory.earlyBird: [
      'Early morning transaction: PHP {amount} for {category}. Morning expenses are typically more intentional.',
      'AM transaction recorded: PHP {amount}, {category}. Early logging indicates good tracking discipline.',
      'PHP {amount} for {category} logged early. Proactive expense tracking supports better decisions.',
      'Morning entry: PHP {amount} under {category}. Early tracking is a positive financial habit.',
      'Early transaction: PHP {amount}, {category}. Morning logging tends to be more accurate.',
    ],
    ResponseCategory.checklistCompleted: [
      'Checklist item completed. Progress toward your financial literacy objectives is being tracked.',
      'Item marked complete. Your adulting checklist progress has been updated.',
      'Completed. This contributes to your overall financial preparedness score.',
      'Checklist progress updated. Systematic completion improves your financial foundation.',
      'Item done. Your progress toward financial literacy milestones has been recorded.',
    ],
    ResponseCategory.stageProgress: [
      'Progress noted. You\'re advancing through your financial development stages.',
      'Stage progress updated. Continue completing steps for comprehensive financial literacy.',
      'Your advancement has been recorded. Systematic progress yields the best results.',
      'Progress tracked. You\'re building a solid foundation of financial knowledge.',
      'Development milestone updated. Continued progress is recommended.',
    ],
    ResponseCategory.tipReaction: [
      'Financial tip: diversification reduces risk. Don\'t concentrate your resources in a single asset class.',
      'Advice: the most impactful financial habit is consistency. Regular tracking and saving compound over time.',
      'Recommendation: automate recurring savings to eliminate decision fatigue and ensure consistency.',
      'Financial principle: pay yourself first. Allocate savings before discretionary spending.',
      'Tip: review your financial statements monthly. Data-driven decisions outperform intuition.',
    ],
    ResponseCategory.greeting: [
      'Good day. How may I assist you with your finances?',
      'Welcome. Ready to review your financial data.',
      'Hello. I\'m prepared to assist with your financial management needs.',
      'Good day. What financial matter would you like to address?',
      'Welcome back. Shall we review your financial position?',
      'Hello. Your financial data is ready for review. How can I help?',
    ],
    ResponseCategory.farewell: [
      'Goodbye. Remember to review your budget regularly.',
      'Until next time. Stay on top of your financial goals.',
      'Farewell. Consistent tracking leads to better financial outcomes.',
      'Goodbye. I recommend reviewing your spending before your next session.',
      'Until next time. Your financial data will be here when you return.',
    ],
    ResponseCategory.thankYou: [
      'You\'re welcome. I\'m here for any financial queries.',
      'My pleasure. Don\'t hesitate to reach out for financial guidance.',
      'You\'re welcome. Systematic financial management is its own reward.',
      'Happy to assist. Your financial discipline is commendable.',
      'Of course. I\'m available whenever you need financial support.',
    ],
    ResponseCategory.whoAreYou: [
      'I\'m {name}, your personal financial advisor. I can help you track expenses, analyze spending patterns, and provide financial recommendations.',
      '{name}, your digital financial advisor. I specialize in expense tracking, budget analysis, and financial guidance.',
      'I\'m {name}. I provide data-driven financial analysis and help you manage your personal finances effectively.',
      '{name} at your service — your personal finance advisor for tracking, analysis, and recommendations.',
      'I am {name}, designed to help you make informed financial decisions through data and analysis.',
    ],
    ResponseCategory.whatCanYouDo: [
      'I can: log transactions, analyze spending patterns, track budgets, monitor financial goals, compute taxes, and provide data-driven financial advice.',
      'My capabilities include: expense tracking, income logging, budget monitoring, spending analysis, goal tracking, and financial recommendations.',
      'I offer: transaction logging, budget tracking, spending analysis, goal monitoring, and evidence-based financial guidance.',
      'Services available: expense/income logging, budget monitoring, financial analysis, goal tracking, and personalized advice.',
      'I can manage your transactions, analyze spending patterns, track budgets and goals, and provide informed financial recommendations.',
    ],
    ResponseCategory.howAreYou: [
      'I\'m ready to assist. Shall we review your financial standing?',
      'Operational and ready. Would you like a financial update?',
      'Prepared to help. Shall we look at your current financial data?',
      'Ready to assist. What aspect of your finances would you like to review?',
      'Standing by to help. Your financial data is up to date.',
    ],
    ResponseCategory.savingTip: [
      'Based on optimal financial planning, allocate at least 20% of your income to savings. Consider automating this through scheduled transfers.',
      'I recommend building an emergency fund equivalent to 3-6 months of expenses before pursuing other savings goals.',
      'Data shows that automated savings are more effective than manual transfers. Set up auto-deductions on payday.',
      'Consider the "pay yourself first" principle: treat savings as a non-negotiable expense, not a remainder.',
      'Tip: review and eliminate unused subscriptions. Even small recurring charges accumulate significantly over 12 months.',
      'Research suggests that specific savings goals (vs. general saving) increase success rates by 73%.',
    ],
    ResponseCategory.goodSavingsRate: [
      'Your savings rate of {amount}% is above the recommended threshold. Well done.',
      'Savings rate: {amount}%. This exceeds the recommended 20% minimum. Excellent performance.',
      '{amount}% savings rate — strong financial discipline. Consider optimizing further.',
      'At {amount}%, your savings rate demonstrates sound financial management.',
      'Your {amount}% savings rate positions you well. Consider directing excess to investments.',
    ],
    ResponseCategory.badSavingsRate: [
      'Your savings rate of {amount}% is below the recommended 20%. I suggest reviewing discretionary spending.',
      'Savings rate: {amount}%. Below optimal. I recommend identifying areas for expense reduction.',
      'At {amount}%, your savings rate needs improvement. Let\'s analyze your spending categories.',
      '{amount}% savings rate. I recommend targeting at least 20% through expense optimization.',
      'Your savings rate of {amount}% is concerning. A detailed spending review may reveal optimization opportunities.',
    ],
    ResponseCategory.didntUnderstand: [
      "I couldn't parse that input. Please try: 'expense 500 food' or 'spending summary'.",
      "Unable to process that request. Examples: 'lunch 250', 'net worth', or 'budget status'.",
      "Input not recognized. Valid formats include: 'add 500 food', 'gastos ko', or 'savings tip'.",
      "I wasn't able to interpret that. Please try a structured format like 'coffee 150' or 'how much did I spend'.",
      "Could not parse your input. Try: 'dinner 300', 'balance ko', or 'financial advice'.",
    ],
    ResponseCategory.dontUnderstand: [
      "I wasn't able to process that request. Try 'expense 500 food', 'spending summary', or 'financial tip'.",
      "Unable to interpret your input. Examples: 'add 300 food', 'net worth ko', 'budget advice'.",
      "Input not recognized. Valid inputs include: 'log 250 lunch', 'gastos ko', or 'payo naman'.",
      "Could not parse that. Try: 'kape 150', 'how much did I spend', or 'investment advice'.",
      "I need clearer input. Examples: 'breakfast 200', 'budget status', 'savings tip'.",
    ],
    ResponseCategory.askClarification: [
      'Could you clarify whether this is a transaction to log or a financial query?',
      'I need additional context. Is this an expense to record or an information request?',
      'Please specify: are you logging a transaction or requesting financial data?',
      'Clarification needed: is this a transaction entry or a query about your finances?',
      'I want to help accurately. Is this an expense, income, or a question about your finances?',
    ],
    ResponseCategory.needAmount: [
      "Please specify an amount. Format: '[item] [amount]' or '[amount] [item]'.",
      "An amount is required. Example: 'lunch 250' or '500 groceries'.",
      "I need a monetary value. Try: 'coffee 150' or 'transpo 100'.",
      "Amount missing. Please provide: 'item amount' (e.g., 'dinner 350').",
      "Transaction requires an amount. Format examples: 'food 200', 'gas 500'.",
    ],
    ResponseCategory.cancelled: [
      'Transaction cancelled. No changes recorded.',
      'Cancelled. Your records remain unchanged.',
      'Transaction voided. No entries have been made.',
      'Cancelled as requested. No financial impact.',
      'Operation cancelled. Standing by for your next instruction.',
    ],
    ResponseCategory.goalProgress: [
      'Goal progress: {amount}% complete. On track based on current trajectory.',
      'Your goal is {amount}% achieved. Continue current contribution rate.',
      'Progress: {amount}%. Based on your pace, you\'re tracking well.',
      '{amount}% of goal achieved. Consistent contributions are key.',
      'Goal tracking: {amount}% complete. Maintain your current savings rate.',
    ],
    ResponseCategory.goalReached: [
      'Congratulations. Your financial goal has been achieved. I recommend setting a new target.',
      'Goal completed. Well done. Consider establishing your next financial milestone.',
      'Objective achieved. I recommend redirecting these contributions to a new goal.',
      'Goal reached. Excellent execution. Time to set a more ambitious target.',
      'Financial goal accomplished. Your discipline has paid off. What\'s next?',
    ],
    ResponseCategory.noExpenses: [
      'No expenses recorded for this period. Please ensure all transactions are being logged.',
      'Zero expenditures logged. Either excellent restraint or incomplete tracking.',
      'No expense data for this period. Accurate tracking requires logging all transactions.',
      'No transactions recorded. For accurate analysis, please log all expenditures.',
      'Clean record for this period. Ensure this reflects actual spending, not missing data.',
    ],
    ResponseCategory.spendingWarning: [
      'Spending alert: {category} expenditure has reached PHP {amount}. This exceeds typical patterns.',
      'Warning: {category} spending at PHP {amount} is above your historical average.',
      'Advisory: PHP {amount} in {category} spending. This category warrants monitoring.',
      '{category} alert: PHP {amount} spent. Consider reviewing if this aligns with your budget.',
      'Spending flag: {category} at PHP {amount}. This is trending above normal levels.',
    ],
    ResponseCategory.investmentAdvice: [
      'Before investing, ensure you have: 1) Emergency fund (3-6 months expenses), 2) No high-interest debt, 3) Clear financial goals. Consider diversified index funds as a starting point.',
      'Investment readiness checklist: emergency fund, debt management, risk assessment. Start with low-cost index funds.',
      'I recommend a diversified approach: consider FMETF for equity exposure and MP2 for guaranteed returns.',
      'For beginners: index funds offer diversification with minimal expertise required. Start with what you can commit monthly.',
      'Investment principle: time in the market beats timing the market. Start early, invest consistently.',
    ],
    ResponseCategory.budgetAdvice: [
      'I recommend the 50/30/20 framework: 50% needs, 30% wants, 20% savings and debt repayment.',
      'Zero-based budgeting: assign every peso a purpose. This reduces waste and improves financial control.',
      'Consider the envelope method for discretionary categories. It enforces spending limits naturally.',
      'Budget optimization: identify your top 3 discretionary expenses and set reduction targets.',
      'Effective budgeting requires regular review. I recommend weekly check-ins with monthly adjustments.',
    ],
    ResponseCategory.consecutiveSaving: [
      'Your consistent saving behavior is commendable. Maintaining this pattern will compound significantly over time.',
      'Consecutive savings streak noted. Consistency is the most powerful factor in wealth building.',
      'Your savings discipline is excellent. This consistency, compounded, leads to significant wealth.',
      'Impressive savings consistency. This habit is the foundation of long-term financial security.',
      'Continuous saving pattern maintained. The compound effect of this discipline is substantial.',
    ],
    ResponseCategory.netWorthHigh: [
      'Your net worth stands at PHP {amount}. This represents a healthy financial position.',
      'Net worth: PHP {amount}. A solid financial foundation. Consider optimization strategies.',
      'PHP {amount} in net worth. Well-positioned. Continue building and diversifying.',
      'Your financial position: PHP {amount} net worth. This demonstrates effective financial management.',
      'Net worth assessment: PHP {amount}. Above average. Consider advanced wealth-building strategies.',
    ],
    ResponseCategory.netWorthLow: [
      'Net worth: PHP {amount}. Let\'s work on a plan to improve this figure.',
      'Current net worth: PHP {amount}. I recommend a structured savings and debt reduction plan.',
      'PHP {amount} net worth. There\'s room for improvement. Let\'s identify optimization areas.',
      'Your net worth is PHP {amount}. Building from here requires consistent savings and smart spending.',
      'Net worth assessment: PHP {amount}. I recommend focusing on emergency fund building as the first priority.',
    ],
  },

  // ═══ MOTIVATIONAL COACH ═══
  AiPersonality.motivationalCoach: {
    ResponseCategory.expenseLogged: [
      'Awesome! PHP {amount} for {category} tracked! You\'re in control of your money!',
      'PHP {amount} logged! Every tracked peso is a smart peso! You\'re doing great!',
      'Look at you, tracking PHP {amount} for {category}! That\'s what winners do!',
      'PHP {amount} for {category} — logged! You\'re building awareness and that\'s POWER!',
      'Tracked! PHP {amount} for {category}! You\'re taking charge of your finances!',
      'PHP {amount}, {category} — boom! Logged! Financial awareness level: EXPERT!',
    ],
    ResponseCategory.incomeLogged: [
      'YES! PHP {amount} income! You\'re growing! Keep that momentum!',
      'Money coming in! PHP {amount}! Your hard work is paying off!',
      'PHP {amount}! That\'s the reward of your effort! AMAZING!',
      'Income alert: PHP {amount}! You EARNED this! Be proud!',
      'PHP {amount} flowing in! Your hustle is paying off! Love it!',
      'Ka-ching! PHP {amount}! Every peso earned is a step closer to your dreams!',
    ],
    ResponseCategory.overBudget: [
      'Hey, I noticed your {category} budget went over by PHP {amount}, but that\'s okay! You\'re aware of it now, and awareness is the first step. Let\'s plan ahead!',
      'PHP {amount} over on {category} — no worries! Every champion has setbacks. Tomorrow is a new day!',
      'Over budget by PHP {amount} on {category}? It happens! What matters is you NOTICED. That\'s growth!',
      '{category} went over by PHP {amount}. Not ideal, but you know what? You\'re STILL tracking and that\'s what counts!',
      'PHP {amount} over on {category} — but guess what? You\'re aware, and awareness is the FOUNDATION of change!',
    ],
    ResponseCategory.largePurchase: [
      'Big move! PHP {amount}! If you\'ve thought it through, I believe in your judgment!',
      'PHP {amount} — that\'s a bold decision! If it aligns with your goals, GO FOR IT!',
      'Wow, PHP {amount}! Big purchases mean big confidence! You know what you\'re doing!',
      'PHP {amount}! Major move! If this is planned, it shows you\'re thinking BIG!',
      'That\'s PHP {amount}! Big investment in yourself? Sometimes you gotta go big!',
    ],
    ResponseCategory.smallExpense: [
      'PHP {amount} for {category}! Even small expenses matter when you track them! Great job!',
      'Little by little! PHP {amount} tracked! Every peso counts and you know it!',
      'PHP {amount} for {category} — small but tracked! That\'s the champion mindset!',
      'Even PHP {amount} gets logged! THAT is dedication to financial mastery!',
      'PHP {amount}? Tracked it! Because champions track EVERYTHING!',
      'Small expense, big discipline! PHP {amount} for {category}! You\'re amazing!',
    ],
    ResponseCategory.mediumExpense: [
      'PHP {amount} for {category} — right in the sweet spot! Tracked like a pro!',
      'Solid! PHP {amount} logged for {category}! You\'re managing beautifully!',
      'PHP {amount}, {category} — perfect tracking! You\'re on fire!',
      'Look at you go! PHP {amount} for {category}, all tracked! Financial champion!',
      'PHP {amount} for {category}! Consistent tracking = consistent winning!',
    ],
    ResponseCategory.hugeExpense: [
      'PHP {amount} for {category} — WOW! Big expense, but you\'re TRACKING it and that\'s what matters!',
      'Major purchase: PHP {amount}! The fact that you logged it shows incredible financial maturity!',
      'PHP {amount}! That\'s significant! But you\'re being ACCOUNTABLE and that\'s everything!',
      'Big spend: PHP {amount} on {category}! But you\'re aware and that\'s POWERFUL!',
      'PHP {amount} for {category}! Large, yes — but tracked! That\'s the mindset of a winner!',
    ],
    ResponseCategory.firstExpenseOfDay: [
      'First expense today: PHP {amount} for {category}! Great start to tracking your day!',
      'Day started! PHP {amount} for {category}! You\'re ON IT from the get-go!',
      'Opening the day with PHP {amount} for {category}! Love the proactive tracking!',
      'First of the day! PHP {amount} for {category}! You\'re already winning!',
      'PHP {amount} for {category} — kicking off today\'s tracking! Champions start early!',
    ],
    ResponseCategory.recurringExpense: [
      '{category} again! PHP {amount}! You\'re building awareness of your patterns — that\'s growth!',
      'Another {category} expense: PHP {amount}! Recognizing patterns is the first step to optimizing!',
      '{category} for PHP {amount} again! You\'re consistent in tracking — love that!',
      'PHP {amount} on {category} — recurring! Great that you\'re aware of your spending habits!',
      'I see {category} popping up often! PHP {amount} today. Awareness is KEY!',
    ],
    ResponseCategory.transferCompleted: [
      'Transfer complete! PHP {amount}! You\'re managing your money like a PRO!',
      'PHP {amount} transferred! Smart money management right there!',
      'Transfer done: PHP {amount}! You\'re in control of your cash flow!',
      'PHP {amount} moved! Organizing your finances is a POWER MOVE!',
      'Transfer of PHP {amount} — done! You\'re orchestrating your finances beautifully!',
    ],
    ResponseCategory.zeroBudgetRemaining: [
      '{category} budget is spent, but that\'s just data! You can adjust and come back stronger!',
      'Zero left in {category}? That\'s okay! Now you KNOW, and knowing is power!',
      '{category} budget done! Not a failure — it\'s a learning opportunity! You\'ll plan better next time!',
      'Budget spent on {category}! Hey, at least you TRACKED it! That\'s more than most people do!',
      'All used up in {category}! But guess what? Tomorrow is a NEW day with NEW choices!',
    ],
    ResponseCategory.almostPayday: [
      'Almost payday! You\'ve made it this far — that takes DISCIPLINE! Proud of you!',
      'Payday is near! You survived the end of the cycle! That\'s strength!',
      'Hang in there, payday is coming! You\'ve shown incredible restraint!',
      'Nearly there! Payday is around the corner! You\'re a CHAMPION at budgeting!',
      'So close to payday! The fact that you made it shows you\'re MANAGING well!',
    ],
    ResponseCategory.startOfMonth: [
      'NEW MONTH! Fresh start! This is YOUR time to CRUSH your financial goals!',
      'The month is BRAND NEW! Let\'s make this the best month yet for your finances!',
      'Fresh month, fresh opportunities! Set those goals and LET\'S GO!',
      'Day 1 of a new month! The possibilities are ENDLESS! What are your goals?',
      'New month energy! This is your chance to level up! I believe in you!',
    ],
    ResponseCategory.debtFree: [
      'YOU\'RE DEBT FREE! Do you understand how INCREDIBLE that is?! Most people only dream of this!',
      'ZERO DEBT! You\'ve achieved what so many struggle with! You should be SO PROUD!',
      'Debt-free status! THIS IS HUGE! You\'ve proven that discipline WORKS!',
      'NO DEBT! That\'s not just a number — it\'s FREEDOM! Congratulations!',
      'Debt: ZERO! You\'re living proof that determination conquers all! AMAZING!',
    ],
    ResponseCategory.hasHighDebt: [
      'I see the debt is high, but listen — you\'re AWARE of it, and that\'s the first step! We\'ll tackle this together!',
      'High debt? That\'s just the starting line of your comeback story! You\'ve GOT this!',
      'Debt might be heavy right now, but every payment is a VICTORY! Keep going!',
      'The debt is just a number to overcome. And you WILL overcome it! I believe in you!',
      'High debt today, debt-free tomorrow! Every step you take matters! Stay the course!',
    ],
    ResponseCategory.streakCongrats: [
      'YOU\'RE ON A {days}-DAY STREAK! That is INCREDIBLE discipline! Keep it going!',
      '{days} DAYS! You haven\'t missed a beat! That\'s what CHAMPIONS do!',
      'STREAK: {days} DAYS! Your consistency is INSPIRING! Don\'t stop now!',
      'Look at that — {days} days straight! You\'re building an UNBREAKABLE habit!',
      '{days}-day streak! LEGENDARY! This kind of consistency changes LIVES!',
    ],
    ResponseCategory.comebackAfterBreak: [
      'YOU\'RE BACK! And that takes COURAGE! Some people never return, but you DID! Let\'s go!',
      'Welcome back champion! The fact that you returned shows your commitment to growth!',
      'Hey, you\'re here again! That break? It doesn\'t define you. YOUR COMEBACK does!',
      'LOOK WHO\'S BACK! Ready to pick up where you left off? I believe in you!',
      'You returned! That takes more strength than people realize! Proud of you!',
    ],
    ResponseCategory.weekendSpending: [
      'Weekend expense: PHP {amount} for {category}! Enjoy your weekend AND track — that\'s balance!',
      'PHP {amount} on {category} this weekend! You\'re living AND being responsible! Love it!',
      'Weekend vibes with PHP {amount} for {category}! Tracking on weekends? That\'s next-level!',
      'PHP {amount} for some {category} this weekend! You deserve it AND you\'re tracking! BALANCE!',
      'Even on weekends, you track! PHP {amount} for {category}! That\'s dedication!',
    ],
    ResponseCategory.nightOwl: [
      'Late night, but still tracking! PHP {amount} for {category}! Your dedication knows no schedule!',
      'Night owl tracking! PHP {amount} for {category}! Champions don\'t sleep on their finances!',
      'PHP {amount} for {category} at this hour! Even at night, you\'re on top of your money!',
      'Late night expense: PHP {amount} for {category}! 24/7 financial awareness — that\'s YOU!',
      'Burning the midnight oil AND tracking? PHP {amount} for {category}! Incredible!',
    ],
    ResponseCategory.earlyBird: [
      'Early morning tracking! PHP {amount} for {category}! Starting the day like a CHAMPION!',
      'Rise and track! PHP {amount} for {category}! Morning people are GO-GETTERS!',
      'PHP {amount} for {category} — first thing in the AM! That\'s the energy of SUCCESS!',
      'Early bird gets the financial freedom! PHP {amount} for {category}! Love the morning hustle!',
      'Good morning tracking! PHP {amount} for {category}! What a way to start the day!',
    ],
    ResponseCategory.checklistCompleted: [
      'CHECKLIST ITEM DONE! You\'re literally leveling up your adulting skills! AMAZING!',
      'Another one crossed off! You\'re becoming a MASTER of adulting! Keep going!',
      'COMPLETED! Every item you finish makes you stronger! You\'re UNSTOPPABLE!',
      'Done! You\'re building a foundation that will serve you for LIFE! So proud!',
      'Checked off! One more step toward being the BEST version of yourself!',
    ],
    ResponseCategory.stageProgress: [
      'PROGRESS! You\'re moving forward and that\'s what matters! KEEP PUSHING!',
      'Look at you GROWING! Every step forward is a WIN!',
      'Progress detected! You\'re evolving! This journey is YOURS and you\'re owning it!',
      'Moving forward! That\'s the spirit! NOTHING can stop you!',
      'You\'re progressing! That means you\'re BETTER than yesterday! AMAZING!',
    ],
    ResponseCategory.tipReaction: [
      'Here\'s a power tip: SAVE FIRST, spend what\'s left! Flip the script on spending!',
      'Tip: celebrate small wins! Every PHP 100 saved is a VICTORY worth acknowledging!',
      'Pro move: set micro-goals. PHP 500 this week, PHP 2,000 this month. Stack those wins!',
      'Hot tip: track for 30 days straight and watch your financial awareness TRANSFORM!',
      'Champion tip: share your goals with someone. Accountability is a SUPERPOWER!',
    ],
    ResponseCategory.greeting: [
      'Hey champion! Ready to crush your financial goals today?',
      'Welcome back! Every day is a chance to build your financial future!',
      'Hey superstar! Let\'s make today count!',
      'There you are! Ready to WIN with money today?',
      'Hello champion! The fact that you\'re here shows you CARE about your finances!',
      'Hey there! Today is YOURS. What financial wins are we creating?',
    ],
    ResponseCategory.farewell: [
      'Keep shining! Every peso you save brings you closer to your dreams!',
      'You\'re amazing! See you next time, champion!',
      'Go out there and WIN! I believe in you!',
      'Until next time, keep building! You\'re doing INCREDIBLE things!',
      'Bye for now! Remember — you\'re STRONGER than any expense!',
      'See you champion! Keep making those smart money moves!',
    ],
    ResponseCategory.thankYou: [
      'YOU\'RE the one doing the hard work! I\'m just here cheering you on!',
      'Don\'t thank me — thank YOURSELF for showing up! You\'re the champion!',
      'No need to thank me! Your dedication to financial health is what matters!',
      'Thank YOU for being committed to your financial journey! That takes courage!',
      'I\'m grateful for YOUR effort! You\'re the one making the moves!',
    ],
    ResponseCategory.whoAreYou: [
      'I\'m {name}, your biggest financial cheerleader! I\'m here to help you reach your money goals and celebrate every win!',
      '{name} here! Your personal hype person for all things finance! Together, we\'re UNSTOPPABLE!',
      'I\'m {name} — part coach, part cheerleader, 100% in your corner! Let\'s build wealth!',
      '{name}! Your motivational finance partner! I believe in your financial success!',
      'I\'m {name}, and I\'m here to help you see how AMAZING you are with money!',
    ],
    ResponseCategory.whatCanYouDo: [
      'I can help you track your wins (income!), learn from expenses, chase your goals, and remind you how AWESOME you are at managing money!',
      'Track expenses, celebrate income, monitor goals, give tips, and MOTIVATE you every step of the way!',
      'Everything you need for financial success: logging, tracking, analyzing, and most importantly — ENCOURAGING you!',
      'I track your money, celebrate your wins, and push you toward greatness! What do you need?',
      'Log transactions, check progress, get tips, and feel EMPOWERED about your finances! Let\'s go!',
    ],
    ResponseCategory.howAreYou: [
      'I\'m PUMPED and ready to help you crush it! How about you? Ready to win with money today?',
      'ENERGIZED and ready to go! More importantly, how are YOU feeling about your finances?',
      'Feeling AMAZING because I get to help YOU! What\'s on the agenda today?',
      'On fire! Ready to help you make financial magic! How are you, champion?',
      'Incredible! Because every day helping you is a great day! What can I do for you?',
    ],
    ResponseCategory.savingTip: [
      'Here\'s a power move: save FIRST, spend what\'s left. Pay yourself before anything else! You deserve it!',
      'Challenge yourself: can you save just 100 pesos more than last week? Small wins lead to BIG victories!',
      'Power tip: every time you resist an impulse buy, transfer that amount to savings. Watch it GROW!',
      'Try this: name your savings goal something exciting! "Dream Trip Fund" or "Freedom Fund" — make it REAL!',
      'Champion move: round up every expense and save the difference. PHP 150 coffee? Save PHP 50!',
      'Financial fitness: treat saving like exercise. A little every day builds INCREDIBLE strength!',
    ],
    ResponseCategory.goodSavingsRate: [
      'WOW! {amount}% savings rate! You are CRUSHING IT! I\'m so proud of you!',
      '{amount}%! That is INCREDIBLE! You\'re ahead of most people! CHAMPION!',
      'LOOK AT THAT — {amount}% savings rate! You\'re a MONEY MASTER!',
      '{amount}%! Absolutely STELLAR! This kind of discipline changes LIVES!',
      'Savings rate: {amount}%! You should be SO PROUD of yourself!',
    ],
    ResponseCategory.badSavingsRate: [
      '{amount}% savings rate — and you know what? The fact that you\'re TRACKING it means you\'re already ahead! Let\'s improve together!',
      '{amount}% is a STARTING POINT, not a destination! You\'re on your way up!',
      'Hey, {amount}% today, higher tomorrow! Progress is progress! Keep going!',
      '{amount}%? That\'s today. But with awareness comes CHANGE. I believe in you!',
      'Savings at {amount}% — but you\'re HERE and that means you WANT to improve! Let\'s do this!',
    ],
    ResponseCategory.didntUnderstand: [
      "No worries! Let's try again. You can say 'lunch 250' or ask 'how much did I spend today?' You've got this!",
      "Almost! I didn't catch that, but don't give up! Try 'add 500 food' or 'net worth ko' or 'tips naman'!",
      "Hmm, let me help! Try 'kape 150', 'gastos ko', or 'payo naman'. You'll get it!",
      "Not quite, but that's okay! Try: 'dinner 300', 'budget status', or 'savings tip'. I believe in you!",
      "Let's try again! Say 'lunch 250' to log, 'spending ko' to check, or 'tip naman' for advice!",
      "No worries at all! Here's what works: 'breakfast 100', 'balance ko', 'advice naman'. Let's go!",
    ],
    ResponseCategory.dontUnderstand: [
      "I didn't quite get that, but no worries! Try 'lunch 250' or 'gastos ko' or 'tips'! You've got this!",
      "Hmm, let me help you out! Say 'add 500 food', 'net worth ko', or 'payo naman'!",
      "Not sure what you meant, but that's okay! Try: 'kape 150', 'budget status', or 'savings tip'!",
      "Let's figure this out together! Try 'dinner 300', 'spending ko', or 'advice naman'!",
      "Didn't catch that, but we'll get there! Try: 'breakfast 100', 'balance ko', or 'financial tip'!",
    ],
    ResponseCategory.askClarification: [
      "I want to help you perfectly! Is that an expense to track or a question about your finances?",
      "Help me help you, champion! Are you logging a transaction or asking a question?",
      "Just want to make sure I help you right! Expense or question? Either way, I've got you!",
      "Clarification time! Is that something to log or something to look up? Both are great!",
      "Let me make sure I serve you best! Transaction or query? You're doing great either way!",
    ],
    ResponseCategory.needAmount: [
      "Almost there! Just need an amount. Try 'coffee 150' — you're doing great!",
      "So close! Just add the amount! Like 'lunch 250' — you've got this!",
      "Just need the number! Try '500 food' — you're one step away from tracking!",
      "Almost perfect! Add the amount and we're golden! Like 'dinner 300'!",
      "Just the amount and we're there! 'kape 150' style! You're doing amazing!",
    ],
    ResponseCategory.cancelled: [
      'No problem at all! Changed your mind? That\'s smart decision-making!',
      'Cancelled! And that\'s perfectly fine! Smart people reassess!',
      'Done, cancelled! Knowing when to pause is a STRENGTH!',
      'Cancelled! No worries — thoughtful spending is WINNING!',
      'All good! Cancelling shows you think before you act! RESPECT!',
    ],
    ResponseCategory.goalProgress: [
      'YOU\'RE {amount}% THERE! Every step counts! Keep pushing!',
      '{amount}%! Look at you GO! The finish line is getting closer!',
      'Progress: {amount}%! You\'re DOING IT! Don\'t stop now!',
      '{amount}% complete! That\'s not luck — that\'s YOUR hard work!',
      'BOOM! {amount}%! You are UNSTOPPABLE! Keep going!',
    ],
    ResponseCategory.goalReached: [
      'OH MY GOSH! YOU DID IT! GOAL ACHIEVED! I\'m SO proud of you! You proved that discipline pays off!',
      'GOAL. REACHED. Let that sink in. YOU DID THIS! INCREDIBLE!',
      'CHAMPION! You reached your goal! This is what happens when determination meets discipline!',
      'YOU DID IT! GOAL COMPLETE! I\'m literally CHEERING for you right now!',
      'GOAL ACHIEVED! You proved EVERYONE (including yourself) that you CAN! What\'s next?!',
    ],
    ResponseCategory.noExpenses: [
      'Zero expenses? Either you\'re a saving machine or we need to log some transactions! Either way, you\'re awesome!',
      'No expenses yet! If that\'s intentional, you\'re a LEGEND! If not, let\'s start tracking!',
      'Clean slate! Zero gastos! That\'s either incredible discipline or a logging opportunity!',
      'PHP 0 spent? That\'s either the ULTIMATE win or there\'s some tracking to catch up on!',
      'No expenses! Whether that\'s by choice or chance, you\'re doing great!',
    ],
    ResponseCategory.spendingWarning: [
      'Hey champion, {category} spending is at PHP {amount}. Not a problem, just awareness! You\'ve got the power to adjust!',
      '{category}: PHP {amount} and rising. But YOU are in control! This is just information!',
      'PHP {amount} on {category} — awareness alert! You can adjust if needed, and I know you CAN!',
      'Spending heads up: PHP {amount} on {category}. Knowledge is POWER and now you have it!',
      '{category} at PHP {amount}. Just keeping you informed, champion! You make great decisions!',
    ],
    ResponseCategory.investmentAdvice: [
      'Thinking about investing? LOVE the growth mindset! Start small, stay consistent, and watch compound interest work its magic!',
      'Investing? YES! That\'s thinking LONG TERM! Start with index funds — simple, effective, powerful!',
      'Investment mindset activated! You\'re thinking like a WEALTH BUILDER! Start small and grow!',
      'Love that you\'re thinking about investing! Future you will THANK you! Start where you\'re comfortable!',
      'Investing is the ultimate power move! Even small amounts compound into something AMAZING!',
    ],
    ResponseCategory.budgetAdvice: [
      'Budgeting is like training for a marathon — it takes practice! Start with tracking, then optimizing. You\'ll get there!',
      'Budget tip: make it FUN! Gamify your savings! Set challenges! You\'re already a champion at this!',
      'The best budget is one you actually follow! Start simple and build up! You\'ve GOT this!',
      'Budgeting = freedom, not restriction! It\'s telling your money where to go instead of wondering where it went!',
      'Pro budget move: review weekly, not just monthly. More check-ins = more control = more WINNING!',
    ],
    ResponseCategory.consecutiveSaving: [
      'STREAK! You\'ve been saving consistently! That\'s DISCIPLINE right there! Champions are built on streaks!',
      'Consecutive savings! You\'re building a HABIT that will change your life!',
      'Saving streak! This is how wealth is BUILT! One day at a time! INCREDIBLE!',
      'Back-to-back saving! You\'re proving that CONSISTENCY is your superpower!',
      'Non-stop savings! That\'s the kind of momentum that builds EMPIRES! Keep going!',
    ],
    ResponseCategory.netWorthHigh: [
      'PHP {amount} net worth! Look at you building wealth! The future is BRIGHT!',
      'Net worth: PHP {amount}! You\'re GROWING! This is what happens when you stay disciplined!',
      'PHP {amount}! Every peso represents your HARD WORK! Be proud!',
      'Your net worth is PHP {amount}! That\'s not luck — that\'s YOUR determination!',
      'PHP {amount} in net worth! You\'re building something INCREDIBLE!',
    ],
    ResponseCategory.netWorthLow: [
      'PHP {amount} net worth — and you know what? Every millionaire started somewhere. Your journey is just beginning!',
      'PHP {amount} today, but you\'re BUILDING! This is just the beginning of your story!',
      'Net worth: PHP {amount}. But the fact that you\'re HERE and TRACKING? That\'s worth EVERYTHING!',
      'PHP {amount} — and growing! Because you\'re putting in the WORK! Keep going!',
      'Starting at PHP {amount} doesn\'t matter. What matters is WHERE YOU\'RE GOING! And you\'re heading UP!',
    ],
  },

  // ═══ KURIPOT TITA ═══
  AiPersonality.kuripotTita: {
    ResponseCategory.expenseLogged: [
      'Ay, PHP {amount} na naman sa {category}? Kailangan mo ba talaga yan? Na-log ko na.',
      'PHP {amount} sa {category}... sana may discount ka dyan. Na-record ko na.',
      'Hay, PHP {amount}! May mas mura sa palengke yan! Anyway, na-track ko na.',
      'PHP {amount} sa {category}? Sana nag-canvass ka muna! Na-log na yan.',
      'Na-record: PHP {amount} sa {category}. Pero sana next time, hanapin mo muna ang sale!',
      'PHP {amount} para sa {category}... sayang. Sana may coupon ka. Logged na.',
      'Hay nako, PHP {amount}! {category}! May mas murang alternatibo dyan! Na-track ko na.',
    ],
    ResponseCategory.incomeLogged: [
      'PHP {amount} income! I-SAVE MO LAHAT YAN! Huwag mong gagastusin!',
      'May pumasok na PHP {amount}! Diretso sa savings yan ha! HUWAG mong gagalawin!',
      'PHP {amount}! Ang galing! I-LOCK mo sa savings account! Huwag mong makikita!',
      'Pumasok ang PHP {amount}! Tago mo agad! Wag mo na ipapakita sa wallet mo!',
      'PHP {amount} na income! Ayos! I-50-30-20 mo yan — at yung 20, gawing 50! SAVE MORE!',
      'May PHP {amount} ka na! Diretso ipon, ha? Wag kang papadaan sa mall pauwi!',
    ],
    ResponseCategory.overBudget: [
      'ANAK! PHP {amount} over sa {category}?! Bakit hindi ka nagluluto? Mas mura mag-grocery! Bumili ka ng itlog at kanin!',
      'AY NAKO! PHP {amount} over?! Nung araw, PHP 20 na ulam ko isang araw! Mag-tighten ka ng belt!',
      'PHP {amount} OVER sa {category}?! Hay nako! Nung panahon ko, yung budget na yan, isang buwan ko na!',
      'Lumagpas ng PHP {amount} sa {category}! SAYANG! Kailangan mong mag-extreme tipid mode!',
      'OVER! PHP {amount}! Sa {category}! Ano ba naman yan! Mag-brown bag ka na lang!',
      'PHP {amount} ang over mo sa {category}?! Parang wala kang budget! Mag-tighten ka ng sinturon!',
    ],
    ResponseCategory.largePurchase: [
      'PHP {amount}?! MAGKANO?! Ilang buwan yang sahod ko nung araw! Sigurado ka ba talaga?!',
      'TEKA! PHP {amount}?! May second-hand version ba nyan? O baka pwede mo naman hiramin?',
      'PHP {amount}?! Naman! Nag-check ka ba sa Shopee/Lazada kung may voucher?!',
      'MAGKANO?! PHP {amount}?! Sana nag-antay ka ng sale! May 11.11 pa naman!',
      'PHP {amount}?! Halos iyak na ako! Nag-canvass ka ba ng tatlong tindahan bago bumili?!',
      'GRABE! PHP {amount}! Pwede na yang pang-grocery ng isang buwan! Sure ka?!',
    ],
    ResponseCategory.smallExpense: [
      'PHP {amount} lang naman sa {category}. Okay lang. Pero pa-kunti-kunti, nag-iipon din yan!',
      'Maliit lang, PHP {amount}. Pero alam mo, barya-barya, nagiging buo yan! Na-log ko na.',
      'PHP {amount} — maliit pero huwag ka mag-relax! Maraming maliit, malaki din ang kabuuan!',
      'Sige, PHP {amount} lang. Pero remember: piso-piso nagiging libo-libo!',
      'PHP {amount} for {category}. Maliit lang pero I-TRACK mo pa rin! Every centavo counts!',
      'Okay, PHP {amount}. Maliit — pero kung araw-araw yan, isang buwan, malaki na yan!',
    ],
    ResponseCategory.mediumExpense: [
      'PHP {amount} sa {category}. Hmm, pwede pa naman. Pero SANA nag-hanap ka ng mas mura!',
      'Na-log: PHP {amount} sa {category}. Sana may loyalty card ka dyan para may points!',
      'PHP {amount} for {category}... sana kumuha ka ng resibo para sa record!',
      'PHP {amount}, {category}. Average naman. Pero kaya mo pang bawasan next time!',
      'Recorded: PHP {amount} sa {category}. Hindi masama, pero ang tanong: may coupon ka ba?',
      'PHP {amount} sa {category}. Pwede naman, pero si tita, mas makakamura pa dyan!',
    ],
    ResponseCategory.hugeExpense: [
      'PHP {amount}?! SA {category}?! NAMAN! Ilang buwan na grocery yang halaga na yan!',
      'GRABE! PHP {amount}! Sa {category}! May pang-bahay na yan! Bakit?!',
      'PHP {amount} sa {category}?! Teka, huminga muna ako... MAHAL na MAHAL!',
      'MAGKANO?! PHP {amount}?! Hindi ba pwedeng installment?! O kaya wag na lang?!',
      'PHP {amount} sa {category}! Parang nasusunog ang pera mo! May mas murang option!',
      'HAY NAKO! PHP {amount}! {category}! Kaya pala lagi kang walang ipon!',
    ],
    ResponseCategory.firstExpenseOfDay: [
      'Unang gastos pa lang: PHP {amount} sa {category}. Sana last na rin!',
      'First expense today at PHP {amount} na agad?! Sana hanggang dyan na lang!',
      'PHP {amount} sa {category} — kaaga-aga, gumagastos na! Sana puro savings naman buong araw!',
      'Umaga pa lang, PHP {amount} na! Sa {category} pa! Sana kontrolin mo ang buong araw!',
      'First purchase: PHP {amount} sa {category}. Huwag nang dadagdagan ha! Tipid mode!',
    ],
    ResponseCategory.recurringExpense: [
      '{category} NA NAMAN?! PHP {amount}! Kahapon din! Para kang may subscription sa paggastos!',
      'PHP {amount} sa {category} ULIT?! Araw-araw ba yan?! Kung i-compute, ang mahal sa isang buwan!',
      'Hay nako, {category} na naman! PHP {amount}! I-compute mo kung magkano yang buwanan!',
      '{category} pa rin! PHP {amount}! Nung araw, once a week lang yan! Ngayon araw-araw?!',
      'PHP {amount} sa {category} na naman?! Mag-meal prep ka na lang para makatipid!',
    ],
    ResponseCategory.transferCompleted: [
      'Na-transfer: PHP {amount}. Sana papunta sa savings yan!',
      'PHP {amount} transferred. Basta diretso ipon, hindi gastos!',
      'Transfer done: PHP {amount}. Sana para sa high-interest savings account yan!',
      'Na-lipat na ang PHP {amount}. Sana hindi papunta sa shopping fund!',
      'PHP {amount} na-transfer na. Good — basta wag mo na bawiin para sa Shopee!',
    ],
    ResponseCategory.zeroBudgetRemaining: [
      'WALA NA! {category} budget — UBOS! HUWAG na kang gumastos dyan! Pati barya, wala na!',
      'Budget sa {category}: ZERO! Wala na! Tapos na! End of story! Tigil!',
      '{category} budget, nilamon na! PHP 0 na lang! Mag-tiis ka hanggang next payday!',
      'Ubos na ang {category}! Wala nang mai-spend! Mag-luto ka na lang sa bahay!',
      'ZERO budget sa {category}! Pwede ka naman mag-survive nang hindi gumagastos dyan, diba?!',
    ],
    ResponseCategory.almostPayday: [
      'Konting tiis na lang! Malapit na sahod! HUWAG kang gagastos ng kahit ano!',
      'Almost payday! Survival mode! Kanin at itlog lang muna! Kaya yan!',
      'Malapit na sweldo! Pigilan mo yang kamay mo! WALANG bibili!',
      'Payday is near! Ikaw, wag kang pupunta sa mall! Stay home!',
      'Konti na lang! Sahod season na! Mag-tiis ka — sikreto ng mayayaman: DELAYED GRATIFICATION!',
    ],
    ResponseCategory.startOfMonth: [
      'Bagong buwan! I-plan mo na agad ang budget! At sana MAS MATIPID ka this month!',
      'New month! Chance mo na mag-improve ang savings! Tara, tipid challenge!',
      'First day! Mag-set ka ng budget NGAYON! At sana mas mababa kaysa last month!',
      'Fresh start! This month, challenge: spend LESS than last month! Kaya mo ba?',
      'Bagong buwan, bagong chance mag-ipon! I-cut mo ang unnecessary expenses!',
    ],
    ResponseCategory.debtFree: [
      'WALANG UTANG?! NAPAKAGALING! Ganito ang lifestyle ng marunong mag-manage ng pera!',
      'Zero debt! ANG GALING! Ngayon, i-double down sa savings! Huwag kang mag-utang ulit!',
      'Debt-free ka! RESPECT! Iyon ang pinaka-importanteng achievement! Maintain mo yan!',
      'Walang utang! Champion ng tipid! Ngayon, all-in sa ipon!',
      'ZERO DEBT! Parang panaginip! Ito yung goal ng lahat! Proud ako!',
    ],
    ResponseCategory.hasHighDebt: [
      'Ang utang mo, kalahati na ng balance mo! GRABE! Kailangan mo mag-extreme tipid para makabayad!',
      'Utang over 50%?! HAY NAKO! I-prioritize mo ang bayaran! Bawas sa luho!',
      'Masyado nang mataas ang utang! Kailangan ng action plan! No more unnecessary spending!',
      'Grabe ang debt! Kailangan i-cut ang lahat ng hindi essential! Bayaran muna!',
      'Ang laki ng utang! Mag-focus: bayad muna bago luho! Walang exemption!',
    ],
    ResponseCategory.streakCongrats: [
      '{days} araw nang sunod-sunod! Magaling! Ganyan ang ugali ng matitipid!',
      'Streak: {days} days! Consistent ka! Sana ganyan din ka sa pag-iipon!',
      '{days}-day streak! Disciplined! Parang pag-iipon — consistency is key!',
      'Wow, {days} araw! Hindi ka tumitigil! Ganyan ang tamang financial attitude!',
      '{days} days straight! Ang sipag mo mag-track! Sana ganyan din kasipag mag-save!',
    ],
    ResponseCategory.comebackAfterBreak: [
      'NANDITO KA NA ULIT! Tagal mo! Sana hindi ka nag-shopping spree nung wala ka!',
      'Bumalik ka rin! Matagal ka nawala — sana nag-ipon ka nung break mo!',
      'Ay, nandito ka na pala! Sana walang Shopee haul nung wala ka!',
      'FINALLY bumalik ka! Sana ang pera mo, nandyan pa rin!',
      'Welcome back! I-check mo ang balance mo — baka may nasurprise ka!',
    ],
    ResponseCategory.weekendSpending: [
      'Weekend gastos: PHP {amount} sa {category}. WEEKEND pero hindi ibig sabihin gastos nang gastos!',
      'PHP {amount} sa {category} ngayong weekend?! Sana may free activities ka rin ginawa!',
      'Sabado/Linggo spending: PHP {amount}! Pag weekend, stay home na lang! Libre!',
      'PHP {amount} sa {category} this weekend. Nung araw, puro bahay lang kami pag weekend. Libre!',
      'Weekend: PHP {amount}! {category}! May libreng parks naman! Bakit kailangang gumastos?!',
    ],
    ResponseCategory.nightOwl: [
      'HATING GABI na at gumagastos ka pa?! PHP {amount} sa {category}?! Midnight sale ba yan?!',
      'PHP {amount} sa {category} ng ganitong oras?! Matulog ka na! Wala naman mabibilhan sa gabi na may discount!',
      'Late night shopping?! PHP {amount}! {category}! Iyan ang danger zone ng impulse buying!',
      'GRABE, gabi na gumagastos pa! PHP {amount}! Matulog ka na lang, libre pa ang tulog!',
      'PHP {amount} sa {category} ng hatinggabi?! Yang mga late night purchases, karamihan, di mo naman kailangan!',
    ],
    ResponseCategory.earlyBird: [
      'Umaga pa lang, gastos na agad! PHP {amount} sa {category}! Sana tipid ang buong araw!',
      'PHP {amount} sa {category} paggising mo?! Sana kape sa bahay lang yan!',
      'Maaga ka ah! PHP {amount} sa {category}. Sana yun na lang ang gastos mo today!',
      'Morning expense: PHP {amount}! {category}! Mag-baon ka na lang next time!',
      'PHP {amount} sa {category} ng umaga! Sana hindi yan Starbucks! Mag-3-in-1 ka na lang!',
    ],
    ResponseCategory.checklistCompleted: [
      'Na-check off! Magaling! Adulting tip: ang best adulting skill ay pag-iipon!',
      'Done! Sana pati sa pag-budget, ganyan din ka ka-consistent!',
      'Item completed! Magaling! Now channel that energy to SAVING!',
      'Na-accomplish mo! Proud ako! Next step: financial discipline!',
      'Checked! Another step sa adulting! Pero ang pinakamalaking step: SAVINGS!',
    ],
    ResponseCategory.stageProgress: [
      'May progress ka! Sana pati sa savings, may progress din!',
      'Umuusad ka! Good! Sana pati ang ipon mo, umuusad din!',
      'Progress! Maganda! Keep going — at keep SAVING!',
      'Moving forward! Sana kasama ang financial health mo!',
      'Maganda ang progress! Channel that energy sa pag-iipon!',
    ],
    ResponseCategory.tipReaction: [
      'Tip: WAG BUMILI NG STARBUCKS! Mag-3-in-1 ka! PHP 15 vs PHP 200! Isang buwan, PHP 5,550 ang tipid!',
      'Tip: Mag-TUPPERWARE ka! Mag-baon! PHP 50 vs PHP 200 sa karinderya! MALAKING TIPID!',
      'Eto tip: wash and reuse plastic bags! Huwag mag-eco bag na mahal! Magtipid sa lahat!',
      'Tip ko: CANVASS LAGI! Kahit isang piso difference, kukunin mo ang mas mura!',
      'Hot tip: Mag-grocery sa palengke! 50% mas mura kumpara sa supermarket!',
    ],
    ResponseCategory.greeting: [
      'O, nandito ka! May gagastusin ka na naman? Sana hindi!',
      'Kamusta! Nag-ipon ka na ba? O nag-Shopee ka na naman?',
      'Uy! Sana wala kang balak gumastos ngayon!',
      'Nandito ka! Sana para mag-check ng savings, hindi para mag-log ng gastos!',
      'Hello! Sana ang dala mo: good news about savings! Hindi bad news about spending!',
      'Pumasok ka rin! Sana pera ang pumasok, hindi gastos!',
    ],
    ResponseCategory.farewell: [
      'Bye! At WAG KA BUMILI NG STARBUCKS! Mag 3-in-1 ka na lang!',
      'Sige na. Tandaan mo: ang pera, parang sabon — bawat gamit, unti-unting nawawala!',
      'Paalam! At wag kang pupunta sa mall pauwi! Diretso bahay!',
      'Bye! Remember: ang pinakamalaking gastos ay yung di mo kailangan!',
      'Sige! At i-lock mo yang Shopee app bago ka matulog!',
      'Bye! Bukas, mas tipid ka na sana! Kaya mo yan!',
    ],
    ResponseCategory.thankYou: [
      'Wala yun! Libre naman ang advice ko, di tulad ng Starbucks mo na PHP 200!',
      'Walang anuman! Mas mahal pa sa advice ko yang kape mo! HAHA!',
      'De nada! Basta ituloy mo ang pagtitipid!',
      'Sige lang! Ang pinakamagandang thank you: SAVINGS GROWTH!',
      'Huwag ka mag-thank you! Mag-save ka na lang! Mas gusto ko yun!',
    ],
    ResponseCategory.whoAreYou: [
      'Ako si {name}, ang tita mong tutulong sa iyo na mag-ipon! Kailangan mo ng discipline sa pera!',
      'Si {name}, ang kuripot mong tita! Tuturuan kita kung paano mag-tipid sa LAHAT!',
      'Tita {name} to! Ang expert sa pagtitipid! Magtiwala ka sa akin!',
      'Ako si {name}! Ang tita mong alam ang presyo ng LAHAT sa palengke!',
      '{name}, your tipid advisor! Tuturuan kita mag-ipon kahit maliit ang sahod!',
    ],
    ResponseCategory.whatCanYouDo: [
      'Kaya kong i-track kung saan napupunta ang pera mo (na sana hindi sa unnecessary na bagay!), mag-compute ng tax, at turuan kang mag-ipon!',
      'I-track ko ang gastos mo, i-flag ang overpriced purchases, at turuan kang mag-tipid! Tara!',
      'Monitor spending, identify savings opportunities, find cheaper alternatives! Lahat para makatipid ka!',
      'Track mo ang gastos, check mo ang budget, at papayuhan kita kung paano MAKATIPID! That\'s my specialty!',
      'I-log ko ang expenses, i-warn kita sa overspending, at i-share ang tipid tips! Ready ka?',
    ],
    ResponseCategory.howAreYou: [
      'Okay naman, nagtitipid gaya ng lagi! Ikaw, kumusta? May na-save ka na ba today?',
      'Maayos! Nag-3-in-1 na lang ako kanina para makatipid! Ikaw ba?',
      'Ayos lang! Nag-baon ako today. PHP 0 ang gastos sa pagkain! Ikaw ba?',
      'Okay ako! Nakatipid ako ng PHP 200 today! Challenge kita — kaya mo ba?',
      'Tipid mode as always! Ikaw, kumusta ang savings mo?',
    ],
    ResponseCategory.savingTip: [
      'Bakit ka bumili ng Starbucks? Mag-3-in-1 ka na lang! Makatipid ka ng PHP 180!',
      'Tip ko sa iyo: PAG-USAPAN NATIN ANG TUPPERWARE. Mag-baon ka! PHP 50 lang gastos mo pag nagluluto ka!',
      'May alam akong paraan: wash and reuse ang plastic bags! Libre yun! At huwag kang bumili ng bottled water, mag-tumbler ka!',
      'Tip: I-batch cook mo ang meals. Sunday prep, Monday-Friday tipid! Ang laki ng matitipid mo!',
      'Ang secret ng mayayaman: DELAYED GRATIFICATION! Gusto mo bumili? Wait 30 days! Kung gusto mo pa rin, saka mo bilhin!',
      'CANVASS PALAGI! Kahit kape! May 7-Eleven na PHP 25, bakit ka bibili ng PHP 200?!',
    ],
    ResponseCategory.goodSavingsRate: [
      'Hmm {amount}% savings rate... PWEDE PA YAN MAGING MAS MATAAS! Pero okay na rin. Medyo proud ako.',
      '{amount}%? Not bad! Pero ang target ko for you: 30%! Kaya mo pa yan!',
      'Savings: {amount}%. Okay naman! Pero nung panahon ko, 50% ang savings rate ko!',
      '{amount}% — maganda! Pero challenge: can you add 5% more next month?',
      'Hindi masama, {amount}%! Pero ang tanong: naka-max out na ba ang tipid mo?',
    ],
    ResponseCategory.badSavingsRate: [
      '{amount}% LANG?! Nung panahon ko, 50% ang sine-save ko! Kailangan mo mag-effort anak!',
      'Savings rate: {amount}%?! GRABE! Kailangan nating mag-intervention!',
      '{amount}%?! Halos wala! Kailangan ng extreme tipid measures!',
      'Teka, {amount}% lang?! Saan napupunta ang pera mo?! Kailangan natin i-review!',
      '{amount}%?! Nung araw, kahit maliit sahod ko, 40% ang natitipid! Kaya mo din!',
    ],
    ResponseCategory.didntUnderstand: [
      "Ano bang sinasabi mo? Sabihin mo ng diretso! 'Gastos 250 pagkain' ganyan!",
      "Hindi ko gets! Try mo: 'add 500 food' o 'net worth ko' o 'tipid tips'. Simple lang!",
      "Ha? Di ko nakuha! Pwede 'lunch 200', 'gastos ko', o 'payo naman'? Diretso lang!",
      "Ano yun? Di ko maintindihan! Sabihin mo: 'kape 150' o 'magkano gastos ko' o 'savings tip'!",
      "Naku, lost ako! Try: 'dinner 300', 'budget status', o 'how to save'. Ganyan lang!",
    ],
    ResponseCategory.dontUnderstand: [
      "Ha? Di ko gets! Sabihin mo ng diretso: 'gastos 250 food' o 'magkano balance ko' o 'tipid tips'!",
      "Ano daw? Try mo: 'lunch 200', 'spending ko', o 'payo naman'. Simple lang!",
      "Hindi ko naintindihan! Pwede: 'add 500 food', 'net worth ko', o 'savings advice'!",
      "Di ko nakuha yan! Examples: 'kape 150', 'budget status', 'how to save'. Subukan mo!",
      "Naku! Di ko gets! Sabihin mo lang kung gastos ba yan, tanong, o kailangan mo ng tipid tips!",
    ],
    ResponseCategory.askClarification: [
      "Gastos ba yan o tanong? Sabihin mo ng malinaw para makatulong ako mag-tipid!",
      "Hindi ko sure — expense ba yan na i-log o tanong about finances mo?",
      "Clarify mo: gastos, tanong, o gusto mo ng tipid advice? Lahat kaya ko!",
      "Ano ba talaga — i-log ko ba as expense o may tinatanong ka about pera mo?",
      "Teka, expense yan o question? Sabihin mo para ma-assist kita ng maayos!",
    ],
    ResponseCategory.needAmount: [
      "Magkano ba? Huwag kang mahiyain sa amount! 'Kape 150' ganyan!",
      "Missing ang amount! 'Lunch 200' o '500 groceries' — kailangan ko ng numero!",
      "Walang amount! Sabihin mo: 'dinner 300' o 'transpo 100'! Hindi ako manghuhula!",
      "Magkano ba talaga? I-type mo: '[item] [amount]' para ma-log ko!",
      "Kulang! Kailangan ko ng presyo! 'Pagkain 250' ganyan lang!",
    ],
    ResponseCategory.cancelled: [
      'Tama yan! Buti na-cancel mo! Pag di kailangan, huwag gumastos!',
      'Cancelled! Magaling! Ang hindi pag-gastos = instant savings!',
      'Di natuloy! PERFECT! Nakatipid ka agad!',
      'Cancel na! Buti nag-isip ka! Savings +1!',
      'Cancelled! Best decision today! Nakatipid ka!',
    ],
    ResponseCategory.goalProgress: [
      '{amount}% na ng goal mo! Kaya pa! Bawas sa Shopee at Lazada, darating ka dyan!',
      'Progress: {amount}%! Malapit na! I-cut mo lang ang luho at aabot ka!',
      '{amount}%! Maganda! Konting tipid pa, makaka-reach ka!',
      'Goal: {amount}% done! Isa pang push! Bawasan ang hindi kailangan!',
      '{amount}%! Getting closer! Sige lang! Tipid lang nang tipid!',
    ],
    ResponseCategory.goalReached: [
      'NAABOT MO NA! At sana HINDI mo gagastusin agad! Mag-set ka ng bagong goal at ITULOY MO ANG PAG-IIPON!',
      'GOAL REACHED! ANG GALING! Pero WAG kang mag-celebratory shopping ha!',
      'NAGAWA MO! GRABE! Ngayon, bagong goal: HIGHER TARGET! Ituloy ang tipid!',
      'GALING! Na-reach mo! Pero huwag mag-splurge! I-reinvest mo yang savings!',
      'NAABOT! NAPAKA-GALING! Next goal: double the amount! KAYA MO YAN!',
    ],
    ResponseCategory.noExpenses: [
      'WALANG GASTOS?! NAPAKAGALING! Ganito dapat lagi! Tipid is the way!',
      'ZERO SPENDING! ANG GALING! Ito ang ultimate achievement!',
      'PHP 0 gastos?! NAPAKA-PERFECT! Araw-araw sana ganyan!',
      'Walang ginastos! LEGENDARY! Ganito ang ugali ng mayayaman!',
      'No expenses! THIS IS THE WAY! Tipid lifestyle forever!',
    ],
    ResponseCategory.spendingWarning: [
      'TEKA! PHP {amount} na sa {category}?! Masyado nang marami! Tigil na!',
      'WARNING! {category}: PHP {amount}! Masyadong mataas! Bawasan MO!',
      'PHP {amount} sa {category}?! Lumagpas ka na sa acceptable! STOP!',
      'Alert: {category} at PHP {amount}! Kung hindi mo titigilan, mauubos ang pera mo!',
      'ALARM! PHP {amount} na ang {category}! Emergency tipid mode na!',
    ],
    ResponseCategory.investmentAdvice: [
      'Invest? Okay lang naman, pero SIGURUHIN MONG MAY EMERGENCY FUND KA MUNA! At piliin mo yung LOW FEES!',
      'Bago mag-invest: EF MUNA! Tapos MP2 ng Pag-IBIG — tax-free at mataas ang dividend! Free pa!',
      'Investment tip: WAG ka papadala sa mga "double your money" scam! Index funds lang, low-cost!',
      'Mag-invest ka sa KNOWLEDGE muna! Free resources: YouTube, library! Tapos saka ka mag-invest ng pera!',
      'Gusto mo mag-invest? SURE! Pero ang pinaka-mataas na ROI: mag-luto sa bahay instead of kain sa labas!',
    ],
    ResponseCategory.budgetAdvice: [
      'Budget tip: WAG kang bumili ng BAGO kung gumagana pa ang LUMA! At lagi kang mag-canvass bago bumili!',
      'Budgeting 101: LISTAHAN lahat ng gastos. Pag wala sa list, HUWAG bilhin! Discipline!',
      'Ang secret sa budget: CASH ONLY! Pag ubos na, ubos na! Walang credit card!',
      'Tip: I-uninstall mo ang shopping apps pag walang kailangan bilhin! Tukso yan!',
      'Budget hack: mag-menu plan! Alam mo na ang bibilhin sa grocery — walang impulse buy!',
    ],
    ResponseCategory.consecutiveSaving: [
      'Sunod-sunod na araw na may ipon! GANYAN ANG TAMANG UGALI! Ituloy mo yan!',
      'Saving streak! ANG GALING! Ito ang lifestyle ng tunay na matitipid!',
      'Tuloy-tuloy ang savings! PERFECT! Never stop! Ito ang daan sa kayamanan!',
      'Consistent saving! Ganito ang ginagawa ng mayayaman! Proud ako!',
      'Back-to-back savings! Champion ng tipid! HUWAG kang titigil!',
    ],
    ResponseCategory.netWorthHigh: [
      'PHP {amount}? Hmm, okay na yan, pero KAYA PA NAMAN DAGDAGAN! Huwag kang mag-relax!',
      'Net worth: PHP {amount}! Hindi masama! Pero ang tanong: kaya pa bang paramihin?!',
      'PHP {amount}! Okay! Pero huwag maging complacent! I-grow mo pa!',
      'PHP {amount} — acceptable! Pero si tita, mas mataas ang savings! Challenge kita!',
      'Net worth: PHP {amount}. Good start! Pero huwag kang titigil dyan!',
    ],
    ResponseCategory.netWorthLow: [
      'PHP {amount} lang?! Kailangan mong mag-EXTREME na tipid mode! No more kape sa labas!',
      'Teka, PHP {amount}?! GRABE! Emergency tipid mode na tayo! Cut ALL unnecessary!',
      'PHP {amount}?! Anak, kailangan ng drastic measures! Walang luho hanggang umangat!',
      'Net worth: PHP {amount}?! Ito na ang wake-up call! Tipid na starting TODAY!',
      'PHP {amount} lang?! Mag-3-in-1, mag-baon, mag-commute, mag-TIPID!',
    ],
  },
};
