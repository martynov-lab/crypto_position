import 'package:adaptive_layout/adaptive_layout.dart';
import 'package:crypto_position/src/components/result_tile.dart';
import 'package:crypto_position/src/presentation/position_calculator/position_calculator_wm.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class PositionCalculator extends ElementaryWidget<PositionCalculatorWm> {
  PositionCalculator({super.key})
    : super((context) => positionCalculatorWMFactory(context: context));

  @override
  Widget build(PositionCalculatorWm wm) {
    return AdaptiveLayout(
      smallLayout: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                _buildInputsSection(wm),
                const SizedBox(height: 24),
                _buildResultsSection(wm),
              ],
            ),
          ),
        ),
      ),
      mediumLayout: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildInputsSection(wm)),
                const SizedBox(width: 24),
                Expanded(child: _buildResultsSection(wm)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputsSection(PositionCalculatorWm wm) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildField('Размер счёта (USD)', wm.accountController),
        _buildField('Риск (%)', wm.riskController),
        _buildField('Цена входа', wm.entryController),
        _buildField('Стоп-лосс', wm.stopController),
        _buildField('Комиссия открытия (%)', wm.openCommissionController),
        _buildField(
          'Комиссия закрытия (%)',
          wm.closeCommissionController,
        ),
        const SizedBox(height: 16),
        _buildTakeProfitsSection(wm),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            onPressed: wm.calculate,
            label: 'Рассчитать',
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection(PositionCalculatorWm wm) {
    return Column(
      children: [
        ValueListenableBuilder<String?>(
          valueListenable: wm.validationError,
          builder: (context, error, _) => error == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
        ),
        const Divider(),
        ResultTile(listenable: wm.riskUsd, title: 'Риск (USD)'),
        ResultTile(
          listenable: wm.positionSizeCrypto,
          title: 'Размер позиции (Crypto)',
        ),
        ResultTile(
          listenable: wm.positionSizeUsd,
          title: 'Размер позиции (USD)',
        ),
        ValueListenableBuilder<List<double?>>(
          valueListenable: wm.tpProfits,
          builder: (context, profits, _) => Column(
            children: [
              for (var i = 0; i < profits.length; i++)
                ListTile(
                  title: Text('Прибыль TP ${i + 1}'),
                  trailing: Text(
                    profits[i] == null
                        ? '-'
                        : profits[i]!.toStringAsFixed(2),
                  ),
                ),
            ],
          ),
        ),
        ResultTile(
          listenable: wm.profitUsd,
          title: 'Общая прибыль',
        ),
        ResultTile(listenable: wm.rr, title: 'Risk / Reward'),
      ],
    );
  }

  Widget _buildTakeProfitsSection(PositionCalculatorWm wm) {
    return ValueListenableBuilder<List<TakeProfitEntry>>(
      valueListenable: wm.takeProfits,
      builder: (context, entries, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Тейк-профиты',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton.filled(
                  onPressed: wm.addTakeProfit,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < entries.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppTextField(
                        controller: entries[i].priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        labelText: 'Цена TP ${i + 1}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        controller: entries[i].percentController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        labelText: '%',
                      ),
                    ),
                    if (entries.length > 1)
                      IconButton(
                        onPressed: () => wm.removeTakeProfit(i),
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Theme.of(context).colorScheme.error,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

Widget _buildField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: AppTextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      labelText: label,
    ),
  );
}
