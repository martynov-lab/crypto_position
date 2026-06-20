import 'package:crypto_position/src/share_preferences/shared_preferences_as_async.dart';
import 'package:crypto_position/src/share_preferences/shared_preferences_common.dart';
import 'package:crypto_position/src/share_preferences/shared_preferences_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Flutter-реализация [SharedPreferencesHelper] поверх `SharedPreferencesAsync`.
class SharedPreferencesHelperFlutter implements SharedPreferencesHelper {
  final SharedPreferencesCommon _preferences;

  /// Создаёт хелпер с явным backend (удобно для тестов).
  SharedPreferencesHelperFlutter(this._preferences);

  /// Создаёт хелпер с новым `SharedPreferencesAsync` по умолчанию.
  factory SharedPreferencesHelperFlutter.withDefaultAsyncBackend() =>
      SharedPreferencesHelperFlutter(
        SharedPreferencesAsAsync(preferences: SharedPreferencesAsync()),
      );

  @override
  Future<bool> getBool(String key, bool defaultValue) async =>
      (await _preferences.getBool(key)) ?? defaultValue;

  @override
  Future<int> getInt(String key, int defaultValue) async =>
      (await _preferences.getInt(key)) ?? defaultValue;

  // ignore: unused-code
  @override
  Future<double> getDouble(String key, double defaultValue) async =>
      (await _preferences.getDouble(key)) ?? defaultValue;

  @override
  Future<String> getString(String key, String defaultValue) async =>
      (await _preferences.getString(key)) ?? defaultValue;

  // ignore: unused-code
  @override
  Future<List<String>> getStringList(
    String key,
    List<String> defaultValue,
  ) async => (await _preferences.getStringList(key)) ?? defaultValue;

  @override
  Future<void> set(String key, Object value) async {
    if (value is bool) {
      await _preferences.setBool(key, value);
    } else if (value is int) {
      await _preferences.setInt(key, value);
    } else if (value is double) {
      await _preferences.setDouble(key, value);
    } else if (value is String) {
      await _preferences.setString(key, value);
    } else if (value is List<String>) {
      await _preferences.setStringList(key, value);
    } else {
      final message = "Doesn't support type ${value.runtimeType} yet.";
      // logger.warning(message);
      throw Exception(message);
    }
  }

  @override
  Future<bool> remove(String key) => _preferences.remove(key);

  @override
  Future<Iterable<String>> allKeys() => _preferences.allKeys();

  @override
  Future<bool> containsKey(String key) => _preferences.containsKey(key);
}
