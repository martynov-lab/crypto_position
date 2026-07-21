import 'dart:async';

import 'package:crypto_position/src/mexc_account_repository_factory.dart';
import 'package:crypto_position/src/mexc_account_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:network/network.dart';

const _keyApiKey = 'MEXC_API_KEY';
const _keyApiSecret = 'MEXC_API_SECRET';

/// App-scoped owner of the MEXC session: stores credentials, opens and
/// closes the REST + WS connection, exposes the connection state.
class MexcSessionService {
  final FlutterSecureStorage _storage;
  final MexcAccountRepositoryFactory _accountFactory;
  final ReconnectionService _reconnectionService;

  final ValueNotifier<bool> _hasCredentials = ValueNotifier(false);
  final ValueNotifier<bool> _loading = ValueNotifier(false);
  final ValueNotifier<String?> _error = ValueNotifier(null);
  final ValueNotifier<MexcAccountSession?> _session = ValueNotifier(null);

  StreamSubscription<WsConnectionState>? _wsStateSub;

  /// Set once the private socket drops: the stream reports changes only, so
  /// whatever happened while it was down has to be re-read over REST.
  bool _needsResync = false;

  ValueListenable<bool> get hasCredentials => _hasCredentials;
  ValueListenable<bool> get loading => _loading;
  ValueListenable<String?> get error => _error;
  ValueListenable<MexcAccountSession?> get session => _session;

  MexcSessionService({
    required FlutterSecureStorage storage,
    required MexcAccountRepositoryFactory accountFactory,
    required ReconnectionService reconnectionService,
  })  : _storage = storage,
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

  /// Re-reads balance and open positions over REST.
  ///
  /// The WS stream only pushes changes, so a position closed while the socket
  /// was down never produces an event and would otherwise stay on screen.
  Future<void> resync() async {
    final session = _session.value;
    if (session == null) return;

    final balanceResult = await session.repository.fetchBalance();
    if (_session.value != session) return;
    balanceResult.fold((_) {}, (error) => _error.value = error.toString());

    final positionsResult = await session.repository.fetchPositions();
    if (_session.value != session) return;
    positionsResult.fold((_) {}, (error) => _error.value = error.toString());
  }

  /// Resyncs on returning to foreground even when [MexcAccountSession.startWs]
  /// is a no-op because the socket was never observed to drop.
  Future<void> _wsConnect() async {
    await _session.value?.startWs();
    await resync();
  }

  Future<void> _wsDisconnect() async => _session.value?.stopWs();

  void _onWsState(WsConnectionState state) {
    if (state == WsConnectionState.connected) {
      if (_needsResync) {
        _needsResync = false;
        unawaited(resync());
      }
      return;
    }
    _needsResync = true;
  }

  void _closeSession() {
    _reconnectionService
      ..removeOnConnectedAction(_wsConnect)
      ..removeOnDisconnectedAction(_wsDisconnect);
    unawaited(_wsStateSub?.cancel());
    _wsStateSub = null;
    _needsResync = false;
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
    unawaited(_wsStateSub?.cancel());
    _needsResync = false;
    _wsStateSub = session.wsManager.stateStream.listen(_onWsState);
    _session.value = session;

    // On success the repository stores the balance in its own notifier.
    final result = await session.repository.fetchBalance();
    if (_session.value != session) return;
    result.fold((_) {}, (error) => _error.value = error.toString());

    // Seed open positions before the WS position stream layers updates.
    final positionsResult = await session.repository.fetchPositions();
    if (_session.value != session) return;
    positionsResult.fold((_) {}, (error) => _error.value = error.toString());
    _loading.value = false;

    unawaited(session.startWs());
    _reconnectionService
      ..addOnConnectedAction(_wsConnect)
      ..addOnDisconnectedAction(_wsDisconnect);
  }
}
