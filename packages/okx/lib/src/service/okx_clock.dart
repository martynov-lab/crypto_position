/// Holds the offset between the local clock and OKX server time.
///
/// OKX rejects signed requests whose `OK-ACCESS-TIMESTAMP` differs from server
/// time by more than ~30s (error 50102). The local machine clock can drift
/// beyond that window, so [OkxAuthInterceptor] signs with [nowMs] instead of
/// the raw local time. [offsetMs] is refreshed from the public server-time
/// endpoint on connect (see `OkxAccountRepository.syncServerTime`).
class OkxClock {
  /// serverTime - localTime, in milliseconds. Zero until the first sync, so
  /// requests fall back to local time when the offset is unknown.
  int offsetMs = 0;

  /// Current time corrected to OKX server time.
  int nowMs() => DateTime.now().millisecondsSinceEpoch + offsetMs;
}
