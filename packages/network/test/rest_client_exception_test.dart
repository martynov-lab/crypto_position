import 'package:network/network.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RestClientException hierarchy', () {
    test('all subclasses are RestClientException and Exception', () {
      const exceptions = <RestClientException>[
        ClientException(message: 'client'),
        ConnectionException(message: 'connection'),
        CustomBackendException(message: 'backend', error: {'detail': 'oops'}),
        InternalServerException(message: 'server', statusCode: 500),
        WrongResponseTypeException(message: 'type'),
      ];

      for (final exception in exceptions) {
        expect(exception, isA<Exception>());
      }
    });

    test('CustomBackendException exposes the server error map', () {
      const exception = CustomBackendException(
        message: 'backend',
        error: {'detail': 'oops'},
        statusCode: 400,
      );

      expect(exception.error, {'detail': 'oops'});
      expect(exception.statusCode, 400);
    });

    test('toString contains message and statusCode', () {
      const exception = ClientException(message: 'bad request', statusCode: 400);

      expect(exception.toString(), contains('bad request'));
      expect(exception.toString(), contains('400'));
    });
  });
}
