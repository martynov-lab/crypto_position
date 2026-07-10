import 'package:mexc/mexc.dart';
// Closed-trade history is internal to the package (like OKX); import directly.
import 'package:mexc/src/api/dto/history_position_dto.dart';
import 'package:mexc/src/api/mappers/closed_trade_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MexcBalanceMapper', () {
    test('uses the USDT asset equity as the account total', () {
      final model = MexcBalanceDto([
        AssetDto.fromJson({
          'currency': 'USDT',
          'equity': 1500.5,
          'availableBalance': 1400,
          'unrealized': 25,
        }),
        AssetDto.fromJson({'currency': 'BTC', 'equity': 0.1}),
      ]).toModel();

      expect(model.totalEquity, 1500.5);
      expect(model.totalWalletBalance, 1500.5);
      expect(model.coins, hasLength(2));
    });
  });

  group('PositionMapper', () {
    test('applies contractSize and maps positionType to side', () {
      // 100 contracts * 0.0001 = 0.01 base; positionType 2 = short.
      final model = PositionDto.fromJson({
        'symbol': 'BTC_USDT',
        'holdVol': 100,
        'holdAvgPrice': 60000,
        'positionType': 2,
        'leverage': 20,
        'state': 1,
      }).toModel(0.0001);

      expect(model.symbol, 'BTC_USDT');
      expect(model.side, 'short');
      expect(model.size, closeTo(0.01, 1e-12));
      expect(model.avgPrice, 60000);
      expect(model.leverage, 20);
    });
  });

  group('ClosedTradeMapper', () {
    test('closing a long reads as Sell; close time from updateTime (ms)', () {
      final model = HistoryPositionDto.fromJson({
        'symbol': 'BTC_USDT',
        'positionType': 1,
        'openAvgPrice': 60000,
        'closeAvgPrice': 61000,
        'closeVol': 100,
        'realised': 123.5,
        'leverage': 20,
        'updateTime': 1783164723672,
      }).toModel(0.0001);

      expect(model.symbol, 'BTC_USDT');
      expect(model.side, 'Sell');
      expect(model.qty, closeTo(0.01, 1e-12));
      expect(model.closedPnl, 123.5);
      expect(
        model.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1783164723672),
      );
    });
  });
}
