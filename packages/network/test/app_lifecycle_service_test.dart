import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLifecycleService', () {
    test('starts in the foreground', () {
      final service = AppLifecycleService();

      expect(service.isForeground, isTrue);
      service.dispose();
    });

    test('paused -> background, resumed -> foreground, with stream events',
        () async {
      final service = AppLifecycleService();
      final events = <bool>[];
      service.onForegroundChanged.listen(events.add);

      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(events, [false, true]);
      expect(service.isForeground, isTrue);
      service.dispose();
    });

    test('duplicate states emit no events', () async {
      final service = AppLifecycleService();
      final events = <bool>[];
      service.onForegroundChanged.listen(events.add);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
      service.dispose();
    });
  });
}
