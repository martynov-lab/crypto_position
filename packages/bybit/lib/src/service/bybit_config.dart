class BybitConfig {
  final String baseRestUrl;
  final String baseWsUrl;
  final String basePublicWsUrl;
  final int recvWindow;

  const BybitConfig({
    this.baseRestUrl = 'https://api.bybit.com',
    this.baseWsUrl = 'wss://stream.bybit.com/v5/private',
    this.basePublicWsUrl = 'wss://stream.bybit.com/v5/public/linear',
    this.recvWindow = 20000,
  });

  const BybitConfig.testnet()
    : baseRestUrl = 'https://api-testnet.bybit.com',
      baseWsUrl = 'wss://stream-testnet.bybit.com/v5/private',
      basePublicWsUrl = 'wss://stream-testnet.bybit.com/v5/public/linear',
      recvWindow = 20000;
}
