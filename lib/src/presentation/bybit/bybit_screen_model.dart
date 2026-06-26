import 'package:elementary/elementary.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keyApiKey = 'BYBIT_API_KEY';
const _keyApiSecret = 'BYBIT_API_SECRET';

class BybitScreenModel extends ElementaryModel {
  final FlutterSecureStorage _storage;

  BybitScreenModel({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getApiKey() => _storage.read(key: _keyApiKey);
  Future<String?> getApiSecret() => _storage.read(key: _keyApiSecret);

  Future<void> saveCredentials(String apiKey, String apiSecret) async {
    await _storage.write(key: _keyApiKey, value: apiKey);
    await _storage.write(key: _keyApiSecret, value: apiSecret);
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyApiKey);
    await _storage.delete(key: _keyApiSecret);
  }
}
