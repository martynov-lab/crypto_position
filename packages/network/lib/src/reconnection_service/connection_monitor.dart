/// Reports whether the device has network connectivity.
abstract interface class ConnectionMonitor {
  bool get hasNetwork;

  Stream<bool> get onNetworkChanged;
}
