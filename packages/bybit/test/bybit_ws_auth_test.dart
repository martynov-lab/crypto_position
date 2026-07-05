import 'package:bybit/bybit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bybitWsAuthMessage', () {
    test('builds the Bybit auth op with a deterministic HMAC signature', () {
      final message = bybitWsAuthMessage(
        apiKey: 'my-key',
        apiSecret: 'my-secret',
        expires: 1700000000000,
      );

      expect(message['op'], 'auth');
      final args = message['args']! as List<Object?>;
      expect(args[0], 'my-key');
      expect(args[1], 1700000000000);
      final signature = args[2]! as String;
      expect(signature, matches(RegExp(r'^[0-9a-f]{64}$')));

      // Known-answer vector pinning the exact HMAC input format.
      expect(
        signature,
        'c859e630d1361140ab72bd40eb07676ceb64447c23924925717c346297b22af4',
      );

      // Deterministic: same inputs produce the same signature.
      final again = bybitWsAuthMessage(
        apiKey: 'my-key',
        apiSecret: 'my-secret',
        expires: 1700000000000,
      );
      expect((again['args']! as List<Object?>)[2], signature);

      // Signature depends on the secret.
      final other = bybitWsAuthMessage(
        apiKey: 'my-key',
        apiSecret: 'other-secret',
        expires: 1700000000000,
      );
      expect((other['args']! as List<Object?>)[2], isNot(signature));
    });

    test('defaults expires to roughly now + 60 seconds', () {
      final before = DateTime.now().millisecondsSinceEpoch + 60000;
      final message = bybitWsAuthMessage(apiKey: 'k', apiSecret: 's');
      final after = DateTime.now().millisecondsSinceEpoch + 60000;

      final expires = (message['args']! as List<Object?>)[1]! as int;
      expect(expires, inInclusiveRange(before, after));
    });
  });
}
