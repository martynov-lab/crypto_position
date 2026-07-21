import 'package:network/network.dart';

/// Never-give-up reconnect policy for the always-on screener stream.
///
/// Same ramp as [DefaultReconnectPolicy] (0s, 2s, 10s, 30s) but then holds at
/// 30s forever instead of returning `null`. The screener is a background feed
/// that must stay connected across focus loss and transient outages — over the
/// internet those are routine (mobile handovers, a container restart on
/// deploy), so it keeps retrying rather than stopping.
class PersistentReconnectPolicy implements RetryPolicy {
  static const _ramp = [
    Duration.zero,
    Duration(seconds: 2),
    Duration(seconds: 10),
  ];
  static const _steady = Duration(seconds: 30);

  const PersistentReconnectPolicy();

  @override
  Duration nextRetryDelay(RetryContext context) =>
      context.retryCount < _ramp.length ? _ramp[context.retryCount] : _steady;
}
