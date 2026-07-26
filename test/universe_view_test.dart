import 'package:crypto_position/src/presentation/screener/widgets/universe_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screener/screener.dart';
import 'package:ui_kit/ui_kit.dart';

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

/// In-memory stand-in for the persisted favourites store.
class _Favorites extends ChangeNotifier {
  final Set<String> pairs;

  _Favorites([Set<String>? pairs]) : pairs = pairs ?? {};

  bool contains(String pair) => pairs.contains(pair);

  void toggle(String pair) {
    if (!pairs.remove(pair)) pairs.add(pair);
    notifyListeners();
  }
}

Future<InstrumentCoverage?> _pump(
  WidgetTester tester, {
  required List<InstrumentCoverage> universe,
  required List<SummaryEntry> summary,
  required Set<String> enabled,
  _Favorites? favorites,
}) async {
  final starred = favorites ?? _Favorites();
  InstrumentCoverage? tapped;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UniverseView(
          universe: ValueNotifier(universe),
          summary: ValueNotifier(summary),
          filters: ValueNotifier<Object?>(null),
          enabledExchanges: () => enabled,
          favorites: starred,
          isFavorite: starred.contains,
          onToggleFavorite: starred.toggle,
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
      final starred = _Favorites();
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
              favorites: starred,
              isFavorite: starred.contains,
              onToggleFavorite: starred.toggle,
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

    testWidgets('the star toggles the coin and swaps the icon', (tester) async {
      final starred = _Favorites();
      await _pump(
        tester,
        universe: [
          _coverage('QNT', ['bybit', 'okx']),
        ],
        summary: const [],
        enabled: {'bybit', 'okx'},
        favorites: starred,
      );

      expect(find.byIcon(AppIcons.star_outlined_24), findsOne);

      await tester.tap(find.byIcon(AppIcons.star_outlined_24));
      await tester.pump();

      expect(starred.pairs, {'QNT/USDT'});
      expect(find.byIcon(AppIcons.star_filled_24), findsOne);
      expect(find.byIcon(AppIcons.star_outlined_24), findsNothing);
    });

    testWidgets('the favourites filter keeps only starred coins',
        (tester) async {
      await _pump(
        tester,
        universe: [
          _coverage('ARB', ['bybit', 'okx']),
          _coverage('QNT', ['bybit', 'okx']),
        ],
        summary: const [],
        enabled: {'bybit', 'okx'},
        favorites: _Favorites({'QNT/USDT'}),
      );

      await tester.tap(find.widgetWithText(FilterChip, 'Избранные'));
      await tester.pump();

      expect(find.text('QNT/USDT'), findsOne);
      expect(find.text('ARB/USDT'), findsNothing);
    });

    testWidgets('the favourites filter reports an empty set', (tester) async {
      await _pump(
        tester,
        universe: [
          _coverage('QNT', ['bybit', 'okx']),
        ],
        summary: const [],
        enabled: {'bybit', 'okx'},
      );

      await tester.tap(find.widgetWithText(FilterChip, 'Избранные'));
      await tester.pump();

      expect(find.text('Нет избранных монет'), findsOne);
    });
  });
}
