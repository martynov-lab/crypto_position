import 'package:network/network.dart';

/// Reports the app as permanently foreground, so [ReconnectionService] never
/// tears the exchange sockets down on focus loss / backgrounding.
///
/// Needed for background notifications: new-position events only arrive over
/// the private WS streams. On Android the process itself is kept alive by the
/// keep-alive foreground service; on Windows a minimized app keeps running
/// anyway. Missed events after a real socket drop are still covered by the
/// sessions' resync-on-reconnect and pull-to-refresh.
class AlwaysOnLifecycleService implements LifecycleService {
  const AlwaysOnLifecycleService();

  @override
  bool get isForeground => true;

  @override
  Stream<bool> get onForegroundChanged => const Stream.empty();
}
