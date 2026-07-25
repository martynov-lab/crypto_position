import 'package:crypto_position/src/presentation/screener/widgets/universe_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screener/screener.dart';

InstrumentCoverage _coverage(String base, List<String> exchanges) =>
    InstrumentCoverage(
      base: base,
      quote: 'USDT',
      exchanges: exchanges,
      coverage: exchanges.length,
    );

SummaryEntry _summary(String pair, String buy, String sell, String netPct) =>
    SummaryEntry(
      instrument: pair,
      buyExchange: buy,
      sellExchange: sell,
      netPct: netPct,
      coverage: 2,
    );

Future<InstrumentCoverage?> _pump(
  WidgetTester tester, {
  required List<InstrumentCoverage> universe,
  required List<SummaryEntry> summary,
  required Set<String> enabled,
}) async {
  InstrumentCoverage? tapped;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UniverseView(
          universe: ValueNotifier(universe),
          summary: ValueNotifier(summary),
          filters: ValueNotifier<Object?>(null),
          enabledExchanges: () => enabled,
          onRefresh: () async {},
          onTap: (_, coverage) => tapped = coverage,
        ),
      ),
    ),
  );
  return tapped;
}

void main() {
  group('UniverseView', () {
    testWidgets('hides coins left with fewer than two enabled venues',
        (tester) async {
      await _pump(
        tester,
        universe: [
          _coverage('ARB', ['bybit', 'kucoin']),
          _coverage('QNT', ['bybit', 'okx']),
        ],
        summary: const [],
        enabled: {'bybit', 'okx'},
      );

      expect(find.text('ARB/USDT'), findsNothing);
      expect(find.text('QNT/USDT'), findsOne);
      // Only the enabled venues are listed on the card.
      expect(find.widgetWithText(Chip, 'kucoin'), findsNothing);
    });

    testWidgets('shows the summary spread only when its pair is reachable',
        (tester) async {
      await _pump(
        tester,
        universe: [
          _coverage('ARB', ['bybit', 'okx', 'kucoin']),
          _coverage('QNT', ['bybit', 'okx']),
        ],
        summary: [
          // Best pair sits on a disabled venue → unreachable, no spread shown.
          _summary('ARB/USDT', 'kucoin', 'okx', '0.02'),
          _summary('QNT/USDT', 'bybit', 'okx', '0.01'),
        ],
        enabled: {'bybit', 'okx'},
      );

      expect(find.text('2.00%'), findsNothing);
      expect(find.text('1.00%'), findsOne);
      expect(find.text('купить bybit → продать okx'), findsOne);
    });

    testWidgets('sorts by spread first, coins without one last',
        (tester) async {
      await _pump(
        tester,
        universe: [
          _coverage('AAA', ['bybit', 'okx']),
          _coverage('BBB', ['bybit', 'okx']),
          _coverage('CCC', ['bybit', 'okx']),
        ],
        summary: [
          _summary('BBB/USDT', 'bybit', 'okx', '0.03'),
          _summary('CCC/USDT', 'bybit', 'okx', '0.01'),
        ],
        enabled: {'bybit', 'okx'},
      );

      final pairs = tester
          .widgetList<Text>(find.textContaining('/USDT'))
          .map((text) => text.data)
          .toList();
      expect(pairs, ['BBB/USDT', 'CCC/USDT', 'AAA/USDT']);
    });

    testWidgets('the clear button appears with a query and resets the list',
        (tester) async {
      await _pump(
        tester,
        universe: [
          _coverage('ARB', ['bybit', 'okx']),
          _coverage('QNT', ['bybit', 'okx']),
        ],
        summary: const [],
        enabled: {'bybit', 'okx'},
      );

      expect(find.byIcon(Icons.close), findsNothing);

      await tester.enterText(find.byType(TextField), 'ARB');
      await tester.pump();
      expect(find.text('QNT/USDT'), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.text('QNT/USDT'), findsOne);
      expect(find.text('ARB/USDT'), findsOne);
    });

    testWidgets('tapping a card reports the coin', (tester) async {
      InstrumentCoverage? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UniverseView(
              universe: ValueNotifier([
                _coverage('QNT', ['bybit', 'okx']),
              ]),
              summary: ValueNotifier(const []),
              filters: ValueNotifier<Object?>(null),
              enabledExchanges: () => {'bybit', 'okx'},
              onRefresh: () async {},
              onTap: (_, coverage) => tapped = coverage,
            ),
          ),
        ),
      );

      await tester.tap(find.text('QNT/USDT'));
      await tester.pump();

      expect(tapped?.pair, 'QNT/USDT');
    });
  });
}
