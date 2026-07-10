class MexcConfig {
  final String baseRestUrl;

  /// Contract WebSocket. One connection carries private personal pushes (after
  /// login) and public ticker subscriptions; the app opens a private
  /// (logged-in) manager and a public one against the same URL.
  final String baseWsUrl;

  const MexcConfig({
    this.baseRestUrl = 'https://contract.mexc.com',
    this.baseWsUrl = 'wss://contract.mexc.com/edge',
  });
}
