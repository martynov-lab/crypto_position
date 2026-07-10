import 'package:bitget/bitget.dart';
import 'package:network/network.dart';

/// Per-credentials Bitget connection graph: REST repository + WS managers
/// (private account stream and public ticker stream).
class BitgetAccountSession {
  final BitgetAccountRepository repository;
  final WsManager wsManager;
  final WsManager publicWsManager;
  final WsService _wsService;
  final WsService _publicWsService;

  BitgetAccountSession({
    required this.repository,
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
