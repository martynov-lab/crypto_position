import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/signal_event.dart';
import '../models/spread_point.dart';
import 'screener_client.dart';
import 'screener_server_message.dart';

/// Drives one coin's live spread chart: sends `watch`, buffers the
/// `watch_snapshot` backfill + `spread_tick` stream into a rolling window, and
/// sends `unwatch` on [dispose].
///
/// A reconnect makes the server resend a fresh snapshot (the client re-sends
/// the watch), which simply replaces the buffer.
class SpreadChartController {
  final ScreenerClient _client;
  final Instrument instrument;
  final int windowMs;

  final _points = ValueNotifier<List<SpreadPoint>>(const []);
  int _resolutionMs = 0;
  StreamSubscription<ScreenerServerMessage>? _sub;

  SpreadChartController(
    this._client, {
    required this.instrument,
    this.windowMs = 900000,
  });

  /// Points in the current window, oldest → newest.
  ValueListenable<List<SpreadPoint>> get points => _points;

  /// Server-chosen sample cadence (0 until the first snapshot).
  int get resolutionMs => _resolutionMs;

  /// Begins watching. Returns `false` if the local watch cap is reached — the
  /// UI should surface that instead of an endless spinner.
  bool start() {
    _sub = _client.watchUpdates.listen(_onUpdate);
    final ok = _client.watch(instrument, windowMs: windowMs);
    if (!ok) {
      unawaited(_sub?.cancel());
      _sub = null;
    }
    return ok;
  }

  void _onUpdate(ScreenerServerMessage message) {
    switch (message) {
      case ScreenerWatchSnapshot(:final instrument, :final resolutionMs, :final points)
          when instrument.pair == this.instrument.pair:
        _resolutionMs = resolutionMs;
        _points.value = _trim(points);
      case ScreenerSpreadTick(:final instrument, :final point)
          when instrument.pair == this.instrument.pair:
        _points.value = _trim([..._points.value, point]);
      default:
        break;
    }
  }

  /// Keeps only points within [windowMs] of the newest sample.
  List<SpreadPoint> _trim(List<SpreadPoint> points) {
    if (points.isEmpty) return const [];
    final cutoff = points.last.tsMs - windowMs;
    return points.where((p) => p.tsMs >= cutoff).toList();
  }

  void dispose() {
    unawaited(_sub?.cancel());
    _client.unwatch(instrument);
    _points.dispose();
  }
}
