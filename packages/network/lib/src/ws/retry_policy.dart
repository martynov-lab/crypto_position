/// Context passed to [RetryPolicy] before each reconnect attempt.
class RetryContext {
  /// Number of retries already attempted since the last successful connection.
  final int retryCount;

  /// Time since the connection loss.
  final Duration elapsed;

  const RetryContext({required this.retryCount, required this.elapsed});
}

/// Decides the delay before the next reconnect attempt.
abstract interface class RetryPolicy {
  /// Returns the delay before the next attempt, or `null` to stop retrying.
  Duration? nextRetryDelay(RetryContext context);
}
