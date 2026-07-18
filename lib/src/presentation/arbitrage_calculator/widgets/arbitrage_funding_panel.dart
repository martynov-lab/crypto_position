import 'dart:async';

import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/presentation/arbitrage_calculator/arbitrage_calculator_wm.dart';
import 'package:flutter/material.dart';

/// Per-leg funding: current rate per interval and a live countdown to the next
/// settlement. Ticks once a second for the countdown.
class ArbitrageFundingPanel extends StatefulWidget {
  final ArbitrageCalculatorWm wm;

  const ArbitrageFundingPanel({super.key, required this.wm});

  @override
  State<ArbitrageFundingPanel> createState() => _ArbitrageFundingPanelState();
}

class _ArbitrageFundingPanelState extends State<ArbitrageFundingPanel> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wm = widget.wm;
    return ListenableBuilder(
      listenable: Listenable.merge([
        wm.funding1,
        wm.funding2,
        wm.exchange1,
        wm.exchange2,
      ]),
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Фандинг', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            _leg(context, wm.exchange1.value, wm.funding1.value),
            _leg(context, wm.exchange2.value, wm.funding2.value),
          ],
        );
      },
    );
  }

  Widget _leg(BuildContext context, ExchangeId? exchange, FundingInfo? funding) {
    if (exchange == null) return const SizedBox.shrink();
    final rate = funding == null ? null : funding.rate * 100;
    final countdown = _countdown(funding?.nextFundingMs);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(exchange.label)),
          Text(
            rate == null ? '—' : '${rate.toStringAsFixed(4)}%',
            style: TextStyle(
              color: rate == null
                  ? null
                  : (rate >= 0 ? Colors.red : Colors.green),
            ),
          ),
          if (countdown != null) ...[
            const SizedBox(width: 12),
            Text('через $countdown',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  String? _countdown(int? nextMs) {
    if (nextMs == null) return null;
    final remaining = nextMs - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) return '0:00';
    final total = remaining ~/ 1000;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }
}
