import 'package:exchange/exchange.dart';
import 'package:mexc/mexc.dart';
import 'package:network/network.dart';

/// Per-credentials MEXC connection graph: REST repository + WS managers
/// (private personal stream after login and public ticker stream).
class MexcAccountSession {
  final MexcAccountRepository repository;

  /// Order placement over the same signed REST client.
  final TradeExecutor tradeExecutor;
  final WsManager wsManager;
  final WsManager publicWsManager;
  final WsService _wsService;
  final WsService _publicWsService;

  MexcAccountSession({
    required this.repository,
    required this.tradeExecutor,
    required this.wsManager,
    required this.publicWsManager,
    required WsService wsService,
    required WsService publicWsService,
  })  : _wsService = wsService,
        _publicWsService = publicWsService;

  Future<void> startWs() async {
    await Future.wait([wsManager.start(), publicWsManager.start()]);
  }

  Future<void> stopWs() async {
    await Future.wait([wsManager.stop(), publicWsManager.stop()]);
  }

  void dispose() {
    wsManager.dispose();
    publicWsManager.dispose();
    _wsService.dispose();
    _publicWsService.dispose();
    repository.dispose();
  }
}
