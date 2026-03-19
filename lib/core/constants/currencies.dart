/// Currency definitions and fallback exchange rates.

class Currency {
  final String code;
  final String symbol;
  final String name;

  const Currency({required this.code, required this.symbol, required this.name});
}

const List<Currency> kCurrencies = [
  Currency(code: 'PHP', symbol: '₱', name: 'Philippine Peso'),
  Currency(code: 'USD', symbol: '\$', name: 'US Dollar'),
  Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
];

/// Fallback exchange rates TO PHP (1 unit = X PHP).
const Map<String, double> kDefaultRatesToPhp = {
  'PHP': 1.0,
  'USD': 56.5,
  'AUD': 36.0,
};

/// Get the symbol for a currency code.
String currencySymbol(String code) {
  return kCurrencies
      .firstWhere((c) => c.code == code, orElse: () => kCurrencies.first)
      .symbol;
}
