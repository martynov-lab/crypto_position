import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/presentation/arbitrage_calculator/arbitrage_calculator.dart';
import 'package:flutter/material.dart';
import 'package:screener/screener.dart';
import 'package:ui_kit/ui_kit.dart';

/// Route argument for the coin chart: the instrument plus the pinned long/short
/// pair taken from the tapped signal (long = buy_exchange, short = sell).
class CoinChartArgs {
  final Instrument instrument;
  final String? longExchange;
  final String? shortExchange;

  /// Venues listing this coin, from the universe catalog. Used only when no
  /// pair is pinned (the catalog tab has no signal to take one from): the first
  /// two the app has market data for become the legs.
  final List<String> venues;

  /// The tapped signal's entry spread, as a plain percent number (e.g. `0.82`
  /// for 0.82%) — seeds the calculator's "Спред входа" field.
  final double? entrySpreadPct;

  const CoinChartArgs({
    required this.instrument,
    this.longExchange,
    this.shortExchange,
    this.venues = const [],
    this.entrySpreadPct,
  });
}

/// Coin detail screen: the arbitrage calculator pinned to one coin, with its
/// own live spread chart fed straight from the exchanges' public REST — the
/// screener server only supplies which coin and which pair to open. Pushed over
/// the bottom nav, so it carries its own [Scaffold] + back button.
class CoinChartScreen extends StatelessWidget {
  final CoinChartArgs args;

  const CoinChartScreen({required this.args, super.key});

  @override
  Widget build(BuildContext context) {
    final legs = _legs;
    final unpriced = [
      for (final venue in [args.longExchange, args.shortExchange])
        if (venue != null && _exchangeByName(venue) == null) venue,
    ];
    return Scaffold(
      appBar: AppBar(title: Text('${args.instrument.pair} · спред')),
      body: Column(
        children: [
          if (unpriced.isNotEmpty) _UnpricedBanner(venues: unpriced),
          Expanded(
            child: ArbitrageCalculator(
              initialBase: args.instrument.base,
              initialExchange1: legs.long,
              initialExchange2: legs.short,
              initialEntrySpreadPct: args.entrySpreadPct,
            ),
          ),
        ],
      ),
    );
  }

  /// The legs to open on: the signal's pinned pair, or — coming from the
  /// catalog, which pins nothing — the first two listed venues the app can
  /// price. A leg left null lets the calculator pick.
  ({ExchangeId? long, ExchangeId? short}) get _legs {
    final long = _exchangeByName(args.longExchange);
    final short = _exchangeByName(args.shortExchange);
    if (long != null || short != null) return (long: long, short: short);
    final priced = [
      for (final venue in args.venues) ?_exchangeByName(venue),
    ];
    return (
      long: priced.isNotEmpty ? priced[0] : null,
      short: priced.length > 1 ? priced[1] : null,
    );
  }
}

/// Maps a screener exchange name (`bybit`, `okx`, …) to the app's [ExchangeId]
/// by its stable key; null when the app has no market-data provider for it.
ExchangeId? _exchangeByName(String? name) {
  final key = name?.toLowerCase();
  for (final e in ExchangeId.values) {
    if (e.key == key) return e;
  }
  return null;
}

/// Warns that a leg's venue is outside the app's market-data providers, so both
/// the chart and the calculation below fell back to other venues. Signals and
/// catalog rows are filtered to the priced venues, so this should not normally
/// appear — it catches a pair that slipped through.
class _UnpricedBanner extends StatelessWidget {
  final List<String> venues;

  const _UnpricedBanner({required this.venues});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: scheme.errorContainer,
      child: Row(
        children: [
          Icon(
            AppIcons.warning_outlined_24,
            size: 18,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Приложение не получает данные с ${venues.join(', ')} — график и '
              'расчёт ниже сделаны по другим площадкам.',
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
