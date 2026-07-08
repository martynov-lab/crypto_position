class OkxConfig {
  final String baseRestUrl;
  final String baseWsUrl;
  final String basePublicWsUrl;

  /// Routes REST/WS to OKX's demo (paper trading) environment. Demo REST
  /// requests additionally carry the `x-simulated-trading: 1` header.
  final bool demoTrading;

  const OkxConfig({
    this.baseRestUrl = 'https://www.okx.com',
    this.baseWsUrl = 'wss://ws.okx.com:8443/ws/v5/private',
    this.basePublicWsUrl = 'wss://ws.okx.com:8443/ws/v5/public',
    this.demoTrading = false,
  });

  const OkxConfig.demo()
    : baseRestUrl = 'https://www.okx.com',
      baseWsUrl = 'wss://wspap.okx.com:8443/ws/v5/private',
      basePublicWsUrl = 'wss://wspap.okx.com:8443/ws/v5/public',
      demoTrading = true;
}
