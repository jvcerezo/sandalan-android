/// Market exchange rate model — port of MarketRate interface from database.ts

class MarketRate {
  final String currency;
  final double rateToPhp;
  final String updatedAt;

  const MarketRate({
    required this.currency,
    required this.rateToPhp,
    required this.updatedAt,
  });

  factory MarketRate.fromJson(Map<String, dynamic> json) {
    return MarketRate(
      currency: json['currency'] as String,
      rateToPhp: (json['rate_to_php'] as num).toDouble(),
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'rate_to_php': rateToPhp,
        'updated_at': updatedAt,
      };
}
