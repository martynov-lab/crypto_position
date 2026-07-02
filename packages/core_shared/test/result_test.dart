import 'package:core_shared/core_shared.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('map transforms Ok value and keeps Err untouched', () {
      const Result<int, String> ok = Ok(2);
      const Result<int, String> err = Err('boom');

      final mappedOk = ok.map((value) => value * 10);
      final mappedErr = err.map((value) => value * 10);

      expect(mappedOk, isA<Ok<int, String>>().having((r) => r.value, 'value', 20));
      expect(mappedErr, isA<Err<int, String>>().having((r) => r.error, 'error', 'boom'));
    });

    test('mapErr transforms Err error and keeps Ok untouched', () {
      const Result<int, String> ok = Ok(2);
      const Result<int, String> err = Err('boom');

      final mappedOk = ok.mapErr((error) => error.length);
      final mappedErr = err.mapErr((error) => error.length);

      expect(mappedOk, isA<Ok<int, int>>().having((r) => r.value, 'value', 2));
      expect(mappedErr, isA<Err<int, int>>().having((r) => r.error, 'error', 4));
    });

    test('fold calls ifOk for Ok and ifErr for Err', () {
      const Result<int, String> ok = Ok(2);
      const Result<int, String> err = Err('boom');

      expect(ok.fold((value) => 'ok:$value', (error) => 'err:$error'), 'ok:2');
      expect(err.fold((value) => 'ok:$value', (error) => 'err:$error'), 'err:boom');
    });

    test('supports pattern matching via switch', () {
      const Result<int, String> ok = Ok(42);

      final label = switch (ok) {
        Ok(:final value) => 'value=$value',
        Err(:final error) => 'error=$error',
      };

      expect(label, 'value=42');
    });
  });
}
