import 'package:crypto_position/src/share_preferences/shared_preferences_common.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Реализация [SharedPreferencesAsync].
class SharedPreferencesAsAsync implements SharedPreferencesCommon {
  final SharedPreferencesAsync _preferences;

  const SharedPreferencesAsAsync({required SharedPreferencesAsync preferences})
    : _preferences = preferences;

  @override
  Future<Iterable<String>> allKeys() => _preferences.getKeys();

  @override
  Future<bool> containsKey(String key) async {
    await _preferences.containsKey(key);

    return Future.value(true);
  }

  @override
  Future<bool> remove(String key) async {
    await _preferences.remove(key);

    return Future.value(true);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    await _preferences.setBool(key, value);

    return Future.value(true);
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    await _preferences.setDouble(key, value);

    return Future.value(true);
  }

  @override
  Future<bool> setInt(String key, int value) async {
    await _preferences.setInt(key, value);

    return Future.value(true);
  }

  @override
  Future<bool> setString(String key, String value) async {
    await _preferences.setString(key, value);

    return Future.value(true);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    await _preferences.setStringList(key, value);

    return Future.value(true);
  }

  @override
  Future<bool?> getBool(String key) => _preferences.getBool(key);

  @override
  Future<double?> getDouble(String key) => _preferences.getDouble(key);

  @override
  Future<int?> getInt(String key) => _preferences.getInt(key);

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<List<String>?> getStringList(String key) =>
      _preferences.getStringList(key);
}
