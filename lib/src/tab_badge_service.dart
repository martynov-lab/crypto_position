import 'dart:async';

import 'package:crypto_position/src/bitget_session_service.dart';
import 'package:crypto_position/src/bybit_session_service.dart';
import 'package:crypto_position/src/gate_session_service.dart';
import 'package:crypto_position/src/mexc_session_service.dart';
import 'package:crypto_position/src/notification_service.dart';
import 'package:crypto_position/src/okx_session_service.dart';
import 'package:crypto_position/src/screener_service.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Tracks "unseen" arrivals for the bottom-nav badges: Main lights up when a
/// position opens while the user is on another tab, Screener when a signal
/// for a not-yet-shown instrument arrives.
///
/// A badge clears when its tab becomes active ([markTabActive]); events that
/// land while the tab is already active never light it.
class TabBadgeService {
  /// Bottom-nav branch indexes (see the router's StatefulShellBranch order).
  static const mainTabIndex = 0;
  static const screenerTabIndex = 3;

  final ScreenerService _screener;
  final NotificationService _notifications;
  late final List<_PositionSource> _sources;

  final ValueNotifier<bool> _mainBadge = ValueNotifier(false);
  final ValueNotifier<bool> _screenerBadge = ValueNotifier(false);

  /// Position keys (`exchange:symbol:side`) already shown or counted toward
  /// the badge; a key that disappears and comes back counts as new again.
  final Set<String> _seenPositions = {};

  /// Instrument pairs already counted toward the Screener badge.
  final Set<String> _seenPairs = {};

  int _activeTab = mainTabIndex;

  ValueListenable<bool> get mainBadge => _mainBadge;
  ValueListenable<bool> get screenerBadge => _screenerBadge;

  TabBadgeService({
    required BybitSessionService bybit,
    required OkxSessionService okx,
    required BitgetSessionService bitget,
    required GateSessionService gate,
    required MexcSessionService mexc,
    required ScreenerService screener,
    required NotificationService notifications,
  }) : _screener = screener,
       _notifications = notifications {
    _sources = [
      _PositionSource(
        'Bybit',
        bybit.session,
        () => bybit.session.value?.repository,
      ),
      _PositionSource('OKX', okx.session, () => okx.session.value?.repository),
      _PositionSource(
        'Bitget',
        bitget.session,
        () => bitget.session.value?.repository,
      ),
      _PositionSource(
        'Gate',
        gate.session,
        () => gate.session.value?.repository,
      ),
      _PositionSource(
        'MEXC',
        mexc.session,
        () => mexc.session.value?.repository,
      ),
    ];
    for (final source in _sources) {
      source.onSessionChanged = () => _onSessionChanged(source);
      source.onPositionsChanged = () => _onPositionsChanged(source);
      source.session.addListener(source.onSessionChanged);
      _onSessionChanged(source);
    }
    _screener.signals.addListener(_onSignalsChanged);
  }

  /// Called by the nav bar on tab switches; clears that tab's badge.
  void markTabActive(int index) {
    _activeTab = index;
    if (index == mainTabIndex) _mainBadge.value = false;
    if (index == screenerTabIndex) _screenerBadge.value = false;
  }

  void _onSessionChanged(_PositionSource source) {
    final repo = source.repo();
    if (identical(source.boundRepo, repo)) return;
    source.boundRepo?.positions.removeListener(source.onPositionsChanged);
    repo?.positions.addListener(source.onPositionsChanged);
    source.boundRepo = repo;
    // A fresh session re-seeds over REST: its first list is a baseline, not
    // "new" positions.
    source.baselined = false;
    _seenPositions.removeWhere((key) => key.startsWith('${source.name}:'));
    _onPositionsChanged(source);
  }

  void _onPositionsChanged(_PositionSource source) {
    final positions = source.boundRepo?.positions.value;
    if (positions == null) return;
    final keys = positions
        .map((p) => '${source.name}:${p.symbol}:${p.side}')
        .toSet();
    if (!source.baselined) {
      source.baselined = true;
      _seenPositions.addAll(keys);
      return;
    }
    final newPositions = positions
        .where(
          (p) => !_seenPositions.contains(
            '${source.name}:${p.symbol}:${p.side}',
          ),
        )
        .toList();
    _seenPositions
      ..removeWhere(
        (key) => key.startsWith('${source.name}:') && !keys.contains(key),
      )
      ..addAll(keys);
    if (newPositions.isEmpty) return;
    if (_activeTab != mainTabIndex) _mainBadge.value = true;
    if (_activeTab != mainTabIndex || !_appFocused) {
      unawaited(
        _notifications.show(
          id: NotificationService.positionsNotificationId,
          title: 'New position opened',
          body: newPositions
              .map((p) => '${source.name} ${p.symbol} ${p.side}')
              .join(', '),
        ),
      );
    }
  }

  // Only `alert`-level signals badge/notify; `info` ones are list-only (they
  // crossed `min_net_spread_pct` but not the `alert_net_spread_pct` the user
  // actually wants to be interrupted for).
  void _onSignalsChanged() {
    final pairs = _screener.signals.value
        .where((event) => event.isAlert)
        .map((event) => event.instrument.pair)
        .toSet();
    final newPairs = pairs.where((p) => !_seenPairs.contains(p)).toList();
    _seenPairs
      ..retainAll(pairs)
      ..addAll(pairs);
    if (newPairs.isEmpty) return;
    if (_activeTab != screenerTabIndex) _screenerBadge.value = true;
    if (_activeTab != screenerTabIndex || !_appFocused) {
      unawaited(
        _notifications.show(
          id: NotificationService.signalsNotificationId,
          title: 'New arbitrage signal',
          body: newPairs.join(', '),
        ),
      );
    }
  }

  /// `resumed` only: on desktop an unfocused window reports `inactive`, which
  /// is exactly when a toast is useful.
  bool get _appFocused =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  void dispose() {
    for (final source in _sources) {
      source.session.removeListener(source.onSessionChanged);
      source.boundRepo?.positions.removeListener(source.onPositionsChanged);
    }
    _screener.signals.removeListener(_onSignalsChanged);
    _mainBadge.dispose();
    _screenerBadge.dispose();
  }
}

/// One exchange's session slot: rebinds to the repository inside whatever
/// session is currently live.
class _PositionSource {
  final String name;
  final Listenable session;
  final ExchangeAccountRepository? Function() repo;

  ExchangeAccountRepository? boundRepo;

  /// Whether the current session's initial REST seed was already absorbed.
  bool baselined = false;

  late VoidCallback onSessionChanged;
  late VoidCallback onPositionsChanged;

  _PositionSource(this.name, this.session, this.repo);
}
