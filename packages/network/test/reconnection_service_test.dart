import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

class FakeLifecycle implements LifecycleService {
  final _controller = StreamController<bool>.broadcast();

  @override
  bool isForeground = true;

  @override
  Stream<bool> get onForegroundChanged => _controller.stream;

  void set(bool foreground) {
    isForeground = foreground;
    _controller.add(foreground);
  }
}

class FakeMonitor implements ConnectionMonitor {
  final _controller = StreamController<bool>.broadcast();

  @override
  bool hasNetwork = true;

  @override
  Stream<bool> get onNetworkChanged => _controller.stream;

  void set(bool network) {
    hasNetwork = network;
    _controller.add(network);
  }
}

void main() {
  group('ReconnectionService', () {
    const debounce = Duration(milliseconds: 20);
    late FakeLifecycle lifecycle;
    late FakeMonitor monitor;
    late ReconnectionService service;
    late int connectedRuns;
    late int disconnectedRuns;

    Future<void> settle() =>
        Future<void>.delayed(debounce + const Duration(milliseconds: 20));

    setUp(() {
      lifecycle = FakeLifecycle();
      monitor = FakeMonitor();
      service = ReconnectionService(
        lifecycleService: lifecycle,
        connectionMonitor: monitor,
        debounce: debounce,
      );
      connectedRuns = 0;
      disconnectedRuns = 0;
      service
        ..addOnConnectedAction(() async => connectedRuns++)
        ..addOnDisconnectedAction(() async => disconnectedRuns++);
    });

    tearDown(() => service.dispose());

    test('runs disconnected actions when the app goes to background',
        () async {
      lifecycle.set(false);
      await settle();

      expect(disconnectedRuns, 1);
      expect(connectedRuns, 0);
    });

    test('runs connected actions when app resumes with network', () async {
      lifecycle.set(false);
      await settle();
      lifecycle.set(true);
      await settle();

      expect(disconnectedRuns, 1);
      expect(connectedRuns, 1);
    });

    test('network loss disconnects, restore reconnects', () async {
      monitor.set(false);
      await settle();
      monitor.set(true);
      await settle();

      expect(disconnectedRuns, 1);
      expect(connectedRuns, 1);
    });

    test('debounces rapid flapping into a single transition', () async {
      lifecycle.set(false);
      lifecycle.set(true);
      lifecycle.set(false);
      await settle();

      expect(disconnectedRuns, 1);
    });

    test('duplicate states do not re-trigger actions', () async {
      lifecycle.set(false);
      await settle();
      monitor.set(false); // still inactive — no new transition
      await settle();

      expect(disconnectedRuns, 1);
    });

    test('removed actions stop running', () async {
      Future<void> action() async => connectedRuns++;
      service.addOnConnectedAction(action);
      service.removeOnConnectedAction(action);

      lifecycle.set(false);
      await settle();
      lifecycle.set(true);
      await settle();

      expect(connectedRuns, 1); // only the setUp action
    });
  });
}
