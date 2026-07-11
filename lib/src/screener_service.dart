import 'dart:async';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:network/network.dart';
import 'package:screener/screener.dart';

/// App-scoped owner of the arbitrage screener connection.
///
/// Unlike the exchange sessions this needs no credentials: it opens the public
/// WebSocket signal stream on [init] and keeps a newest-wins table of live
/// [SignalEvent]s keyed by instrument.
class ScreenerService {
  final ScreenerClient _client;
  final ScreenerRestApi _rest;
  final ReconnectionService _reconnectionService;

  final _byPair = <String, SignalEvent>{};
  final ValueNotifier<List<SignalEvent>> _signals = ValueNotifier(const []);
  final ValueNotifier<List<SummaryEntry>> _summary = ValueNotifier(const []);
  final ValueNotifier<String?> _error = ValueNotifier(null);

  StreamSubscription<SignalEvent>? _eventSub;
  StreamSubscription<String>? _errorSub;

  ScreenerService({
    ScreenerConfig config = const ScreenerConfig(),
    required ReconnectionService reconnectionService,
  })  : _reconnectionService = reconnectionService,
        _client = ScreenerClient(config: config),
        _rest = ScreenerRestApi(
          RestClient(
            createSharedHttpClient()
              ..interceptors.addAll([
                BaseUrlDioInterceptor(getHost: () => Uri.parse(config.baseRestUrl)),
                if (kDebugMode)
                  LogInterceptor(requestBody: true, responseBody: true),
              ]),
          ),
        );

  /// `connected` once the `subscribe` handshake is acked.
  ValueListenable<WsConnectionState> get connectionState => _client.state;

  /// Traded-instrument catalog from the latest `universe` push.
  ValueListenable<List<InstrumentCoverage>> get universe => _client.universe;

  /// Live signals, newest-per-instrument, sorted by quality (best first).
  ValueListenable<List<SignalEvent>> get signals => _signals;

  /// Cold-start snapshot from `GET /summary` (best spread per instrument).
  ValueListenable<List<SummaryEntry>> get summary => _summary;

  /// Latest server-reported error (invalid config, `unauthorized`, ...).
  ValueListenable<String?> get error => _error;

  ClientConfig get clientConfig => _client.clientConfig;

  void init() {
    _eventSub = _client.events.listen(_onEvent);
    _errorSub = _client.errors.listen((message) => _error.value = message);
    _client.start();
    _reconnectionService
      ..addOnConnectedAction(_wsConnect)
      ..addOnDisconnectedAction(_wsDisconnect);
    unawaited(refreshSummary());
  }

  /// Re-subscribes with a new filter set; clears the current table so it
  /// refills under the new filters.
  void reconfigure(ClientConfig config) {
    _error.value = null;
    _byPair.clear();
    _signals.value = const [];
    _client.reconfigure(config);
  }

  /// Validates a config server-side without subscribing.
  Future<Result<ConfigValidation, Object>> validateConfig(
    ClientConfig config,
  ) =>
      _rest.validateConfig(config);

  Future<void> refreshSummary() async {
    final result = await _rest.fetchSummary();
    result.fold((rows) => _summary.value = rows, (_) {});
  }

  void _onEvent(SignalEvent event) {
    _byPair[event.instrument.pair] = event;
    final list = _byPair.values.toList()
      ..sort((a, b) => b.sortScore.compareTo(a.sortScore));
    _signals.value = list;
  }

  Future<void> _wsConnect() async => _client.start();

  Future<void> _wsDisconnect() async => _client.stop();

  void dispose() {
    _reconnectionService
      ..removeOnConnectedAction(_wsConnect)
      ..removeOnDisconnectedAction(_wsDisconnect);
    unawaited(_eventSub?.cancel());
    unawaited(_errorSub?.cancel());
    _client.dispose();
    _signals.dispose();
    _summary.dispose();
    _error.dispose();
  }
}
