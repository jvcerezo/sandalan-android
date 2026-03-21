import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage the "hide balances" privacy feature.
class PrivacyService {
  PrivacyService._();
  static final PrivacyService instance = PrivacyService._();

  static const _hideBalancesKey = 'hide_balances';

  Future<bool> isHidden() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hideBalancesKey) ?? false;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getBool(_hideBalancesKey) ?? false;
    await prefs.setBool(_hideBalancesKey, !current);
  }

  Future<void> setHidden(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideBalancesKey, value);
  }
}
