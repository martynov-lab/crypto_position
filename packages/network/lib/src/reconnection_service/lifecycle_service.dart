/// Reports whether the app is in the foreground.
abstract interface class LifecycleService {
  bool get isForeground;

  Stream<bool> get onForegroundChanged;
}
