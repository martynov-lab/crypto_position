import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local (on-device) notifications for new positions and screener signals.
///
/// Works as long as the app process is alive: always on Windows, and on
/// Android while the keep-alive foreground service is running.
class NotificationService {
  static const _channelId = 'crypto_position_events';
  static const _channelName = 'Positions & signals';

  /// Fixed ids so a newer notification of the same kind replaces the previous
  /// one instead of piling up.
  static const positionsNotificationId = 1;
  static const signalsNotificationId = 2;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        windows: WindowsInitializationSettings(
          appName: 'Crypto Position',
          appUserModelId: 'CryptoPosition.CryptoPosition',
          guid: '7a9569b4-1e8a-4ea9-886b-7b350049c7fa',
        ),
      ),
    );
    _ready = initialized ?? false;
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
