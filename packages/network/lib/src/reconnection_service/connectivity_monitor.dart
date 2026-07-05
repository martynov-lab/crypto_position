import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'connection_monitor.dart';

/// Network availability via the connectivity_plus plugin.
class ConnectivityMonitor implements ConnectionMonitor {
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _hasNetwork = true;

  ConnectivityMonitor([Connectivity? connectivity]) {
    final instance = connectivity ?? Connectivity();
    _subscription = instance.onConnectivityChanged.listen(_onResults);
    unawaited(instance.checkConnectivity().then(_onResults));
  }

  @override
  bool get hasNetwork => _hasNetwork;

  @override
  Stream<bool> get onNetworkChanged => _controller.stream;

  void _onResults(List<ConnectivityResult> results) {
    final hasNetwork =
        results.any((result) => result != ConnectivityResult.none);
    if (hasNetwork == _hasNetwork) return;
    _hasNetwork = hasNetwork;
    _controller.add(hasNetwork);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
