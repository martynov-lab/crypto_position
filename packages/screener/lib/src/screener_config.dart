/// Location of (and credential for) the arbitrage screener server.
///
/// Both are build-time settings so neither the host nor the token is hardcoded
/// in the source or committed:
///
/// ```
/// flutter run --dart-define=ARB_HOST=arovit-screener.duckdns.org \
///             --dart-define=ARB_TOKEN=<token>
/// ```
///
/// Point it at a dev server with `--dart-define=ARB_HOST=127.0.0.1:8080`.
class ScreenerConfig {
  /// Deployed host by default; override for a local server.
  static const defaultHost = String.fromEnvironment(
    'ARB_HOST',
    defaultValue: 'arovit-screener.duckdns.org',
  );

  /// `ARB_AUTH_TOKEN` from the server's env. Empty = send no token (a local
  /// server without auth).
  static const defaultToken = String.fromEnvironment('ARB_TOKEN');

  /// Host, optionally with a port (`127.0.0.1:8080`). The deployed server is
  /// on 443, so its URLs carry no port.
  final String host;
  final String token;

  const ScreenerConfig({this.host = defaultHost, this.token = defaultToken});

  /// TLS everywhere except loopback. This is not cosmetic: the reverse proxy
  /// answers a plain `ws://` with a redirect to 443 instead of upgrading the
  /// connection, so the socket never opens.
  bool get secure =>
      !host.startsWith('127.0.0.1') && !host.startsWith('localhost');

  Uri get wsUri => Uri.parse('${secure ? 'wss' : 'ws'}://$host/ws');
  String get baseRestUrl => '${secure ? 'https' : 'http'}://$host';
}
