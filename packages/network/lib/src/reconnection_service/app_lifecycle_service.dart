import 'dart:async';

import 'package:flutter/widgets.dart';

import 'lifecycle_service.dart';

/// Foreground detection via [WidgetsBindingObserver].
class AppLifecycleService with WidgetsBindingObserver
    implements LifecycleService {
  final _controller = StreamController<bool>.broadcast();
  bool _isForeground = true;

  AppLifecycleService() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  bool get isForeground => _isForeground;

  @override
  Stream<bool> get onForegroundChanged => _controller.stream;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _isForeground) return;
    _isForeground = foreground;
    _controller.add(foreground);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.close();
  }
}
