import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/presentation/home/exchange_account.dart';
import 'package:crypto_position/src/presentation/home/widgets/all_balances_view.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

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

Future<void> _pump(
  WidgetTester tester,
  PositionModel position, {
  Set<String> selectedKeys = const {},
  ValueChanged<String>? onToggleSelection,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: AllBalancesView(
        selectedKeys: selectedKeys,
        onToggleSelection: onToggleSelection,
        accounts: [
          ExchangeAccount(
            exchange: ExchangeId.bybit,
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

  group('AllBalancesView selection', () {
    testWidgets('long press reports the position key', (tester) async {
      final toggled = <String>[];
      await _pump(tester, _position(), onToggleSelection: toggled.add);

      await tester.longPress(find.text('BTCUSDT'));

      expect(toggled, ['bybit|BTCUSDT|Buy']);
    });

    testWidgets('a tap only toggles while a selection is active',
        (tester) async {
      final toggled = <String>[];
      await _pump(tester, _position(), onToggleSelection: toggled.add);

      await tester.tap(find.text('BTCUSDT'));
      expect(toggled, isEmpty);

      await _pump(
        tester,
        _position(),
        selectedKeys: const {'bybit|BTCUSDT|Buy'},
        onToggleSelection: toggled.add,
      );
      await tester.tap(find.text('BTCUSDT'));

      expect(toggled, ['bybit|BTCUSDT|Buy']);
    });

    testWidgets('marks the selected card', (tester) async {
      await _pump(tester, _position());
      expect(find.byIcon(AppIcons.check_circle_filled_24), findsNothing);

      await _pump(
        tester,
        _position(),
        selectedKeys: const {'bybit|BTCUSDT|Buy'},
      );

      expect(find.byIcon(AppIcons.check_circle_filled_24), findsOne);
    });
  });
}
