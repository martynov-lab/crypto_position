import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:network/network.dart';

/// Compact connection indicator for the screener stream, plus the latest
/// server error when present.
class ConnectionStatusBadge extends StatelessWidget {
  final ValueListenable<WsConnectionState> connectionState;
  final ValueListenable<String?> error;

  const ConnectionStatusBadge({
    super.key,
    required this.connectionState,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WsConnectionState>(
      valueListenable: connectionState,
      builder: (context, state, _) {
        final (color, label) = _describe(state);
        return ValueListenableBuilder<String?>(
          valueListenable: error,
          builder: (context, errorMessage, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  if (errorMessage != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  (Color, String) _describe(WsConnectionState state) => switch (state) {
        WsConnectionState.connected => (Colors.green, 'В сети'),
        WsConnectionState.connecting => (Colors.orange, 'Подключение…'),
        WsConnectionState.reconnecting => (Colors.orange, 'Переподключение…'),
        WsConnectionState.disconnected => (Colors.red, 'Отключено'),
      };
}
