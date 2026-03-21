/// Chat AI dictionary — keyword maps, verb maps, compound patterns,
/// filler words, brand filters, and all static lookup data for the
/// chat engine's NLP parsing pipeline.

// ═══════════════════════════════════════════════════════════════════════
// CATEGORY DICTIONARY — keyword -> transaction category
// ═══════════════════════════════════════════════════════════════════════

const Map<String, String> kCategoryDictionary = {
  // ─── Food ──────────────────────────────────────────────────────────
  // Meals
  'lunch': 'Food', 'dinner': 'Food', 'breakfast': 'Food',
  'snack': 'Food', 'merienda': 'Food', 'tanghalian': 'Food',
  'hapunan': 'Food', 'almusal': 'Food', 'kain': 'Food',
  'ulam': 'Food', 'baon': 'Food', 'pulutan': 'Food',
  'brunch': 'Food', 'tusok': 'Food', 'street food': 'Food',
  'pagkain': 'Food', 'agahan': 'Food',

  // Fast food / chains
  'jollibee': 'Food', 'mcdo': 'Food', 'mcdonalds': 'Food',
  'kfc': 'Food', 'chowking': 'Food', 'greenwich': 'Food',
  'mang inasal': 'Food', 'bonchon': 'Food', 'army navy': 'Food',
  'ministop': 'Food', 'familymart': 'Food',
  'starbucks': 'Food', 'tim hortons': 'Food', 'dunkin': 'Food',
  'potato corner': 'Food', 'turks': 'Food', 'sbarro': 'Food',
  'yellowcab': 'Food', 'angels pizza': 'Food',
  'burger king': 'Food', 'wendys': 'Food', 'subway': 'Food',
  'pizza hut': 'Food', 'shakeys': 'Food', 'kenny rogers': 'Food',
  'max': 'Food', 'pancake house': 'Food', 'dencio': 'Food',
  'goldilocks': 'Food', 'red ribbon': 'Food', 'mary grace': 'Food',
  'mesa': 'Food', 'vikings': 'Food', 'sambo kojin': 'Food',
  'yabu': 'Food', 'ramen nagi': 'Food', 'coco ichibanya': 'Food',
  'yoshinoya': 'Food', 'pepper lunch': 'Food', 'ippudo': 'Food',
  'genki sushi': 'Food', 'botejyu': 'Food',

  // Filipino food
  'sisig': 'Food', 'adobo': 'Food', 'sinigang': 'Food',
  'lechon': 'Food', 'bulalo': 'Food', 'kare kare': 'Food',
  'pancit': 'Food', 'lumpia': 'Food', 'halo halo': 'Food',
  'isaw': 'Food', 'kwek kwek': 'Food', 'fishball': 'Food',
  'balut': 'Food', 'taho': 'Food', 'turon': 'Food',
  'bibingka': 'Food', 'puto': 'Food', 'kakanin': 'Food',
  'tokwa': 'Food', 'tinola': 'Food', 'caldereta': 'Food',
  'menudo': 'Food', 'afritada': 'Food', 'bistek': 'Food',
  'tapsilog': 'Food', 'longsilog': 'Food', 'tosilog': 'Food',
  'silog': 'Food', 'lugaw': 'Food', 'goto': 'Food',
  'arroz caldo': 'Food', 'palabok': 'Food',

  // International food
  'samgyupsal': 'Food', 'samgyup': 'Food', 'ramen': 'Food',
  'sushi': 'Food', 'sashimi': 'Food', 'tempura': 'Food',
  'katsu': 'Food', 'teriyaki': 'Food', 'gyoza': 'Food',
  'dimsum': 'Food', 'dumpling': 'Food', 'noodles': 'Food',
  'pasta': 'Food', 'pizza': 'Food', 'burger': 'Food',
  'steak': 'Food', 'wings': 'Food', 'fries': 'Food',
  'shawarma': 'Food', 'kebab': 'Food', 'curry': 'Food',
  'pho': 'Food', 'pad thai': 'Food', 'bibimbap': 'Food',
  'bento': 'Food', 'taco': 'Food', 'burrito': 'Food',

  // Drinks
  'coffee': 'Food', 'kape': 'Food', 'beer': 'Food',
  'inumin': 'Food', 'juice': 'Food', 'water': 'Food',
  'tubig': 'Food', 'milk tea': 'Food', 'milktea': 'Food',
  'boba': 'Food', 'frappe': 'Food', 'smoothie': 'Food',
  'soda': 'Food', 'softdrinks': 'Food', 'tea': 'Food',
  'wine': 'Food', 'cocktail': 'Food', 'alak': 'Food',

  // Grocery / market
  'grocery': 'Food', 'palengke': 'Food', 'wet market': 'Food',
  'puregold': 'Food', 'sm supermarket': 'Food',
  'robinsons supermarket': 'Food', 'landers': 'Food',
  'snr': 'Food', 'metro market': 'Food', 'savemore': 'Food',
  'waltermart': 'Food', 'ever gotesco': 'Food',
  'rice': 'Food', 'bigas': 'Food', 'gulay': 'Food',
  'karne': 'Food', 'isda': 'Food', 'prutas': 'Food',

  // Delivery
  'foodpanda': 'Food', 'food panda': 'Food',

  // ─── Transportation ────────────────────────────────────────────────
  'grab': 'Transportation', 'angkas': 'Transportation',
  'jeep': 'Transportation', 'jeepney': 'Transportation',
  'tricycle': 'Transportation', 'trike': 'Transportation',
  'mrt': 'Transportation', 'lrt': 'Transportation',
  'bus': 'Transportation', 'taxi': 'Transportation',
  'fare': 'Transportation', 'pamasahe': 'Transportation',
  'gas': 'Transportation', 'diesel': 'Transportation',
  'gasolina': 'Transportation', 'fuel': 'Transportation',
  'parking': 'Transportation', 'toll': 'Transportation',
  'autosweep': 'Transportation', 'easytrip': 'Transportation',
  'beep': 'Transportation', 'uber': 'Transportation',
  'indriver': 'Transportation', 'joyride': 'Transportation',
  'lalamove': 'Transportation', 'ferry': 'Transportation',
  'transpo': 'Transportation', 'commute': 'Transportation',
  'habal': 'Transportation', 'pedicab': 'Transportation',
  'van': 'Transportation', 'uv express': 'Transportation',
  'p2p': 'Transportation', 'carpool': 'Transportation',
  'oil change': 'Transportation', 'tire': 'Transportation',
  'car wash': 'Transportation', 'registration': 'Transportation',
  'lto': 'Transportation', 'emission': 'Transportation',

  // ─── Housing ───────────────────────────────────────────────────────
  'rent': 'Housing', 'upa': 'Housing', 'condo': 'Housing',
  'dorm': 'Housing', 'apartment': 'Housing',
  'association dues': 'Housing', 'hoa': 'Housing',
  'repair': 'Housing', 'ayos': 'Housing',
  'furniture': 'Housing', 'appliance': 'Housing',
  'meralco': 'Housing', 'maynilad': 'Housing',
  'manila water': 'Housing', 'pldt': 'Housing',
  'globe': 'Housing', 'smart': 'Housing',
  'converge': 'Housing', 'wifi': 'Housing',
  'internet': 'Housing', 'kuryente': 'Housing',
  'tubig bill': 'Housing', 'load': 'Housing',
  'prepaid': 'Housing', 'postpaid': 'Housing',
  'electric bill': 'Housing', 'water bill': 'Housing',
  'phone bill': 'Housing', 'cable': 'Housing',
  'cleaning': 'Housing', 'laundry': 'Housing',
  'laba': 'Housing', 'mortgage': 'Housing',
  'amortization': 'Housing',

  // ─── Entertainment ─────────────────────────────────────────────────
  'movie': 'Entertainment', 'sine': 'Entertainment',
  'netflix': 'Entertainment', 'spotify': 'Entertainment',
  'youtube': 'Entertainment', 'gaming': 'Entertainment',
  'steam': 'Entertainment', 'ps5': 'Entertainment',
  'ps4': 'Entertainment', 'xbox': 'Entertainment',
  'nintendo': 'Entertainment', 'switch': 'Entertainment',
  'gig': 'Entertainment', 'concert': 'Entertainment',
  'party': 'Entertainment', 'videoke': 'Entertainment',
  'karaoke': 'Entertainment', 'gym': 'Entertainment',
  'lakad': 'Entertainment', 'gala': 'Entertainment',
  'outing': 'Entertainment', 'beach': 'Entertainment',
  'inuman': 'Entertainment', 'bar': 'Entertainment',
  'club': 'Entertainment', 'date': 'Entertainment',
  'travel': 'Entertainment', 'hotel': 'Entertainment',
  'airbnb': 'Entertainment', 'booking': 'Entertainment',
  'resort': 'Entertainment', 'swimming': 'Entertainment',
  'pool': 'Entertainment', 'spa': 'Entertainment',
  'massage': 'Entertainment', 'hilot': 'Entertainment',
  'salon': 'Entertainment', 'haircut': 'Entertainment',
  'gupit': 'Entertainment', 'barber': 'Entertainment',
  'hobby': 'Entertainment', 'subscription': 'Entertainment',
  'disney': 'Entertainment', 'hbo': 'Entertainment',
  'apple music': 'Entertainment', 'viu': 'Entertainment',

  // ─── Healthcare ────────────────────────────────────────────────────
  'doctor': 'Healthcare', 'dentist': 'Healthcare',
  'checkup': 'Healthcare', 'hospital': 'Healthcare',
  'clinic': 'Healthcare', 'medicine': 'Healthcare',
  'gamot': 'Healthcare', 'pharmacy': 'Healthcare',
  'mercury drug': 'Healthcare', 'watsons': 'Healthcare',
  'southstar': 'Healthcare', 'lab': 'Healthcare',
  'xray': 'Healthcare', 'vitamins': 'Healthcare',
  'glasses': 'Healthcare', 'salamin': 'Healthcare',
  'consultation': 'Healthcare', 'therapy': 'Healthcare',
  'mental health': 'Healthcare', 'derma': 'Healthcare',
  'ob gyne': 'Healthcare', 'pediatrician': 'Healthcare',
  'vaccine': 'Healthcare', 'bakuna': 'Healthcare',
  'surgery': 'Healthcare', 'dental': 'Healthcare',
  'braces': 'Healthcare', 'eye check': 'Healthcare',
  'endo': 'Healthcare',

  // ─── Education ─────────────────────────────────────────────────────
  'tuition': 'Education', 'school': 'Education',
  'books': 'Education', 'aral': 'Education',
  'review': 'Education', 'tutorial': 'Education',
  'course': 'Education', 'seminar': 'Education',
  'training': 'Education', 'udemy': 'Education',
  'school supplies': 'Education', 'thesis': 'Education',
  'grad': 'Education', 'graduation': 'Education',
  'enrollment': 'Education', 'miscellaneous fee': 'Education',
  'uniform': 'Education', 'modules': 'Education',
  'coursera': 'Education', 'skillshare': 'Education',

  // ─── Family Support ────────────────────────────────────────────────
  'padala': 'Family Support', 'remittance': 'Family Support',
  'mama': 'Family Support', 'papa': 'Family Support',
  'nanay': 'Family Support', 'tatay': 'Family Support',
  'parents': 'Family Support', 'magulang': 'Family Support',
  'allowance': 'Family Support', 'sustento': 'Family Support',
  'kapatid': 'Family Support', 'lola': 'Family Support',
  'lolo': 'Family Support', 'anak': 'Family Support',
  'pamilya': 'Family Support', 'family': 'Family Support',
  'tita': 'Family Support', 'tito': 'Family Support',
  'ninong': 'Family Support', 'ninang': 'Family Support',
  'inaanak': 'Family Support', 'abuloy': 'Family Support',
  'regalo': 'Family Support', 'gift': 'Family Support',

  // ─── Other / Shopping ──────────────────────────────────────────────
  'shopee': 'Other', 'lazada': 'Other',
  'uniqlo': 'Other', 'sm': 'Other',
  'robinsons': 'Other', 'ayala': 'Other',
  'mall': 'Other', 'shopping': 'Other',
  'bili': 'Other', 'bought': 'Other',
  'purchase': 'Other', 'amazon': 'Other',
  'tiktok shop': 'Other', 'zalora': 'Other',
  'clothes': 'Other', 'damit': 'Other',
  'shoes': 'Other', 'sapatos': 'Other',
  'bag': 'Other', 'gadget': 'Other',
  'phone': 'Other', 'laptop': 'Other',
  'computer': 'Other', 'accessories': 'Other',
  'pet': 'Other', 'vet': 'Other',
  'dog': 'Other', 'cat': 'Other',
  'donation': 'Other', 'charity': 'Other',
  'tithe': 'Other', 'church': 'Other',
  'simbahan': 'Other',
};

// ═══════════════════════════════════════════════════════════════════════
// COMPOUND PATTERNS — multi-word phrases checked BEFORE individual keywords.
// Ordered by length descending (longest match wins).
// ═══════════════════════════════════════════════════════════════════════

const List<(String pattern, String category)> kCompoundPatterns = [
  // Food delivery (overrides transport brand)
  ('grab food', 'Food'),
  ('grab delivery', 'Food'),
  ('food delivery', 'Food'),
  ('food panda', 'Food'),
  ('foodpanda', 'Food'),
  ('pick up food', 'Food'),
  ('dine in', 'Food'),
  ('take out', 'Food'),
  ('drive thru', 'Food'),
  ('drive through', 'Food'),
  ('milk tea', 'Food'),
  ('street food', 'Food'),

  // Transport
  ('gas station', 'Transportation'),
  ('road trip', 'Transportation'),
  ('car wash', 'Transportation'),
  ('oil change', 'Transportation'),
  ('uv express', 'Transportation'),
  ('school bus', 'Transportation'),

  // Housing / bills
  ('electric bill', 'Housing'),
  ('water bill', 'Housing'),
  ('phone bill', 'Housing'),
  ('internet bill', 'Housing'),
  ('house rent', 'Housing'),
  ('condo dues', 'Housing'),
  ('association dues', 'Housing'),
  ('manila water', 'Housing'),

  // Education
  ('school supplies', 'Education'),
  ('school fees', 'Education'),
  ('miscellaneous fee', 'Education'),

  // Healthcare
  ('health insurance', 'Healthcare'),
  ('life insurance', 'Healthcare'),
  ('mental health', 'Healthcare'),
  ('ob gyne', 'Healthcare'),
  ('eye check', 'Healthcare'),
  ('mercury drug', 'Healthcare'),

  // Entertainment
  ('gym membership', 'Entertainment'),
  ('apple music', 'Entertainment'),
  ('tiktok shop', 'Other'),

  // Family
  ('family support', 'Family Support'),
];

// ═══════════════════════════════════════════════════════════════════════
// FILIPINO VERB MAP — conjugated verbs -> category
// ═══════════════════════════════════════════════════════════════════════

const Map<String, String> kVerbCategories = {
  // Food
  'kinain': 'Food', 'kumain': 'Food', 'kakain': 'Food',
  'inorder': 'Food', 'ininom': 'Food', 'uminom': 'Food',
  'naglunch': 'Food', 'nagdinner': 'Food', 'nagbreakfast': 'Food',
  'nagmerienda': 'Food', 'nagsnack': 'Food', 'nagluto': 'Food',
  'naorder': 'Food', 'umorder': 'Food',

  // Transport
  'niride': 'Transportation', 'sumakay': 'Transportation',
  'sinakyan': 'Transportation', 'nagcommute': 'Transportation',
  'nagdrive': 'Transportation', 'nagpark': 'Transportation',
  'nasakay': 'Transportation',

  // Shopping / generic
  'binili': 'Other', 'bumili': 'Other', 'bibili': 'Other',
  'shinopee': 'Other', 'shinoppee': 'Other',

  // Payment (likely bill)
  'binayaran': 'Housing', 'nagbayad': 'Housing', 'binayad': 'Housing',

  // Family
  'pinadala': 'Family Support', 'ibinigay': 'Family Support',
  'pinadalhan': 'Family Support', 'nagpadala': 'Family Support',

  // Withdraw / transfer
  'nagwithdraw': 'Other', 'nagtransfer': 'Other',
  'nagcashin': 'Other', 'nagcashout': 'Other',
};

// ═══════════════════════════════════════════════════════════════════════
// INCOME KEYWORDS
// ═══════════════════════════════════════════════════════════════════════

const Set<String> kIncomeKeywords = {
  'salary', 'sweldo', 'sahod', 'suweldo',
  'freelance', 'commission', 'overtime', 'ot pay',
  '13th month', '13th month pay', 'thirteenth month',
  'refund', 'cashback', 'rebate', 'cash back',
  'prize', 'panalo', 'jackpot',
  'income', 'kita',
  'dividend', 'interest income',
  'rental income',
  'raket', 'sideline', 'side hustle',
  'benta', 'sale', 'sold',
  'tip', 'tips', 'pabuya',
  'natanggap', 'tinanggap', 'received',
  'may pumasok', 'pumasok',
};

const Set<String> kAmbiguousIncomeKeywords = {
  'bonus', 'investment', 'return',
};

// ═══════════════════════════════════════════════════════════════════════
// FILLER / NOISE WORDS — stripped before processing
// ═══════════════════════════════════════════════════════════════════════

const Set<String> kFillerWords = {
  'lang', 'lng', 'naman', 'po', 'mga', 'yung', 'yun',
  'nung', 'din', 'rin', 'daw', 'raw', 'pala', 'na',
  'worth', 'around', 'about', 'just', 'only',
  'for', 'the', 'a', 'an', 'my', 'i',
  'ako', 'ko', 'nag', 'ng',
};

// ═══════════════════════════════════════════════════════════════════════
// QUERY DETECTION
// ═══════════════════════════════════════════════════════════════════════

const Set<String> kQueryWords = {
  // English
  'what', 'how', 'when', 'where', 'show', 'list',
  'total', 'spent', 'spending', 'balance',
  'net worth', 'networth',
  'budget', 'goal', 'goals', 'debt', 'debts', 'bills',
  'summary', 'report', 'status',
  'recent', 'history', 'last',
  'remaining', 'left', 'available',
  'compare', 'versus', 'vs',

  // Filipino
  'magkano', 'ilan', 'gaano', 'ano', 'nasaan', 'saan', 'kailan',
  'paki', 'pakita', 'ipakita',
  'gastos', 'ginastos', 'nagastos',
  'kita', 'kinita',
  'utang', 'natitirang', 'natitira',
  'bayarin',
  'pinaka', 'pinakamalaki', 'pinakamaliit',
  'saan napupunta', 'napupunta',
};

/// Words that force QUERY intent even when an amount is present.
const Set<String> kQuestionParticles = {
  'ba', 'diba', 'noh', 'no', 'di ba',
};

// ═══════════════════════════════════════════════════════════════════════
// SPECIAL MODIFIERS
// ═══════════════════════════════════════════════════════════════════════

const Set<String> kNegationPrefixes = {
  'hindi', 'di', 'wala', 'walang', 'huwag', 'wag',
};

const Set<String> kTransferWords = {
  'to', 'sa', 'from', 'galing', 'papunta', 'mula',
};

const Set<String> kHelpTriggers = {
  'help', 'tulong', 'commands', 'what can you do',
  'ano magagawa mo', 'paano', 'how to use',
  'ano kaya mo',
};

const Set<String> kFamilyWords = {
  'mama', 'papa', 'nanay', 'tatay', 'parents', 'magulang',
  'kapatid', 'lola', 'lolo', 'anak', 'pamilya', 'family',
  'tita', 'tito', 'ninong', 'ninang', 'inaanak', 'asawa',
};

// ═══════════════════════════════════════════════════════════════════════
// GREETING / SMALL TALK DETECTION
// ═══════════════════════════════════════════════════════════════════════

const Set<String> kGreetingWords = {
  'hello', 'hi', 'hey', 'kumusta', 'kamusta', 'uy', 'oi',
  'good morning', 'good afternoon', 'good evening',
  'magandang umaga', 'magandang hapon', 'magandang gabi',
  'musta', 'sup', 'yo',
};

const Set<String> kFarewellWords = {
  'bye', 'goodbye', 'paalam', 'sige', 'see you', 'see ya',
  'later', 'salamat bye', 'bye bye',
};

const Set<String> kThankYouWords = {
  'thank you', 'thanks', 'salamat', 'maraming salamat',
  'thank u', 'ty', 'tnx', 'thankyou',
};

const Set<String> kWhoAreYouWords = {
  'who are you', 'sino ka', 'sino ka ba', 'anong pangalan mo',
  'what is your name', 'what\'s your name',
};

const Set<String> kWhatCanYouDoWords = {
  'what can you do', 'ano kaya mo', 'ano magagawa mo',
  'what are your features', 'capabilities',
};

const Set<String> kHowAreYouWords = {
  'how are you', 'kamusta ka', 'kumusta ka', 'musta ka',
  'how r u', 'how are u',
};

// ═══════════════════════════════════════════════════════════════════════
// FINANCIAL ADVICE TRIGGERS
// ═══════════════════════════════════════════════════════════════════════

const Set<String> kAdviceTriggers = {
  'give me a tip', 'tip naman', 'payo', 'payo naman',
  'any advice', 'advice', 'suggestion', 'suggest',
  'paano mag-ipon', 'paano mag ipon', 'how to save',
  'how to save more', 'save more', 'mag-ipon',
  'should i invest', 'mag-invest', 'mag invest',
  'invest ba ako', 'investing',
  'compound interest', 'ano compound interest',
  'explain sss', 'sss pension', 'paano pension',
};

// ═══════════════════════════════════════════════════════════════════════
// CONTRIBUTION / TAX QUERY TRIGGERS
// ═══════════════════════════════════════════════════════════════════════

const Set<String> kContributionTriggers = {
  'sss', 'philhealth', 'pag-ibig', 'pagibig', 'hdmf',
  'contributions', 'contribution', 'mga contribution',
  'compute tax', 'compute my tax', 'tax ko',
  '13th month', '13th month pay', 'magkano 13th month',
};

// ═══════════════════════════════════════════════════════════════════════
// APP NAVIGATION TRIGGERS
// ═══════════════════════════════════════════════════════════════════════

const Map<String, String> kNavigationTriggers = {
  'open dashboard': '/dashboard',
  'go to dashboard': '/dashboard',
  'dashboard': '/dashboard',
  'show transactions': '/transactions',
  'transactions': '/transactions',
  'transactions ko': '/transactions',
  'open settings': '/settings',
  'settings': '/settings',
  'open accounts': '/accounts',
  'accounts': '/accounts',
  'mga account ko': '/accounts',
  'scan receipt': '/scan',
  'scan resibo': '/scan',
  'open budgets': '/budgets',
  'budgets': '/budgets',
  'budget ko': '/budgets',
  'open goals': '/goals',
  'goals': '/goals',
  'open bills': '/bills',
  'bills ko': '/bills',
  'open debts': '/debts',
  'debts ko': '/debts',
  'utang ko': '/debts',
};

// ═══════════════════════════════════════════════════════════════════════
// TRANSACTION VERB PATTERNS — expanded
// ═══════════════════════════════════════════════════════════════════════

/// Words that signal an explicit add-expense action.
const Set<String> kExpenseActionWords = {
  'add', 'spent', 'gastos', 'bayad', 'paid',
  'bought', 'bumili', 'binili', 'purchased',
  'nagbayad', 'binayaran', 'nagastos',
  'add expense', 'log expense',
};

/// Words that signal an explicit add-income action.
const Set<String> kIncomeActionWords = {
  'add income', 'log income', 'received',
  'sahod', 'sweldo', 'salary',
  'may pumasok', 'pumasok',
  'natanggap', 'tinanggap',
};

/// Words that signal a transfer action.
const Set<String> kTransferActionWords = {
  'transfer', 'transferred', 'nagtransfer',
  'withdraw', 'withdrew', 'nagwithdraw', 'nag-withdraw',
  'cash in', 'cashin', 'nagcashin', 'nag-cash-in',
  'cash out', 'cashout', 'nagcashout', 'nag-cash-out',
  'padala', 'send money', 'nagpadala',
};

// ═══════════════════════════════════════════════════════════════════════
// CONFIRMATION STATE WORDS
// ═══════════════════════════════════════════════════════════════════════

const Set<String> kAffirmativeWords = {
  'yes', 'oo', 'sige', 'go', 'ok', 'okay', 'y', 'opo',
  'sure', 'confirm', 'aye', 'yep', 'yup', 'ge', 'g',
};

const Set<String> kNegativeWords = {
  'no', 'hindi', 'cancel', 'huwag', 'wag', 'n', 'nope',
  'ayaw', 'ayoko', 'hinde', 'pass', 'skip',
};

// ═══════════════════════════════════════════════════════════════════════
// AMOUNT PARSING HELPERS
// ═══════════════════════════════════════════════════════════════════════

/// Numeric brand names — excluded from amount scanning.
const Set<String> kBrandFilter = {
  '7eleven', '7-eleven', '711', '7-11',
  '2go', '24chicken', '8cuts',
  'b1t1', 'b2t1', 's&r', 'snr',
  '360', '3m', '555',
};

/// Quantity marker words — number adjacent to these is NOT the amount.
const Set<String> kQuantityMarkers = {
  'pax', 'pcs', 'pieces', 'piraso', 'x',
  'rides', 'trips', 'months', 'days', 'hours',
  'tickets', 'tix', 'cups', 'serving', 'servings',
  'items', 'bottles', 'cans', 'boxes', 'packs',
  'kilos', 'kg', 'grams', 'liters',
};

/// Month names for date-adjacency filtering.
const Set<String> kMonthNames = {
  // English
  'january', 'jan', 'february', 'feb', 'march', 'mar',
  'april', 'apr', 'may', 'june', 'jun',
  'july', 'jul', 'august', 'aug', 'september', 'sep', 'sept',
  'october', 'oct', 'november', 'nov', 'december', 'dec',
  // Filipino
  'enero', 'pebrero', 'marso', 'abril', 'mayo', 'hunyo',
  'hulyo', 'agosto', 'setyembre', 'oktubre', 'nobyembre', 'disyembre',
};

/// Promo/sale patterns — numbers within these are NOT amounts.
final List<RegExp> kPromoPatterns = [
  RegExp(r'\b\d{1,2}\.\d{1,2}\b'), // 11.11, 12.12, 9.9
  RegExp(r'\bbuy\s*\d+\s*(?:get|take)\s*\d+\b', caseSensitive: false),
  RegExp(r'\bb\d+t\d+\b', caseSensitive: false), // b1t1, b2t1
  RegExp(r'\b\d+%\s*(?:off|discount)\b', caseSensitive: false),
];

/// K-suffix amount multiplier pattern: 30k, 1.5K, etc.
final RegExp kAmountKSuffix = RegExp(r'^(\d+\.?\d*)[kK]$');

/// Peso-prefixed amount: peso250, P300, php250, Php 300
final RegExp kPesoPrefix = RegExp(
  r'(?:₱|[Pp][Hh][Pp]?\s*|[Pp])(\d[\d,]*\.?\d*)',
);

/// Plain number: 250, 1500, 250.50, 1,500
final RegExp kPlainNumber = RegExp(r'^\d[\d,]*\.?\d*$');

// ═══════════════════════════════════════════════════════════════════════
// DESCRIPTION CLEANUP
// ═══════════════════════════════════════════════════════════════════════

/// Leading/trailing prepositions to strip from cleaned descriptions.
const Set<String> kDanglingPrepositions = {
  'sa', 'ng', 'ni', 'kay', 'para', 'at', 'and', 'from', 'with',
};

/// "pang-" prefix words — strip prefix to get root word for category lookup.
final RegExp kPangPrefix = RegExp(r'^(?:pang|pinang|ipang|ipinang)(.+)$');
