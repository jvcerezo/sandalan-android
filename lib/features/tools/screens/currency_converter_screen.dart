import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Currency data: code, flag emoji, name, fallback rate to PHP.
class _CurrencyInfo {
  final String code;
  final String flag;
  final String name;
  final double fallbackRate;
  const _CurrencyInfo(this.code, this.flag, this.name, this.fallbackRate);
}

const _currencies = [
  _CurrencyInfo('PHP', '\ud83c\uddf5\ud83c\udded', 'Philippine Peso', 1.0),
  _CurrencyInfo('USD', '\ud83c\uddfa\ud83c\uddf8', 'US Dollar', 56.5),
  _CurrencyInfo('SGD', '\ud83c\uddf8\ud83c\uddec', 'Singapore Dollar', 42.8),
  _CurrencyInfo('AUD', '\ud83c\udde6\ud83c\uddfa', 'Australian Dollar', 36.0),
  _CurrencyInfo('JPY', '\ud83c\uddef\ud83c\uddf5', 'Japanese Yen', 0.37),
  _CurrencyInfo('GBP', '\ud83c\uddec\ud83c\udde7', 'British Pound', 72.0),
  _CurrencyInfo('EUR', '\ud83c\uddea\ud83c\uddfa', 'Euro', 62.0),
  _CurrencyInfo('AED', '\ud83c\udde6\ud83c\uddea', 'UAE Dirham', 15.4),
  _CurrencyInfo('KRW', '\ud83c\uddf0\ud83c\uddf7', 'Korean Won', 0.042),
  _CurrencyInfo('SAR', '\ud83c\uddf8\ud83c\udde6', 'Saudi Riyal', 15.1),
  _CurrencyInfo('HKD', '\ud83c\udded\ud83c\uddf0', 'Hong Kong Dollar', 7.2),
  _CurrencyInfo('CAD', '\ud83c\udde8\ud83c\udde6', 'Canadian Dollar', 41.5),
  _CurrencyInfo('MYR', '\ud83c\uddf2\ud83c\uddfe', 'Malaysian Ringgit', 12.5),
  _CurrencyInfo('TWD', '\ud83c\uddf9\ud83c\uddfc', 'Taiwan Dollar', 1.8),
];

/// Fallback rates map built from hardcoded currency list.
Map<String, double> _fallbackRates() {
  final m = <String, double>{};
  for (final c in _currencies) {
    m[c.code] = c.fallbackRate;
  }
  return m;
}

/// Fetches live rates from Supabase market_rates table, caches in SharedPreferences.
final marketRatesProvider = FutureProvider<Map<String, double>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  try {
    final client = Supabase.instance.client;
    final response = await client.from('market_rates').select();
    final rates = <String, double>{'PHP': 1.0};
    for (final row in response) {
      rates[row['currency'] as String] = (row['rate_to_php'] as num).toDouble();
    }
    // Cache for offline use
    await prefs.setString('currency_rates', jsonEncode(rates));
    return rates;
  } catch (_) {
    // Offline — try cached rates
    final cached = prefs.getString('currency_rates');
    if (cached != null) {
      try {
        final decoded = (jsonDecode(cached) as Map<String, dynamic>);
        return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (_) {}
    }
    return _fallbackRates();
  }
});

/// Fetches the last updated_at timestamp from market_rates.
final ratesLastUpdatedProvider = FutureProvider<String>((ref) async {
  try {
    final client = Supabase.instance.client;
    final response = await client
        .from('market_rates')
        .select('updated_at')
        .order('updated_at', ascending: false)
        .limit(1);
    if (response.isNotEmpty) {
      return response[0]['updated_at'] as String;
    }
  } catch (_) {}
  return '';
});

/// Whether we fell back to cached/hardcoded rates (offline).
final ratesOfflineProvider = FutureProvider<bool>((ref) async {
  try {
    final client = Supabase.instance.client;
    await client.from('market_rates').select('currency').limit(1);
    return false;
  } catch (_) {
    return true;
  }
});

class CurrencyConverterScreen extends ConsumerStatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  ConsumerState<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends ConsumerState<CurrencyConverterScreen> {
  final _amountCtl = TextEditingController(text: '1000');
  String _fromCode = 'PHP';
  String _toCode = 'USD';

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  double _convert(double amount, String from, String to, Map<String, double> rates) {
    if (from == to) return amount;
    final fromRate = rates[from] ?? 1.0;
    final toRate = rates[to] ?? 1.0;
    return amount * fromRate / toRate;
  }

  void _swap() {
    setState(() {
      final tmp = _fromCode;
      _fromCode = _toCode;
      _toCode = tmp;
    });
  }

  _CurrencyInfo _info(String code) =>
      _currencies.firstWhere((c) => c.code == code, orElse: () => _currencies.first);

  void _refresh() {
    ref.invalidate(marketRatesProvider);
    ref.invalidate(ratesLastUpdatedProvider);
    ref.invalidate(ratesOfflineProvider);
  }

  String _timeAgo(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().toUtc().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratesAsync = ref.watch(marketRatesProvider);
    final lastUpdatedAsync = ref.watch(ratesLastUpdatedProvider);
    final offlineAsync = ref.watch(ratesOfflineProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/tools');
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Currency Converter',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              tooltip: 'Refresh rates',
              onPressed: _refresh,
            ),
          ],
        ),
        body: ratesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildBody(context, _fallbackRates(), colorScheme,
              lastUpdated: '', isOffline: true),
          data: (rates) {
            // Fill any missing currencies with fallback
            for (final c in _currencies) {
              rates.putIfAbsent(c.code, () => c.fallbackRate);
            }
            final lastUpdated = lastUpdatedAsync.valueOrNull ?? '';
            final isOffline = offlineAsync.valueOrNull ?? false;
            return _buildBody(context, rates, colorScheme,
                lastUpdated: lastUpdated, isOffline: isOffline);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, double> rates,
      ColorScheme colorScheme,
      {required String lastUpdated, required bool isOffline}) {
    final amount = double.tryParse(_amountCtl.text.replaceAll(',', '')) ?? 0;
    final converted = _convert(amount, _fromCode, _toCode, rates);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Offline banner
          if (isOffline)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.wifiOff, size: 14, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text('Offline \u2014 using cached rates',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700])),
                ],
              ),
            ),

          // Input amount
          TextField(
            controller: _amountCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Amount',
              prefixText: '${_info(_fromCode).flag} ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // From currency
          _CurrencyDropdown(
            label: 'From',
            value: _fromCode,
            onChanged: (v) => setState(() => _fromCode = v),
          ),
          const SizedBox(height: 8),

          // Swap button
          Center(
            child: IconButton.filledTonal(
              onPressed: _swap,
              icon: const Icon(LucideIcons.arrowUpDown, size: 20),
              tooltip: 'Swap currencies',
            ),
          ),
          const SizedBox(height: 8),

          // To currency
          _CurrencyDropdown(
            label: 'To',
            value: _toCode,
            onChanged: (v) => setState(() => _toCode = v),
          ),
          const SizedBox(height: 16),

          // Result
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              Text(
                '${_info(_fromCode).flag} ${amount.toStringAsFixed(2)} $_fromCode',
                style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              const Text('=', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${_info(_toCode).flag} ${converted.toStringAsFixed(2)} $_toCode',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1 $_fromCode = ${_convert(1, _fromCode, _toCode, rates).toStringAsFixed(4)} $_toCode',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Popular rates
          Text('POPULAR RATES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              )),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.surfaceContainerHighest),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              for (final c in _currencies.where((c) => c.code != 'PHP'))
                _RateRow(
                  flag: c.flag,
                  code: c.code,
                  name: c.name,
                  rate: rates[c.code] ?? c.fallbackRate,
                ),
            ]),
          ),

          // Last updated
          const SizedBox(height: 16),
          if (lastUpdated.isNotEmpty)
            Center(
              child: Text(
                'Last updated: ${_timeAgo(lastUpdated)}',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  final String label;
  final String value;
  final void Function(String) onChanged;

  const _CurrencyDropdown({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isDense: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: _currencies
          .map((c) => DropdownMenuItem(
                value: c.code,
                child: Text('${c.flag} ${c.code} \u2014 ${c.name}',
                    style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _RateRow extends StatelessWidget {
  final String flag;
  final String code;
  final String name;
  final double rate;

  const _RateRow(
      {required this.flag, required this.code, required this.name, required this.rate});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Text(flag, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(code, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(name, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
        ])),
        Text('${rate.toStringAsFixed(rate < 1 ? 4 : 2)} PHP',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
