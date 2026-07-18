import 'package:crypto_position/src/presentation/home/exchange_account.dart';
import 'package:crypto_position/src/presentation/home/widgets/all_balances_view.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PositionModel _position({
  double? upcomingFundingUsd,
  DateTime? nextFundingTime,
}) =>
    PositionModel(
      symbol: 'BTCUSDT',
      side: 'Buy',
      size: 0.1,
      avgPrice: 60000,
      markPrice: 62000,
      unrealisedPnl: 200,
      leverage: 10,
      upcomingFundingUsd: upcomingFundingUsd,
      nextFundingTime: nextFundingTime,
    );

Future<void> _pump(WidgetTester tester, PositionModel position) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AllBalancesView(
            accounts: [
              ExchangeAccount(
                name: 'Bybit',
                balance: const BalanceModel(
                  totalEquity: 1000,
                  totalWalletBalance: 1000,
                  coins: [],
                ),
                positions: [position],
              ),
            ],
          ),
        ),
      ),
    );

void main() {
  group('AllBalancesView position card', () {
    testWidgets('shows upcoming funding with its payout time', (tester) async {
      await _pump(
        tester,
        _position(
          upcomingFundingUsd: -0.62,
          nextFundingTime: DateTime(2026, 7, 15, 8, 5),
        ),
      );

      expect(find.text('Следующий фандинг · 08:05'), findsOne);
      expect(find.text('-0.62'), findsOne);
    });

    testWidgets('shows a dash when the exchange reports nothing',
        (tester) async {
      await _pump(tester, _position());

      expect(find.text('Следующий фандинг'), findsOne);
      expect(find.text('—'), findsOne);
    });
  });
}
