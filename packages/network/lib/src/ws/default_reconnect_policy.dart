import 'retry_policy.dart';

/// Retry delays 0s, 2s, 10s, 30s, then give up.
class DefaultReconnectPolicy implements RetryPolicy {
  static const _delays = [
    Duration.zero,
    Duration(seconds: 2),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ];

  const DefaultReconnectPolicy();

  @override
  Duration? nextRetryDelay(RetryContext context) =>
      context.retryCount < _delays.length ? _delays[context.retryCount] : null;
}
