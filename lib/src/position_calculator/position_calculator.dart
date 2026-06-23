import 'package:crypto_position/src/components/result_tile.dart';
import 'package:crypto_position/src/position_calculator/position_calculator_wm.dart';
import 'package:elementary/elementary.dart';
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
            ResultTile(listenable: wm.riskUsd, title: 'Риск (USD)'),
            ResultTile(
              listenable: wm.positionSizeCrypto,
              title: 'Размер позиции (Crypto)',
            ),
            ResultTile(
              listenable: wm.positionSizeUsd,
              title: 'Размер позиции (USD)',
            ),
            ResultTile(
              listenable: wm.profitUsd,
              title: 'Потенциальная прибыль',
            ),
            ResultTile(listenable: wm.rr, title: 'Risk / Reward'),
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
