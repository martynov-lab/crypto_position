/// The exchanges the app can connect to, used as a stable key across the
/// market-data providers, the fee store and the arbitrage UI.
enum ExchangeId {
  bybit('bybit', 'Bybit'),
  okx('okx', 'OKX'),
  bitget('bitget', 'Bitget'),
  gate('gate', 'Gate'),
  mexc('mexc', 'MEXC');

  /// Stable storage/wire key.
  final String key;

  /// Human-facing label for dropdowns and labels.
  final String label;

  const ExchangeId(this.key, this.label);
}
