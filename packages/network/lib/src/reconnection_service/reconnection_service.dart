import 'dart:async';

import 'connection_monitor.dart';
import 'lifecycle_service.dart';

/// Runs connect/disconnect actions on app lifecycle and network changes.
///
/// Active = app in foreground AND network available. Transitions are
/// debounced; duplicate states do not re-trigger actions.
class ReconnectionService {
  final LifecycleService _lifecycleService;
  final ConnectionMonitor _connectionMonitor;
  final Duration _debounce;

  final _onConnectedActions = <Future<void> Function()>[];
  final _onDisconnectedActions = <Future<void> Function()>[];
  final _subscriptions = <StreamSubscription<bool>>[];
  late bool _lastActive;
  Timer? _debounceTimer;

  ReconnectionService({
    required LifecycleService lifecycleService,
    required ConnectionMonitor connectionMonitor,
    Duration debounce = const Duration(seconds: 2),
  })  : _lifecycleService = lifecycleService,
        _connectionMonitor = connectionMonitor,
        _debounce = debounce {
    _lastActive = _isActive;
    _subscriptions
      ..add(_lifecycleService.onForegroundChanged
          .listen((_) => _onStateChanged()))
      ..add(_connectionMonitor.onNetworkChanged
          .listen((_) => _onStateChanged()));
  }

  bool get _isActive =>
      _lifecycleService.isForeground && _connectionMonitor.hasNetwork;

  void addOnConnectedAction(Future<void> Function() action) =>
      _onConnectedActions.add(action);

  void removeOnConnectedAction(Future<void> Function() action) =>
      _onConnectedActions.remove(action);

  void addOnDisconnectedAction(Future<void> Function() action) =>
      _onDisconnectedActions.add(action);

  void removeOnDisconnectedAction(Future<void> Function() action) =>
      _onDisconnectedActions.remove(action);

  void _onStateChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      final active = _isActive;
      if (active == _lastActive) return;
      _lastActive = active;
      final actions =
          active ? _onConnectedActions : _onDisconnectedActions;
      for (final action in List.of(actions)) {
        unawaited(action());
      }
    });
  }

  void dispose() {
    _debounceTimer?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
  }
}
