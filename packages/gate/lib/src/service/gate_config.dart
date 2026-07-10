class GateConfig {
  final String baseRestUrl;

  /// USDT-settled futures WebSocket. Gate uses a single connection for both
  /// public (tickers) and private (positions) channels; auth is per
  /// subscription, not per connection.
  final String baseWsUrl;

  const GateConfig({
    this.baseRestUrl = 'https://api.gateio.ws',
    this.baseWsUrl = 'wss://fx-ws.gateio.ws/v4/ws/usdt',
  });
}
