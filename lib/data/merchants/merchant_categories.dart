import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Known Filipino merchants/stores mapped to expense categories.
const kMerchantCategories = <String, String>{
  // ─── Food & Groceries ──────────────────────────────────────────────
  'sm supermarket': 'Food',
  'sm hypermarket': 'Food',
  'sm savemore': 'Food',
  'savemore': 'Food',
  'puregold': 'Food',
  'puregold price club': 'Food',
  'robinsons supermarket': 'Food',
  'robinsons easymart': 'Food',
  'metro supermarket': 'Food',
  'metro retail': 'Food',
  's&r': 'Food',
  's&r membership': 'Food',
  'landers': 'Food',
  'landers superstore': 'Food',
  'waltermart': 'Food',
  'ever gotesco': 'Food',
  'rustans': 'Food',
  'rustans supermarket': 'Food',
  'landmark supermarket': 'Food',
  'shopwise': 'Food',
  'south supermarket': 'Food',
  'cherry foodarama': 'Food',
  'unimart': 'Food',

  // Convenience stores
  '7-eleven': 'Food',
  '7 eleven': 'Food',
  'ministop': 'Food',
  'family mart': 'Food',
  'familymart': 'Food',
  'alfamart': 'Food',
  'lawson': 'Food',
  'all day': 'Food',
  'allday': 'Food',

  // Fast food & restaurants
  'jollibee': 'Food',
  'mcdonalds': 'Food',
  'mcdonald': 'Food',
  "mcdonald's": 'Food',
  'kfc': 'Food',
  'chowking': 'Food',
  'mang inasal': 'Food',
  'greenwich': 'Food',
  'pizza hut': 'Food',
  'burger king': 'Food',
  'wendys': 'Food',
  "wendy's": 'Food',
  'subway': 'Food',
  'kenny rogers': 'Food',
  'tokyo tokyo': 'Food',
  'teriyaki boy': 'Food',
  'yoshinoya': 'Food',
  'pepper lunch': 'Food',
  'army navy': 'Food',
  'yellow cab': 'Food',
  'shakeys': 'Food',
  "shakey's": 'Food',
  'bonchon': 'Food',
  'max': 'Food',
  "max's": 'Food',
  'mesa': 'Food',
  'vikings': 'Food',
  'sambo kojin': 'Food',
  'buffet 101': 'Food',
  'goldilocks': 'Food',
  'red ribbon': 'Food',
  'mary grace': 'Food',
  'pan de manila': 'Food',
  'tous les jours': 'Food',
  'bakers dozen': 'Food',

  // Coffee shops
  'starbucks': 'Food',
  'tim hortons': 'Food',
  'coffee bean': 'Food',
  'coffee project': 'Food',
  'bo coffee': 'Food',
  "bo's coffee": 'Food',
  'dunkin': 'Food',
  "dunkin'": 'Food',
  'dunkin donuts': 'Food',
  'krispy kreme': 'Food',

  // Milk tea
  'gong cha': 'Food',
  'macao imperial': 'Food',
  'tiger sugar': 'Food',
  'coco': 'Food',

  // Delivery
  'foodpanda': 'Food',
  'grabfood': 'Food',

  // ─── Transportation ────────────────────────────────────────────────
  'shell': 'Transportation',
  'petron': 'Transportation',
  'caltex': 'Transportation',
  'seaoil': 'Transportation',
  'phoenix': 'Transportation',
  'phoenix petroleum': 'Transportation',
  'total': 'Transportation',
  'total energies': 'Transportation',
  'cleanfuel': 'Transportation',
  'flying v': 'Transportation',
  'unioil': 'Transportation',
  'ptt': 'Transportation',
  'grab': 'Transportation',
  'grabcar': 'Transportation',
  'angkas': 'Transportation',
  'joyride': 'Transportation',
  'move it': 'Transportation',
  'ltfrb': 'Transportation',
  'lto': 'Transportation',
  'autosweep': 'Transportation',
  'easytrip': 'Transportation',
  'nlex': 'Transportation',
  'slex': 'Transportation',
  'skyway': 'Transportation',
  'cebu pacific': 'Transportation',
  'philippine airlines': 'Transportation',
  'pal': 'Transportation',
  'airasia': 'Transportation',

  // ─── Utilities (mapped to Housing) ─────────────────────────────────
  'meralco': 'Housing',
  'maynilad': 'Housing',
  'manila water': 'Housing',
  'pldt': 'Housing',
  'globe': 'Housing',
  'globe telecom': 'Housing',
  'smart': 'Housing',
  'smart communications': 'Housing',
  'converge': 'Housing',
  'converge ict': 'Housing',
  'dito': 'Housing',
  'dito telecommunity': 'Housing',
  'sky cable': 'Housing',
  'skycable': 'Housing',
  'cignal': 'Housing',

  // ─── Healthcare ────────────────────────────────────────────────────
  'mercury drug': 'Healthcare',
  'watsons': 'Healthcare',
  'southstar drug': 'Healthcare',
  'generika': 'Healthcare',
  'generika drugstore': 'Healthcare',
  'rose pharmacy': 'Healthcare',
  'the generics pharmacy': 'Healthcare',
  'tgp': 'Healthcare',
  'ritemed': 'Healthcare',
  'st lukes': 'Healthcare',
  "st. luke's": 'Healthcare',
  'makati med': 'Healthcare',
  'makati medical': 'Healthcare',
  'asian hospital': 'Healthcare',
  'medical city': 'Healthcare',
  'the medical city': 'Healthcare',

  // ─── Shopping / Entertainment ──────────────────────────────────────
  'sm department store': 'Entertainment',
  'sm store': 'Entertainment',
  'sm city': 'Entertainment',
  'robinsons department store': 'Entertainment',
  'robinsons galleria': 'Entertainment',
  'robinsons place': 'Entertainment',
  'uniqlo': 'Entertainment',
  'h&m': 'Entertainment',
  'zara': 'Entertainment',
  'miniso': 'Entertainment',
  'daiso': 'Entertainment',
  'japan home': 'Entertainment',
  'true value': 'Entertainment',
  'ace hardware': 'Entertainment',
  'handyman': 'Entertainment',
  'cw home depot': 'Entertainment',
  'wilcon': 'Entertainment',
  'sm cinema': 'Entertainment',
  'sm mall of asia': 'Entertainment',
  'ayala malls': 'Entertainment',
  'power plant': 'Entertainment',
  'greenbelt': 'Entertainment',
  'glorietta': 'Entertainment',
  'trinoma': 'Entertainment',
  'megamall': 'Entertainment',
  'netflix': 'Entertainment',
  'spotify': 'Entertainment',
  'disney': 'Entertainment',
  'hbo': 'Entertainment',
  'apple': 'Entertainment',
  'lazada': 'Entertainment',
  'shopee': 'Entertainment',
  'zalora': 'Entertainment',

  // ─── Education ─────────────────────────────────────────────────────
  'national bookstore': 'Education',
  'fully booked': 'Education',
  'powerbooks': 'Education',
  'rex bookstore': 'Education',
  'ateneo': 'Education',
  'la salle': 'Education',
  'ust': 'Education',
  'up': 'Education',
};

/// Case-insensitive partial matching of store name against known merchants.
/// Returns the category if matched, or null.
String? matchMerchant(String storeName) {
  final lower = storeName.toLowerCase().trim();
  if (lower.isEmpty) return null;

  // Exact match first
  if (kMerchantCategories.containsKey(lower)) {
    return kMerchantCategories[lower];
  }

  // Partial match: check if any known merchant name is contained in the store name
  for (final entry in kMerchantCategories.entries) {
    if (lower.contains(entry.key)) {
      return entry.value;
    }
  }

  // Reverse: check if store name is contained in any known merchant name
  for (final entry in kMerchantCategories.entries) {
    if (entry.key.contains(lower) && lower.length >= 3) {
      return entry.value;
    }
  }

  return null;
}

/// Stores user corrections for merchant → category mappings in SharedPreferences.
class LearnedMerchants {
  static const _key = 'learned_merchants';

  /// Get the learned category for a merchant, or null if not learned.
  static Future<String?> getCategory(String merchantName) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return null;
    final map = Map<String, String>.from(jsonDecode(data) as Map);
    return map[merchantName.toLowerCase().trim()];
  }

  /// Save a merchant → category mapping from user correction.
  static Future<void> learn(String merchantName, String category) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    final map = data != null
        ? Map<String, String>.from(jsonDecode(data) as Map)
        : <String, String>{};
    map[merchantName.toLowerCase().trim()] = category;
    await prefs.setString(_key, jsonEncode(map));
  }

  /// Match against learned merchants first, then fall back to built-in.
  static Future<String?> matchWithLearned(String storeName) async {
    // Check learned first
    final learned = await getCategory(storeName);
    if (learned != null) return learned;
    // Fall back to built-in
    return matchMerchant(storeName);
  }
}
