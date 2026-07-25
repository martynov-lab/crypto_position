import 'package:crypto_position/src/trade/position_close_controller.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/material.dart';

/// Asks the user to confirm the exact orders about to be sent, and spells out
/// the strategy — the exit starts as a maker order but will cross the book if it
/// has to, which costs the taker fee.
Future<bool?> showCloseConfirmation(
  BuildContext context,
  List<ClosePlanItem> items,
  CloseTuning tuning,
) {
  final valid = items.where((i) => i.valid).toList();
  final invalid = items.where((i) => !i.valid).toList();
  final totalFee = valid.fold<double>(0, (sum, i) => sum + i.estFeeUsd);

  return showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: const Text('Подтвердите выход'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Будут выставлены реальные reduce-only ордера:'),
              const SizedBox(height: 8),
              for (final item in valid)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${item.exchange.label} ${item.symbol} ${item.side} → '
                    '${item.orderSide == OrderSide.sell ? 'SELL' : 'BUY'} '
                    '${_fmtQty(item.qty)} @ ${_fmtPrice(item.makerPrice)} '
                    'post-only',
                  ),
                ),
              for (final item in invalid)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${item.exchange.label} ${item.symbol} ${item.side} — '
                    '${item.invalidReason} (не будет закрыта)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Комиссия maker ≈ ${totalFee.toStringAsFixed(2)} \$, если ордер '
                'исполнится без добора.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Сначала лимит по лучшей цене; если цена уходит — до '
                '${tuning.maxRepriceAttempts} перестановок, через '
                '${tuning.deadline.inSeconds} с — добор по рынку '
                '(${_fmtPct(tuning.takerBufferPct)}% через книгу, комиссия '
                'taker).',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: valid.isEmpty
                ? null
                : () => Navigator.of(context).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      );
    },
  );
}

/// Shows how each exit ended. A position that is only partly closed is called
/// out explicitly — the app must never imply a flat position it can't confirm.
Future<void> showCloseReport(BuildContext context, CloseReport report) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final unclosed = report.unclosed;
      return AlertDialog(
        title: Text(report.ok ? 'Позиции закрыты' : 'Выход завершён частично'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in report.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${item.exchange.label} ${item.symbol} — '
                    '${_outcomeLabel(item)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: item.ok ? null : Colors.red,
                    ),
                  ),
                ),
              if (unclosed.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Проверьте оставшиеся позиции на бирже.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Понятно'),
          ),
        ],
      );
    },
  );
}

String _outcomeLabel(CloseOutcome item) {
  if (item.ok) {
    return item.tookLiquidity ? 'закрыта (добор по рынку)' : 'закрыта (maker)';
  }
  final remaining = item.remainingQty > 0
      ? ', остаток ${_fmtQty(item.remainingQty)}'
      : '';
  return '${item.message ?? 'не закрыта'}$remaining';
}

String _fmtQty(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(4);
}

String _fmtPrice(double v) {
  if (v >= 100) return v.toStringAsFixed(2);
  return v.toStringAsFixed(6);
}

String _fmtPct(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
