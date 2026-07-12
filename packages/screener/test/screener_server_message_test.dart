import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:screener/screener.dart';

void main() {
  group('ScreenerServerMessage.decode', () {
    test('decodes the guide example event with all optional blocks', () {
      const raw = '''
      {
        "type": "event",
        "spread": {
          "instrument": { "base": "ARB", "quote": "USDT", "kind": "perp" },
          "buy_exchange": "mexc",
          "sell_exchange": "kucoin",
          "vwap_buy": "1.2340",
          "vwap_sell": "1.2712",
          "gross_pct": "0.0301",
          "net_pct": "0.0289",
          "executable_notional": "2000",
          "capped_by_depth": false
        },
        "funding": { "long_exchange": "okx", "short_exchange": "bybit", "diff_apr": "0.1832" },
        "dynamics": {
          "baseline_pct": "0.0031", "stddev_pct": "0.0090", "current_pct": "0.0289",
          "z_score": "3.41", "sample_count": 120, "episode_ms": 1400
        },
        "quality_score": "66.2",
        "ts_ms": 1752230400000
      }''';

      final message = ScreenerServerMessage.decode(raw);
      expect(message, isA<ScreenerEvent>());
      final event = (message as ScreenerEvent).event;

      expect(event.instrument.pair, 'ARB/USDT');
      expect(event.spread.buyExchange, 'mexc');
      expect(event.spread.netPct, '0.0289');
      expect(event.spread.cappedByDepth, isFalse);
      expect(event.funding?.diffApr, '0.1832');
      expect(event.dynamics?.sampleCount, 120);
      expect(event.dynamics?.episodeMs, 1400);
      expect(event.qualityScore, '66.2');
      expect(event.tsMs, 1752230400000);
    });

    test('omits funding/dynamics/quality_score when absent', () {
      const raw = '''
      {
        "type": "event",
        "spread": {
          "instrument": { "base": "BTC", "quote": "USDT", "kind": "perp" },
          "buy_exchange": "bybit", "sell_exchange": "okx",
          "vwap_buy": "1", "vwap_sell": "1", "gross_pct": "0", "net_pct": "0.05",
          "executable_notional": "1000", "capped_by_depth": true
        },
        "ts_ms": 1
      }''';

      final event = (ScreenerServerMessage.decode(raw) as ScreenerEvent).event;
      expect(event.funding, isNull);
      expect(event.dynamics, isNull);
      expect(event.qualityScore, isNull);
      expect(event.spread.cappedByDepth, isTrue);
    });

    test('decodes universe rows', () {
      const raw = '''
      { "type": "universe", "instruments": [
        { "base": "BTC", "quote": "USDT", "exchanges": ["bybit","okx"], "coverage": 2 }
      ] }''';
      final message = ScreenerServerMessage.decode(raw);
      expect(message, isA<ScreenerUniverse>());
      final rows = (message as ScreenerUniverse).instruments;
      expect(rows.single.pair, 'BTC/USDT');
      expect(rows.single.exchanges, ['bybit', 'okx']);
      expect(rows.single.coverage, 2);
    });

    test('decodes subscribed ack and error', () {
      expect(
        ScreenerServerMessage.decode('{"type":"subscribed","config":{"quote":"USDT"}}'),
        isA<ScreenerSubscribed>(),
      );
      final error =
          ScreenerServerMessage.decode('{"type":"error","message":"unauthorized"}');
      expect((error as ScreenerError).message, 'unauthorized');
    });

    test('unknown type is ignored, not fatal', () {
      expect(
        ScreenerServerMessage.decode('{"type":"whatever"}'),
        isA<ScreenerUnknown>(),
      );
    });

    test('decodes watch_snapshot with In/Out points and funding header', () {
      const raw = '''
      { "type": "watch_snapshot",
        "instrument": { "base": "ARB", "quote": "USDT", "kind": "perp" },
        "resolution_ms": 1000, "window_ms": 900000,
        "long_exchange": "mexc", "short_exchange": "kucoin",
        "funding_interval_hours": "8", "next_funding_ms": 1752231600000,
        "funding_long_apr": "0.1083", "funding_short_apr": "0.0848",
        "points": [
          { "ts_ms": 1752230400000, "net_pct": "0.0031", "in_pct": "0.0031",
            "out_pct": "-0.0016", "baseline_pct": "0.0030",
            "buy_exchange": "mexc", "sell_exchange": "kucoin",
            "executable_notional": "2000", "capped_by_depth": false,
            "funding_long_pct": "0.0001", "funding_short_pct": "0.00008" } ] }''';
      final message = ScreenerServerMessage.decode(raw);
      expect(message, isA<ScreenerWatchSnapshot>());
      final snapshot = message as ScreenerWatchSnapshot;
      expect(snapshot.instrument.pair, 'ARB/USDT');
      expect(snapshot.meta.resolutionMs, 1000);
      expect(snapshot.meta.longExchange, 'mexc');
      expect(snapshot.meta.shortExchange, 'kucoin');
      expect(snapshot.meta.fundingIntervalHours, '8');
      expect(snapshot.meta.nextFundingMs, 1752231600000);
      expect(snapshot.meta.fundingLongApr, '0.1083');
      final point = snapshot.points.single;
      expect(point.inPct, '0.0031');
      expect(point.outPct, '-0.0016');
      expect(point.entryPct, '0.0031');
      expect(point.fundingLongPct, '0.0001');
      expect(point.fundingShortPct, '0.00008');
    });

    test('decodes spread_tick with In/Out', () {
      const raw = '''
      { "type": "spread_tick",
        "instrument": { "base": "ARB", "quote": "USDT", "kind": "perp" },
        "point": { "ts_ms": 1752230402000, "net_pct": "0.0289",
                   "in_pct": "0.0289", "out_pct": "-0.0010",
                   "capped_by_depth": true } }''';
      final message = ScreenerServerMessage.decode(raw);
      expect(message, isA<ScreenerSpreadTick>());
      final tick = message as ScreenerSpreadTick;
      expect(tick.point.inPct, '0.0289');
      expect(tick.point.outPct, '-0.0010');
      expect(tick.point.cappedByDepth, isTrue);
      expect(tick.point.baselinePct, isNull);
    });

    test('entryPct falls back to net_pct when in_pct absent (legacy)', () {
      const raw = '''
      { "type": "spread_tick",
        "instrument": { "base": "ARB", "quote": "USDT", "kind": "perp" },
        "point": { "ts_ms": 1, "net_pct": "0.05" } }''';
      final tick = ScreenerServerMessage.decode(raw) as ScreenerSpreadTick;
      expect(tick.point.inPct, isNull);
      expect(tick.point.entryPct, '0.05');
    });
  });

  group('ClientConfig.toJson', () {
    test('drops null fields and keeps snake_case keys', () {
      const config = ClientConfig(
        minNetSpreadPct: '0.03',
        maxNetSpreadPct: '0.15',
        exchanges: ['bybit', 'okx'],
      );
      final json = config.toJson();
      expect(json, {
        'min_net_spread_pct': '0.03',
        'max_net_spread_pct': '0.15',
        'exchanges': ['bybit', 'okx'],
      });
      // Round-trips as the subscribe payload's config object.
      expect(jsonDecode(jsonEncode(json)), json);
    });
  });

  group('Decimals.percent', () {
    test('formats a fraction string as a percent without float error', () {
      expect(Decimals.percent('0.0289'), '2.89%');
      expect(Decimals.percent('-0.0004', fractionDigits: 4), '-0.0400%');
    });
  });
}
