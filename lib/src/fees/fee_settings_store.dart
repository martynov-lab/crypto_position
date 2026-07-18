import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/share_preferences/shared_preferences_helper.dart';
import 'package:flutter/foundation.dart';

/// Per-exchange maker fee (percent) used by the arbitrage calculator. A limit
/// order is a maker fill on both open and close, so one rate per exchange is
/// enough. Persisted via [SharedPreferencesHelper]; edited in Settings.
class FeeSettingsStore extends ChangeNotifier {
  /// Default maker fee (%) per exchange, from each venue's standard tier.
  static const Map<ExchangeId, double> _defaults = {
    ExchangeId.bybit: 0.02,
    ExchangeId.okx: 0.02,
    ExchangeId.bitget: 0.02,
    ExchangeId.gate: 0.02,
    ExchangeId.mexc: 0.01,
  };

  static String _key(ExchangeId e) => 'FEE_MAKER_${e.key}';

  final SharedPreferencesHelper _prefs;
  final Map<ExchangeId, double> _makerPct = Map.of(_defaults);

  FeeSettingsStore(this._prefs);

  /// Loads persisted overrides. Call once at startup.
  Future<void> load() async {
    for (final e in ExchangeId.values) {
      _makerPct[e] = await _prefs.getDouble(_key(e), _defaults[e]!);
    }
    notifyListeners();
  }

  double makerPct(ExchangeId exchange) =>
      _makerPct[exchange] ?? _defaults[exchange] ?? 0;

  void setMakerPct(ExchangeId exchange, double pct) {
    if (pct.isNaN || pct < 0) return;
    _makerPct[exchange] = pct;
    _prefs.set(_key(exchange), pct);
    notifyListeners();
  }
}
