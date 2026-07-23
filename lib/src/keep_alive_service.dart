import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Android-only keep-alive: a dataSync foreground service that exempts the
/// process from background freezing, so the exchange/screener sockets (and
/// with them notifications) keep working while the app is backgrounded.
///
/// No task callback is registered — the point is only to keep the main
/// isolate's connections alive. No-op on other platforms.
class KeepAliveService {
  Future<void> start() async {
    if (!Platform.isAndroid) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'crypto_position_keep_alive',
        channelName: 'Background streaming',
        channelDescription:
            'Keeps exchange and screener connections alive in background',
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
      ),
    );
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceTypes: const [ForegroundServiceTypes.dataSync],
      notificationTitle: 'Crypto Position',
      notificationText: 'Streaming positions & signals',
    );
  }
}
