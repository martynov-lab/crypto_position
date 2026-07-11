/// Location of the arbitrage screener server.
///
/// Local default per the integration guide (`config/default.toml`):
/// `127.0.0.1:8080`, plain `ws://`/`http://`.
class ScreenerConfig {
  final String host;
  final int port;
  final bool secure;

  const ScreenerConfig({
    this.host = '127.0.0.1',
    this.port = 8080,
    this.secure = false,
  });

  String get _httpScheme => secure ? 'https' : 'http';
  String get _wsScheme => secure ? 'wss' : 'ws';

  Uri get wsUri => Uri.parse('$_wsScheme://$host:$port/ws');
  String get baseRestUrl => '$_httpScheme://$host:$port';
}
