import '../dto/transaction_log_dto.dart';

/// Trading fee and funding totals over one position's life.
///
/// [commission] is positive when fees were paid; [funding] follows the
/// account's point of view, negative when funding was paid out.
typedef PositionFees = ({double commission, double funding});

const emptyPositionFees = (commission: 0.0, funding: 0.0);

extension TransactionLogAggregator on List<TransactionLogDto> {
  /// Sums the `TRADE` fees and `SETTLEMENT` funding logged for [symbol] at or
  /// after [since] — i.e. over the current position's life. Entries from an
  /// earlier position on the same symbol are excluded by [since].
  PositionFees feesFor(String symbol, DateTime since) {
    var commission = 0.0;
    var funding = 0.0;

    for (final entry in this) {
      if (entry.symbol != symbol) continue;

      final ms = int.tryParse(entry.transactionTime);
      if (ms == null || ms < since.millisecondsSinceEpoch) continue;

      switch (entry.type) {
        case 'TRADE':
          commission += _parseAmount(entry.fee);
        case 'SETTLEMENT':
          funding += _parseAmount(entry.funding);
      }
    }

    return (commission: commission, funding: funding);
  }
}

/// Bybit returns '' for fields that do not apply to an entry's type.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);
