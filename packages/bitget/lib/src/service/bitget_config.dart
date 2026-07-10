class BitgetConfig {
  final String baseRestUrl;

  /// Private (authenticated) WebSocket stream: account + positions.
  final String baseWsUrl;

  /// Public WebSocket stream: per-symbol ticker (mark price) for live PnL.
  final String basePublicWsUrl;

  const BitgetConfig({
    this.baseRestUrl = 'https://api.bitget.com',
    this.baseWsUrl = 'wss://ws.bitget.com/v2/ws/private',
    this.basePublicWsUrl = 'wss://ws.bitget.com/v2/ws/public',
  });
}
