import 'package:bitget/bitget.dart';
// Closed-trade history is internal to the package (like OKX); import directly.
import 'package:bitget/src/api/dto/position_history_dto.dart';
import 'package:bitget/src/api/mappers/closed_trade_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BitgetBalanceMapper', () {
    test('sums USDT equity across accounts into the total', () {
      final dto = BitgetBalanceDto([
        BitgetAccountDto.fromJson({
          'marginCoin': 'USDT',
          'usdtEquity': '1250.5',
          'available': '1000',
          'unrealizedPL': '50.5',
        }),
      ]);

      final model = dto.toModel();

      expect(model.totalEquity, 1250.5);
      expect(model.totalWalletBalance, 1250.5);
      expect(model.coins.single.coin, 'USDT');
      expect(model.coins.single.walletBalance, 1000);
      expect(model.coins.single.unrealisedPnl, 50.5);
    });
  });

  group('PositionMapper', () {
    test('maps a REST position and keeps holdSide as the native word', () {
      final model = PositionDto.fromJson({
        'symbol': 'BTCUSDT',
        'holdSide': 'short',
        'total': '0.5',
        'openPriceAvg': '60000',
        'markPrice': '59000',
        'unrealizedPL': '500',
        'leverage': '20',
      }).toModel();

      expect(model.symbol, 'BTCUSDT');
      expect(model.side, 'short');
      expect(model.size, 0.5);
      expect(model.avgPrice, 60000);
      expect(model.leverage, 20);
    });

    test('falls back to instId when the WS frame omits symbol', () {
      final model = PositionDto.fromJson({
        'instId': 'ETHUSDT',
        'holdSide': 'long',
        'total': '2',
      }).toModel();

      expect(model.symbol, 'ETHUSDT');
    });
  });

  group('ClosedTradeMapper', () {
    test('maps a closed position; closing a short reads as a Buy', () {
      final model = PositionHistoryDto.fromJson({
        'symbol': 'BTCUSDT',
        'holdSide': 'short',
        'openAvgPrice': '60000',
        'closeAvgPrice': '59000',
        'closeTotalPos': '0.5',
        'netProfit': '500',
        'leverage': '20',
        'utime': '1783164723672',
      }).toModel();

      expect(model.symbol, 'BTCUSDT');
      expect(model.side, 'Buy');
      expect(model.closedPnl, 500);
      expect(model.qty, 0.5);
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(1783164723672));
    });
  });
}
