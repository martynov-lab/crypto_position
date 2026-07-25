import 'package:crypto_position/src/trade/position_close_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Bottom bar of the Main tab while positions are selected: the exit action
/// before the run, and the live phase of each position during it.
class ClosePositionsPanel extends StatelessWidget {
  final ValueListenable<Set<String>> selectedKeys;
  final ValueListenable<bool> busy;
  final ValueListenable<Map<String, CloseProgress>> progress;

  final VoidCallback onCancelSelection;
  final VoidCallback onAbort;
  final VoidCallback onClose;

  const ClosePositionsPanel({
    super.key,
    required this.selectedKeys,
    required this.busy,
    required this.progress,
    required this.onCancelSelection,
    required this.onAbort,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([selectedKeys, busy, progress]),
      builder: (context, _) {
        final selected = selectedKeys.value.length;
        final isBusy = busy.value;
        final steps = progress.value;
        // Selection is cleared the moment the run ends, so the panel has to stay
        // up while an exit is still in flight.
        if (selected == 0 && !isBusy) return const SizedBox.shrink();

        final theme = Theme.of(context);
        return Material(
          elevation: 8,
          color: theme.colorScheme.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final step in steps.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${step.symbol} · ${_phaseLabel(step)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  if (isBusy)
                    Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Выход из позиций…',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: onAbort,
                          child: const Text('Прекратить'),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.outlined(
                            label: 'Отмена',
                            onPressed: onCancelSelection,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'Выйти из позиций ($selected)',
                            onPressed: onClose,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _phaseLabel(CloseProgress step) => switch (step.phase) {
    ClosePhase.maker => 'лимит по лучшей цене',
    ClosePhase.chasing => 'перестановка ${step.attempt}',
    ClosePhase.taker => 'добор по рынку',
    ClosePhase.done => 'закрыта',
    ClosePhase.failed => step.message ?? 'не закрыта',
    ClosePhase.aborted => 'остановлено',
  };
}
