import 'package:crypto_position/src/position_calculator_wm.dart';
import 'package:crypto_position/src/trade_direction.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PositionCalculator extends ElementaryWidget<PositionCalculatorWm> {
  PositionCalculator({super.key})
    : super((context) => positionCalculatorWMFactory(context: context));

  @override
  Widget build(PositionCalculatorWm wm) {
    return Scaffold(
      appBar: AppBar(title: const Text('Position Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<TradeDirection>(
              segments: const [
                ButtonSegment(value: TradeDirection.long, label: Text('LONG')),
                ButtonSegment(
                  value: TradeDirection.short,
                  label: Text('SHORT'),
                ),
              ],
              selected: {wm.direction},
              onSelectionChanged: (value) {
                wm.direction = value.first;
              },
            ),
            const SizedBox(height: 16),
            buildField('Размер счёта (USD)', wm.accountController),
            buildField('Риск (%)', wm.riskController),
            buildField('Цена входа', wm.entryController),
            buildField('Стоп-лосс', wm.stopController),
            buildField('Тейк-профит', wm.takeProfitController),
            buildField('Комиссия открытия (%)', wm.openCommissionController),
            buildField('Комиссия закрытия (%)', wm.closeCommissionController),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: wm.calculate,
                child: const Text('Рассчитать'),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            buildResult('Риск (USD)', wm.riskUsd),
            buildResult('Размер позиции (Crypto)', wm.positionSizeCrypto),
            buildResult('Размер позиции (USD)', wm.positionSizeUsd),
            buildResult('Потенциальная прибыль', wm.profitUsd),
            buildResult('Risk / Reward', wm.rr),
          ],
        ),
      ),
    );
  }
}

Widget buildField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

Widget buildResult(String label, ValueListenable<double?> listenable) {
  return ListTile(
    title: Text(label),
    trailing: ValueListenableBuilder(
      valueListenable: listenable,
      builder: (context, value, child) {
        return Text(value == null ? '-' : value.toStringAsFixed(2));
      },
    ),
  );
}
