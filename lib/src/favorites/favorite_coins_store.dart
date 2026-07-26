import 'package:crypto_position/src/share_preferences/shared_preferences_helper.dart';
import 'package:flutter/foundation.dart';

/// Coins the user starred in the screener universe, keyed by the instrument
/// pair (`BTC/USDT`). Persisted via [SharedPreferencesHelper]; toggled from the
/// universe tab, where the favourites filter narrows the catalog to this set.
class FavoriteCoinsStore extends ChangeNotifier {
  static const _key = 'SCREENER_FAVORITE_COINS';

  final SharedPreferencesHelper _prefs;
  final Set<String> _pairs = {};

  FavoriteCoinsStore(this._prefs);

  /// Loads the persisted set. Call once at startup.
  Future<void> load() async {
    _pairs
      ..clear()
      ..addAll(await _prefs.getStringList(_key, const []));
    notifyListeners();
  }

  bool isFavorite(String pair) => _pairs.contains(pair);

  void toggle(String pair) {
    if (!_pairs.remove(pair)) _pairs.add(pair);
    _prefs.set(_key, _pairs.toList());
    notifyListeners();
  }
}
