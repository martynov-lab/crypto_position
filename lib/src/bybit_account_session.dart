import 'package:bybit/bybit.dart';
import 'package:exchange/exchange.dart';
import 'package:network/network.dart';

/// Per-credentials Bybit connection graph: REST repository + WS managers
/// (private account stream and public ticker stream).
class BybitAccountSession {
  final BybitAccountRepository repository;

  /// Order placement over the same signed REST client.
  final TradeExecutor tradeExecutor;
  final WsManager wsManager;
  final WsManager publicWsManager;
  final WsService _wsService;
  final WsService _publicWsService;

  BybitAccountSession({
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
