import 'package:crypto_position/src/presentation/screener/widgets/signals_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screener/screener.dart';

const _instrument = Instrument(base: 'ARB', quote: 'USDT', kind: 'perp');

SignalEvent _signal(String netPct) => SignalEvent(
      spread: Spread(
        instrument: _instrument,
        buyExchange: 'bybit',
        sellExchange: 'okx',
        vwapBuy: '1',
        vwapSell: '1.01',
        grossPct: '0.01',
        netPct: netPct,
        roundTripPct: '0.004',
        outPct: '-0.001',
        fundingCostPct: '0',
        expectedProfitQuote: '4',
        legSkewMs: 10,
        executableNotional: '1000',
        cappedByDepth: false,
      ),
      tsMs: DateTime.now().millisecondsSinceEpoch,
    );

SummaryEntry _summary(String netPct) => SummaryEntry(
      instrument: 'ARB/USDT',
      buyExchange: 'bybit',
      sellExchange: 'okx',
      netPct: netPct,
      coverage: 2,
    );

Future<void> _pump(
  WidgetTester tester, {
  required List<SignalEvent> signals,
  required List<SummaryEntry> summary,
  void Function(double? entrySpreadPct)? onTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SignalsView(
          signals: ValueNotifier(signals),
          summary: ValueNotifier(summary),
          onRefresh: () async {},
          configOf: () => const ClientConfig(),
          onTap: (_, _, _, _, entrySpreadPct) => onTap?.call(entrySpreadPct),
        ),
      ),
    ),
  );
}

void main() {
  group('SignalsView', () {
    testWidgets("shows the current spread next to the signal's own",
        (tester) async {
      await _pump(
        tester,
        signals: [_signal('0.0082')],
        summary: [_summary('0.0042')],
      );

      expect(find.text('вход сейчас 0.42%'), findsOne);
      expect(find.text('в сигнале 0.82%'), findsOne);
    });

    testWidgets('falls back to the signal spread without a summary row',
        (tester) async {
      await _pump(tester, signals: [_signal('0.0082')], summary: const []);

      expect(find.text('вход 0.82%'), findsOne);
      expect(find.textContaining('в сигнале'), findsNothing);
    });

    testWidgets("opens the coin with the current spread, not the signal's",
        (tester) async {
      double? tapped;
      await _pump(
        tester,
        signals: [_signal('0.0082')],
        summary: [_summary('0.0042')],
        onTap: (entrySpreadPct) => tapped = entrySpreadPct,
      );

      await tester.tap(find.text('ARB/USDT'));
      await tester.pump();

      expect(tapped, 0.42);
    });
  });
}
