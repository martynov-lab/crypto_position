import 'package:gate/gate.dart';
import 'package:network/network.dart';

/// Per-credentials Gate connection graph: REST repository + a single WS manager
/// carrying both the private positions channel and the public ticker channels
/// (Gate authenticates per subscription, so one connection serves both).
class GateAccountSession {
  final GateAccountRepository repository;
  final WsManager wsManager;
  final GateWsProtocol _protocol;
  final WsService _wsService;

  GateAccountSession({
    required this.repository,
    required this.wsManager,
    required GateWsProtocol protocol,
    required WsService wsService,
  })  : _protocol = protocol,
        _wsService = wsService;

  Future<void> startWs() async {
    // Gate needs the numeric account id in the positions subscription payload;
    // it is learned from the REST balance call that runs before startWs.
    _protocol.userId = repository.userId;
    await wsManager.start();
  }

  Future<void> stopWs() async {
    await wsManager.stop();
  }

  void dispose() {
    wsManager.dispose();
    _wsService.dispose();
    repository.dispose();
  }
}
