import 'dart:async';

import 'package:crypto_position/src/bybit_account_repository_factory.dart';
import 'package:crypto_position/src/bybit_account_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:network/network.dart';

const _keyApiKey = 'BYBIT_API_KEY';
const _keyApiSecret = 'BYBIT_API_SECRET';

/// App-scoped owner of the Bybit session: stores credentials, opens and
/// closes the REST + WS connection, exposes the connection state.
class BybitSessionService {
  final FlutterSecureStorage _storage;
  final BybitAccountRepositoryFactory _accountFactory;
  final ReconnectionService _reconnectionService;

  final ValueNotifier<bool> _hasCredentials = ValueNotifier(false);
  final ValueNotifier<bool> _loading = ValueNotifier(false);
  final ValueNotifier<String?> _error = ValueNotifier(null);
  final ValueNotifier<BybitAccountSession?> _session = ValueNotifier(null);

  ValueListenable<bool> get hasCredentials => _hasCredentials;
  ValueListenable<bool> get loading => _loading;
  ValueListenable<String?> get error => _error;
  ValueListenable<BybitAccountSession?> get session => _session;

  BybitSessionService({
    required FlutterSecureStorage storage,
    required BybitAccountRepositoryFactory accountFactory,
    required ReconnectionService reconnectionService,
  }) : _storage = storage,
       _accountFactory = accountFactory,
       _reconnectionService = reconnectionService;

  /// Loads stored credentials and connects when they are present.
  Future<void> init() async {
    final apiKey = await _storage.read(key: _keyApiKey);
    final apiSecret = await _storage.read(key: _keyApiSecret);
    if (apiKey != null && apiSecret != null && apiKey.isNotEmpty) {
      _hasCredentials.value = true;
      await _connectApi(apiKey, apiSecret);
    }
  }

  Future<void> saveCredentials(String apiKey, String apiSecret) async {
    await _storage.write(key: _keyApiKey, value: apiKey);
    await _storage.write(key: _keyApiSecret, value: apiSecret);
    _hasCredentials.value = true;
    await _connectApi(apiKey, apiSecret);
  }

  Future<void> logout() async {
    _closeSession();
    await _storage.delete(key: _keyApiKey);
    await _storage.delete(key: _keyApiSecret);
    _hasCredentials.value = false;
  }

  void dispose() {
    _closeSession();
  }

  Future<void> _wsConnect() async => _session.value?.wsManager.start();

  Future<void> _wsDisconnect() async => _session.value?.wsManager.stop();

  void _closeSession() {
    _reconnectionService
      ..removeOnConnectedAction(_wsConnect)
      ..removeOnDisconnectedAction(_wsDisconnect);
    _session.value?.dispose();
    _session.value = null;
  }

  Future<void> _connectApi(String apiKey, String apiSecret) async {
    _loading.value = true;
    _error.value = null;

    final session = _accountFactory.create(
      apiKey: apiKey,
      apiSecret: apiSecret,
    );
    _session.value = session;

    // On success the repository stores the balance in its own notifier.
    final result = await session.repository.fetchWalletBalance();
    if (_session.value != session) return;
    result.fold((_) {}, (error) => _error.value = error.toString());
    _loading.value = false;

    unawaited(session.wsManager.start());
    _reconnectionService
      ..addOnConnectedAction(_wsConnect)
      ..addOnDisconnectedAction(_wsDisconnect);
  }
}
