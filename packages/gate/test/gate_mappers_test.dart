import 'package:gate/gate.dart';
// These are internal to the package (like OKX's history); import directly.
import 'package:gate/src/api/dto/position_close_dto.dart';
import 'package:gate/src/api/mappers/closed_trade_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GateAccountDto', () {
    test('parses the account id the positions subscription needs', () {
      // The balance fields alongside it are ignored on purpose: they cover the
      // futures wallet only.
      final dto = GateAccountDto.fromJson({
        'user': 42,
        'currency': 'USDT',
        'total': '1500.25',
      });

      expect(dto.user, 42);
    });
  });

  group('GateTotalBalanceMapper', () {
    test('maps the converted whole-account total', () {
      final model = TotalBalanceDto.fromJson({
        'details': {
          'spot': {'currency': 'USDT', 'amount': '189.65'},
          'futures': {'currency': 'USDT', 'amount': '0.0004'},
        },
        'total': {
          'currency': 'USDT',
          'amount': '189.6504',
          'unrealised_pnl': '2.5',
        },
      }).toModel();

      expect(model.totalEquity, 189.6504);
      expect(model.totalWalletBalance, 189.6504);
      expect(model.coins.single.coin, 'USDT');
      expect(model.coins.single.walletBalance, 189.6504);
      expect(model.coins.single.unrealisedPnl, 2.5);
    });

    test('treats an omitted unrealised_pnl as zero', () {
      final model = TotalBalanceDto.fromJson({
        'total': {'currency': 'USDT', 'amount': '10'},
      }).toModel();

      expect(model.totalWalletBalance, 10);
      expect(model.coins.single.unrealisedPnl, 0);
    });
  });

  group('PositionMapper', () {
    test('derives side from size sign and base qty from value/mark', () {
      // A short: size negative, value = |qty| * mark. qty = |value|/mark = 0.02.
      final model = PositionDto.fromJson({
        'contract': 'BTC_USDT',
        'size': -200,
        'leverage': '10',
        'entry_price': '60000',
        'mark_price': '59000',
        'unrealised_pnl': '20',
        'value': '1180', // 0.02 * 59000
      }).toModel();

      expect(model.symbol, 'BTC_USDT');
      expect(model.side, 'short');
      expect(model.size, closeTo(0.02, 1e-9));
      expect(model.avgPrice, 60000);
      expect(model.leverage, 10);
    });

    test('long position keeps side long', () {
      final model = PositionDto.fromJson({
        'contract': 'ETH_USDT',
        'size': 5,
        'mark_price': '3000',
        'value': '150',
      }).toModel();

      expect(model.side, 'long');
      expect(model.size, closeTo(0.05, 1e-9));
    });
  });

  group('ClosedTradeMapper', () {
    test('closing a long reads as a Sell; entry=long_price, exit=short_price',
        () {
      final model = PositionCloseDto.fromJson({
        'time': 1700000000.5,
        'contract': 'BTC_USDT',
        'side': 'long',
        'pnl': '123.5',
        'accum_size': '10',
        'long_price': '60000',
        'short_price': '61000',
      }).toModel();

      expect(model.symbol, 'BTC_USDT');
      expect(model.side, 'Sell');
      expect(model.avgEntryPrice, 60000);
      expect(model.avgExitPrice, 61000);
      expect(model.closedPnl, 123.5);
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000500));
    });

    test('closing a short reads as a Buy; entry/exit prices swap', () {
      final model = PositionCloseDto.fromJson({
        'time': 1700000000,
        'contract': 'ETH_USDT',
        'side': 'short',
        'pnl': '-10',
        'accum_size': '3',
        'long_price': '3100',
        'short_price': '3000',
      }).toModel();

      expect(model.side, 'Buy');
      expect(model.avgEntryPrice, 3000);
      expect(model.avgExitPrice, 3100);
    });
  });
}
