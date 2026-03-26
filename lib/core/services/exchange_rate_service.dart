import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Fetches and caches PHP exchange rates from a free API.
/// Rates are cached for 6 hours to minimize API calls.
class ExchangeRateService {
  ExchangeRateService._();
  static final ExchangeRateService instance = ExchangeRateService._();

  static const _cacheKey = 'exchange_rates_cache';
  static const _cacheTimeKey = 'exchange_rates_cache_time';
  static const _cacheDuration = Duration(hours: 6);

  // Free API — no key needed, 1500 req/month
  // Base currency is PHP, returns rate of 1 PHP in other currencies.
  // We invert to get "1 USD = X PHP" format.
  static const _apiUrl = 'https://api.exchangerate-api.com/v4/latest/PHP';

  Map<String, double>? _cachedRates;
  DateTime? _lastFetch;

  /// Get rate for 1 unit of [currency] in PHP.
  /// Returns null if rate is unavailable.
  Future<double?> getRate(String currency) async {
    if (currency == 'PHP') return 1.0;
    final rates = await getRates();
    if (rates == null) return null;

    // API returns: 1 PHP = X USD (e.g., 0.018)
    // We want: 1 USD = X PHP (e.g., 56.5)
    final phpToOther = rates[currency];
    if (phpToOther == null || phpToOther == 0) return null;
    return 1.0 / phpToOther;
  }

  /// Get all rates (1 PHP = X of each currency).
  /// Returns cached data if fresh enough, otherwise fetches from API.
  Future<Map<String, double>?> getRates() async {
    // Check memory cache
    if (_cachedRates != null && _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      return _cachedRates;
    }

    // Check disk cache
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_cacheKey);
    final cachedTime = prefs.getInt(_cacheTimeKey);

    if (cachedJson != null && cachedTime != null) {
      final cacheAge = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(cachedTime));
      if (cacheAge < _cacheDuration) {
        _cachedRates = Map<String, double>.from(
          (jsonDecode(cachedJson) as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        );
        _lastFetch = DateTime.fromMillisecondsSinceEpoch(cachedTime);
        return _cachedRates;
      }
    }

    // Fetch fresh rates
    try {
      final response = await http.get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = (data['rates'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );

        // Cache to memory + disk
        _cachedRates = rates;
        _lastFetch = DateTime.now();
        await prefs.setString(_cacheKey, jsonEncode(rates));
        await prefs.setInt(_cacheTimeKey, _lastFetch!.millisecondsSinceEpoch);

        return rates;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('ExchangeRateService: fetch failed: $e');
    }

    // Fall back to stale cache if available
    return _cachedRates;
  }

  /// Convert an amount from one currency to another via PHP.
  Future<double?> convert(double amount, String from, String to) async {
    if (from == to) return amount;

    final rates = await getRates();
    if (rates == null) return null;

    // Convert from -> PHP -> to
    double phpAmount;
    if (from == 'PHP') {
      phpAmount = amount;
    } else {
      final fromRate = rates[from];
      if (fromRate == null || fromRate == 0) return null;
      phpAmount = amount / fromRate; // 1 PHP = fromRate of 'from', so amount/fromRate = PHP
    }

    if (to == 'PHP') return phpAmount;

    final toRate = rates[to];
    if (toRate == null) return null;
    return phpAmount * toRate; // PHP * rate = target currency
  }

  /// Get the timestamp of the last successful fetch.
  DateTime? get lastFetchTime => _lastFetch;

  /// Force refresh from API (ignores cache).
  Future<Map<String, double>?> refresh() async {
    _cachedRates = null;
    _lastFetch = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
    return getRates();
  }
}
