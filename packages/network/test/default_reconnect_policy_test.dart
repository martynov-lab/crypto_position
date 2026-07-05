import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

void main() {
  group('DefaultReconnectPolicy', () {
    const policy = DefaultReconnectPolicy();

    Duration? delayFor(int retryCount) => policy.nextRetryDelay(
          RetryContext(retryCount: retryCount, elapsed: Duration.zero),
        );

    test('returns 0s, 2s, 10s, 30s for the first four retries', () {
      expect(delayFor(0), Duration.zero);
      expect(delayFor(1), const Duration(seconds: 2));
      expect(delayFor(2), const Duration(seconds: 10));
      expect(delayFor(3), const Duration(seconds: 30));
    });

    test('returns null after the fourth retry (give up)', () {
      expect(delayFor(4), isNull);
      expect(delayFor(10), isNull);
    });
  });
}
