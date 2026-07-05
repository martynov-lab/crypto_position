import 'package:bybit/bybit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClosedTradeMapper', () {
    test('converts DTO to model with parsed numbers and dates', () {
      const dto = ClosedPnlDto(
        symbol: 'BTCUSDT',
        orderId: 'order-1',
        side: 'Sell',
        qty: '0.5',
        orderPrice: '61000.5',
        orderType: 'Market',
        avgEntryPrice: '60000',
        avgExitPrice: '61000',
        closedPnl: '500.25',
        leverage: '25',
        cumEntryValue: '30000',
        cumExitValue: '30500',
        createdTime: '1783160574265',
        updatedTime: '1783164723672',
      );

      final model = dto.toModel();

      expect(model.symbol, 'BTCUSDT');
      expect(model.side, 'Sell');
      expect(model.qty, 0.5);
      expect(model.orderPrice, 61000.5);
      expect(model.closedPnl, 500.25);
      expect(model.leverage, 25);
      expect(
        model.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1783160574265),
      );
      expect(
        model.updatedAt,
        DateTime.fromMillisecondsSinceEpoch(1783164723672),
      );
    });

    test('unparsable numbers and timestamps fall back to zero', () {
      const dto = ClosedPnlDto(
        symbol: 'X',
        orderId: '',
        side: 'Buy',
        qty: 'abc',
        orderPrice: '',
        orderType: '',
        avgEntryPrice: 'nan?',
        avgExitPrice: '',
        closedPnl: '',
        leverage: '',
        cumEntryValue: '',
        cumExitValue: '',
        createdTime: 'not-a-number',
        updatedTime: '',
      );

      final model = dto.toModel();

      expect(model.qty, 0);
      expect(model.orderPrice, 0);
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('fromJson fills missing keys with defaults', () {
      final dto = ClosedPnlDto.fromJson({'symbol': 'ETHUSDT'});

      expect(dto.symbol, 'ETHUSDT');
      expect(dto.orderId, '');
      expect(dto.qty, '0');
      expect(dto.createdTime, '0');
    });

    test('model getters mirror the legacy ClosedTrade', () {
      final win = ClosedPnlDto.fromJson({
        'symbol': 'X',
        'side': 'Buy',
        'closedPnl': '1',
      }).toModel();
      final loss = ClosedPnlDto.fromJson({
        'symbol': 'X',
        'side': 'Sell',
        'closedPnl': '-1',
      }).toModel();

      expect(win.isProfitable, isTrue);
      expect(win.tradeType, 'Закрыть шорт');
      expect(win.resultLabel, 'Успешная сделка');
      expect(loss.isProfitable, isFalse);
      expect(loss.tradeType, 'Закрыть лонг');
      expect(loss.resultLabel, 'Убыток');
    });
  });
}
