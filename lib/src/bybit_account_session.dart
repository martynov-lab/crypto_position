import 'package:bybit/bybit.dart';
import 'package:network/network.dart';

/// Per-credentials Bybit connection graph: REST repository + WS manager.
class BybitAccountSession {
  final BybitAccountRepository repository;
  final WsManager wsManager;
  final WsService _wsService;

  BybitAccountSession({
    required this.repository,
    required this.wsManager,
    required WsService wsService,
  }) : _wsService = wsService;

  void dispose() {
    wsManager.dispose();
    _wsService.dispose();
    repository.dispose();
  }
}
