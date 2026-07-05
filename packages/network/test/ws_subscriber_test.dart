import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

void main() {
  group('WsSubscriber', () {
    test('maps handled json to typed events on the stream', () async {
      final subscriber = WsSubscriber<String>(
        'wallet',
        (json) => json['name']! as String,
      );
      final events = <String>[];
      subscriber.stream.listen(events.add);

      subscriber.handle({'name': 'neo'});
      subscriber.handle({'name': 'trinity'});
      await Future<void>.delayed(Duration.zero);

      expect(events, ['neo', 'trinity']);
      subscriber.dispose();
    });

    test('skips elements the mapper cannot parse without breaking the stream',
        () async {
      final subscriber = WsSubscriber<String>(
        'wallet',
        (json) => json['name']! as String,
      );
      final events = <String>[];
      final errors = <Object>[];
      subscriber.stream.listen(events.add, onError: errors.add);

      subscriber.handle({'wrong': 'shape'}); // mapper throws
      subscriber.handle({'name': 'neo'});
      await Future<void>.delayed(Duration.zero);

      expect(events, ['neo']);
      expect(errors, isEmpty);
      subscriber.dispose();
    });

    test('stream is broadcast (supports multiple listeners)', () {
      final subscriber = WsSubscriber<int>('wallet', (json) => 1);

      expect(subscriber.stream.isBroadcast, isTrue);
      subscriber.stream.listen((_) {});
      subscriber.stream.listen((_) {});
      subscriber.dispose();
    });
  });
}
