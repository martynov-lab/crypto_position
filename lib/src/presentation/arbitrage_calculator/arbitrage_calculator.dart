import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/presentation/arbitrage_calculator/arbitrage_calculator_wm.dart';
import 'package:crypto_position/src/presentation/arbitrage_calculator/arbitrage_math.dart';
import 'package:crypto_position/src/presentation/arbitrage_calculator/widgets/arbitrage_funding_panel.dart';
import 'package:crypto_position/src/presentation/arbitrage_calculator/widgets/spread_line_chart.dart';
import 'package:crypto_position/src/trade/arbitrage_entry_controller.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class ArbitrageCalculator extends ElementaryWidget<ArbitrageCalculatorWm> {
  ArbitrageCalculator({super.key})
    : super((context) => arbitrageCalculatorWmFactory(context: context));

  @override
  Widget build(ArbitrageCalculatorWm wm) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Wide (desktop): settings on the left, live chart on the right.
        final wide = constraints.maxWidth >= 900;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 1150 : 700),
              child: wide ? _WideLayout(wm: wm) : _NarrowLayout(wm: wm),
            ),
          ),
        );
      },
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  final ArbitrageCalculatorWm wm;
  const _NarrowLayout({required this.wm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CoinSearch(wm: wm),
        const SizedBox(height: 16),
        _ExchangePickers(wm: wm),
        const SizedBox(height: 16),
        _LiveSection(wm: wm, chartHeight: 300),
        const SizedBox(height: 16),
        _Inputs(wm: wm),
        const SizedBox(height: 16),
        _CalcButton(wm: wm),
        const SizedBox(height: 16),
        _Results(wm: wm),
        _SlippagePanel(wm: wm),
        _EntryPanel(wm: wm),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  final ArbitrageCalculatorWm wm;
  const _WideLayout({required this.wm});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CoinSearch(wm: wm),
              const SizedBox(height: 16),
              _ExchangePickers(wm: wm),
              const SizedBox(height: 16),
              _Inputs(wm: wm),
              const SizedBox(height: 16),
              _CalcButton(wm: wm),
              const SizedBox(height: 16),
              _Results(wm: wm),
              _SlippagePanel(wm: wm),
              _EntryPanel(wm: wm),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(flex: 6, child: _LiveSection(wm: wm, chartHeight: 460)),
      ],
    );
  }
}

class _CalcButton extends StatelessWidget {
  final ArbitrageCalculatorWm wm;
  const _CalcButton({required this.wm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppButton(onPressed: wm.calculate, label: 'Рассчитать'),
    );
  }
}

// --- Coin search --------------------------------------------------------

class _CoinSearch extends StatelessWidget {
  final ArbitrageCalculatorWm wm;
  const _CoinSearch({required this.wm});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: wm.connectedListenable,
      builder: (context, _) {
        if (wm.availableExchangesAll.isEmpty) {
          return const _InfoCard(
            'Нет подключённых бирж. Подключите API-ключи в разделе «Настройки».',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: wm.searchController,
              labelText: 'Монета (фьючерс)',
              prefixIcon: const Icon(Icons.search),
            ),
            ValueListenableBuilder<List<String>>(
              valueListenable: wm.candidates,
              builder: (context, list, _) {
                if (list.isEmpty) return const SizedBox.shrink();
                return Card(
                  margin: const EdgeInsets.only(top: 4),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final base in list)
                          ListTile(
                            dense: true,
                            title: Text(base),
                            onTap: () => wm.selectBase(base),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// --- Exchange pickers ---------------------------------------------------

class _ExchangePickers extends StatelessWidget {
  final ArbitrageCalculatorWm wm;
  const _ExchangePickers({required this.wm});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: wm.selectedBase,
      builder: (context, base, _) {
        if (base == null) return const SizedBox.shrink();
        final available = wm.availableExchanges;
        if (available.length < 2) {
          return _InfoCard(
            'Монета $base доступна менее чем на двух подключённых биржах.',
          );
        }
        return Row(
          children: [
            Expanded(
              child: _ExchangeDropdown(
                label: 'Биржа 1',
                value: wm.exchange1,
                options: available,
                exclude: wm.exchange2,
                onChanged: wm.selectExchange1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ExchangeDropdown(
                label: 'Биржа 2',
                value: wm.exchange2,
                options: available,
                exclude: wm.exchange1,
                onChanged: wm.selectExchange2,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExchangeDropdown extends StatelessWidget {
  final String label;
  final ValueListenable<ExchangeId?> value;
  final ValueListenable<ExchangeId?> exclude;
  final List<ExchangeId> options;
  final ValueChanged<ExchangeId?> onChanged;

  const _ExchangeDropdown({
    required this.label,
    required this.value,
    required this.exclude,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([value, exclude]),
      builder: (context, _) {
        final excluded = exclude.value;
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ExchangeId>(
              isExpanded: true,
              value: value.value,
              items: [
                for (final e in options)
                  DropdownMenuItem(
                    value: e,
                    enabled: e != excluded,
                    child: Text(
                      e.label,
                      style: e == excluded
                          ? TextStyle(color: Theme.of(context).disabledColor)
                          : null,
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}

// --- Live section: prices, spread, chart, funding -----------------------

class _LiveSection extends StatelessWidget {
  final ArbitrageCalculatorWm wm;
  final double chartHeight;
  const _LiveSection({required this.wm, required this.chartHeight});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([wm.exchange1, wm.exchange2]),
      builder: (context, _) {
        final e1 = wm.exchange1.value;
        final e2 = wm.exchange2.value;
        if (e1 == null || e2 == null) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PriceTile(wm: wm, exchange: e1, leg: 1),
                    ),
                    Expanded(
                      child: _PriceTile(wm: wm, exchange: e2, leg: 2),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _SpreadHeader(wm: wm),
                const SizedBox(height: 8),
                _TimeframeSelector(wm: wm),
                const SizedBox(height: 8),
                SizedBox(
                  height: chartHeight,
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      wm.spreadSeries,
                      wm.timeframeMin,
                      wm.quote1,
                      wm.quote2,
                    ]),
                    builder: (context, _) {
                      final q1 = wm.quote1.value;
                      final q2 = wm.quote2.value;
                      String? buyLabel;
                      String? sellLabel;
                      if (q1 != null && q2 != null && q1.mid != q2.mid) {
                        // Buy (long) the cheaper leg, sell (short) the dearer.
                        final e1Cheaper = q1.mid < q2.mid;
                        buyLabel = (e1Cheaper ? e1 : e2).label;
                        sellLabel = (e1Cheaper ? e2 : e1).label;
                      }
                      return SpreadLineChart(
                        series: wm.spreadSeries.value,
                        timeframeMin: wm.timeframeMin.value,
                        buyLabel: buyLabel,
                        sellLabel: sellLabel,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ArbitrageFundingPanel(wm: wm),
                _ErrorText(wm: wm),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PriceTile extends StatelessWidget {
  final ArbitrageCalculatorWm wm;
  final ExchangeId exchange;
  final int leg;
  const _PriceTile({
    required this.wm,
    required this.exchange,
    required this.leg,
  });

  @override
  Widget build(BuildContext context) {
    final quote = leg == 1 ? wm.quote1 : wm.quote2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(exchange.label, style: Theme.of(context).textTheme.labelMedium),
        ValueListenableBuilder<Quote?>(
          valueListenable: quote,
          builder: (context, q, _) => Text(
            q == null ? '—' : _fmtPrice(q.mid),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Text(
          'maker ${wm.makerPct(exchange)}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SpreadHeader extends StatelessWidget {
  final ArbitrageCalculatorWm wm;
  const _SpreadHeader({required this.wm});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SpreadSample>>(
      valueListenable: wm.spreadSeries,
      builder: (context, _, _) {
        final spread = wm.currentSpreadPct;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Спред', style: Theme.of(context).textTheme.labelLarge),
            Text(
              spread == null ? '—' : '${spread.toStringAsFixed(3)}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: spread == null
                    ? null
                    : (spread >= 0 ? Colors.green : Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TimeframeSelector extends StatelessWidget {
  final ArbitrageCalculatorWm wm;
  const _TimeframeSelector({required this.wm});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: wm.timeframeMin,
      builder: (context, selected, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (final m in kTimeframesMin)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  label: Text(m == 0 ? 'Тики' : '$mм'),
                  selected: m == selected,
                  onSelected: (_) => wm.setTimeframe(m),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ErrorText extends StatelessWidget {
  final ArbitrageCalculatorWm wm;
  const _ErrorText({required this.wm});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: wm.dataError,
      builder: (context, error, _) => error == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
    );
  }
}

// --- Inputs -------------------------------------------------------------

class _Inputs extends StatelessWidget {
  final ArbitrageCalculatorWm wm;
  const _Inputs({required this.wm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _NumField(
                controller: wm.capital1Controller,
                label: 'Средства биржа 1 (USD)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumField(
                controller: wm.capital2Controller,
                label: 'Средства биржа 2 (USD)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LeverageSlider(wm: wm),
        const SizedBox(height: 12),
        _NumField(
          controller: wm.holdingHoursController,
          label: 'Время удержания (часы)',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _NumField(
                controller: wm.entrySpreadController,
                label: 'Спред входа (%)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumField(
                controller: wm.exitSpreadController,
                label: 'Спред выхода (%)',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LeverageSlider extends StatelessWidget {
  final ArbitrageCalculatorWm wm;
  const _LeverageSlider({required this.wm});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: wm.leverage,
      builder: (context, lev, _) {
        final index = kLeverageSteps
            .indexOf(lev)
            .clamp(0, kLeverageSteps.length - 1);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Плечо: ${lev.toStringAsFixed(0)}x',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Slider(
              value: index.toDouble(),
              min: 0,
              max: (kLeverageSteps.length - 1).toDouble(),
              divisions: kLeverageSteps.length - 1,
              label: '${lev.toStringAsFixed(0)}x',
              onChanged: (v) => wm.setLeverage(kLeverageSteps[v.round()]),
            ),
          ],
        );
      },
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _NumField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      labelText: label,
    );
  }
}

// --- Results ------------------------------------------------------------

class _Results extends StatelessWidget {
  final ArbitrageCalculatorWm wm;
  const _Results({required this.wm});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ArbitrageResult?>(
      valueListenable: wm.result,
      builder: (context, r, _) {
        if (r == null) return const SizedBox.shrink();
        final profitColor = r.netUsd >= 0 ? Colors.green : Colors.red;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row(context, 'Ноционал (на ногу)', _fmtUsd(r.notional)),
                _row(context, 'Профит по спреду', _fmtUsd(r.grossUsd)),
                _row(context, 'Комиссии', '-${_fmtUsd(r.feesUsd)}'),
                _row(context, 'Фандинг за период', _fmtUsd(r.fundingUsd)),
                const Divider(),
                _row(
                  context,
                  'Чистый профит',
                  _fmtUsd(r.netUsd),
                  color: profitColor,
                  bold: true,
                ),
                _row(
                  context,
                  'Доходность на капитал',
                  '${r.netReturnPct.toStringAsFixed(2)}%',
                  color: profitColor,
                ),
                _row(
                  context,
                  'APR',
                  '${r.aprPct.toStringAsFixed(1)}%',
                  color: profitColor,
                  bold: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Color? color,
    bool bold = false,
  }) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: color,
      fontWeight: bold ? FontWeight.bold : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Per-leg order-book fill quality for the last calculation: whether the
/// visible depth covers the sized quantity and the expected slippage.
class _SlippagePanel extends StatelessWidget {
  final ArbitrageCalculatorWm wm;
  const _SlippagePanel({required this.wm});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        wm.fill1,
        wm.fill2,
        wm.exchange1,
        wm.exchange2,
      ]),
      builder: (context, _) {
        final f1 = wm.fill1.value;
        final f2 = wm.fill2.value;
        if (f1 == null && f2 == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Исполнение по стакану',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (f1 != null)
                    _leg(context, wm.exchange1.value?.label ?? 'Нога 1', f1),
                  if (f2 != null)
                    _leg(context, wm.exchange2.value?.label ?? 'Нога 2', f2),
                  const SizedBox(height: 8),
                  Text(
                    'Оценка по снимку стакана — не гарантия исполнения.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _leg(BuildContext context, String label, FillEstimate f) {
    final ok = f.covered;
    final color = ok ? Colors.green : Colors.orange;
    final coverage = f.requestedQty > 0
        ? (f.filledQty / f.requestedQty * 100).clamp(0, 100)
        : 0;
    final status = ok
        ? 'покрытие полное'
        : 'покрытие ${coverage.toStringAsFixed(0)}% — риск частичного';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            '${ok ? '✅' : '⚠️'} $status · слип ${f.slippagePct.toStringAsFixed(3)}%',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Order preview, preflight canary and the entry action for the current plan.
class _EntryPanel extends StatelessWidget {
  final ArbitrageCalculatorWm wm;
  const _EntryPanel({required this.wm});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        wm.entryPlan,
        wm.canaryReport,
        wm.entryReport,
        wm.entryBusy,
      ]),
      builder: (context, _) {
        final plan = wm.entryPlan.value;
        if (plan == null) return const SizedBox.shrink();
        final busy = wm.entryBusy.value;
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Вход в позицию',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _legRow(context, 'LONG', plan.long),
                  _legRow(context, 'SHORT', plan.short),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.outlined(
                          label: 'Проверить',
                          onPressed: busy ? null : wm.runCanary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Войти',
                          onPressed: (busy || !plan.valid)
                              ? null
                              : () => _confirmAndEnter(context, plan),
                        ),
                      ),
                    ],
                  ),
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  _canaryResult(context, wm.canaryReport.value),
                  _entryResult(context, wm.entryReport.value),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _legRow(BuildContext context, String side, EntryLeg leg) {
    final invalid = leg.invalidReason;
    final text = invalid == null
        ? '${leg.exchange.label}: $side ${_fmtQty(leg.qty)} @ ${_fmtPrice(leg.price)}'
        : '${leg.exchange.label}: $side — $invalid';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: invalid == null ? null : Colors.red,
        ),
      ),
    );
  }

  Widget _canaryResult(BuildContext context, CanaryReport? report) {
    if (report == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            report.ok
                ? '✅ Обе биржи принимают ордера'
                : '⚠️ Канарейка выявила проблемы',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: report.ok ? Colors.green : Colors.orange,
            ),
          ),
          for (final leg in report.legs)
            if (!leg.ok)
              Text(
                '${leg.exchange.label}: ${leg.message ?? 'ошибка'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
        ],
      ),
    );
  }

  Widget _entryResult(BuildContext context, EntryReport? report) {
    if (report == null) return const SizedBox.shrink();
    final color = report.ok
        ? Colors.green
        : (report.unwound ? Colors.orange : Colors.red);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            report.ok
                ? '✅ Позиция открыта'
                : '⚠️ ${report.note ?? 'ошибка входа'}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color),
          ),
          for (final leg in report.legs)
            Text(
              leg.ok
                  ? '${leg.exchange.label}: ордер ${leg.orderId ?? ''}'
                  : '${leg.exchange.label}: ${leg.message ?? 'отклонён'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: leg.ok ? null : Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmAndEnter(BuildContext context, EntryPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите вход'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Будут выставлены реальные ордера:'),
            const SizedBox(height: 8),
            Text(
              '${plan.long.exchange.label}: LONG '
              '${_fmtQty(plan.long.qty)} @ ${_fmtPrice(plan.long.price)}',
            ),
            Text(
              '${plan.short.exchange.label}: SHORT '
              '${_fmtQty(plan.short.qty)} @ ${_fmtPrice(plan.short.price)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Войти'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await wm.executeEntry();
  }
}

String _fmtQty(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(4);
}

class _InfoCard extends StatelessWidget {
  final String text;
  const _InfoCard(this.text);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Text(text)),
    );
  }
}

String _fmtPrice(double v) {
  if (v >= 1000) return v.toStringAsFixed(1);
  if (v >= 1) return v.toStringAsFixed(3);
  return v.toStringAsFixed(6);
}

String _fmtUsd(double v) => '${v.toStringAsFixed(2)} \$';
