import 'package:crypto_position/src/position_calculator_wm.dart';
import 'package:crypto_position/src/trade_direction.dart';
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
            ListTile(
              title: Text('Риск (USD)'),
              trailing: ValueListenableBuilder(
                valueListenable: wm.riskUsd,
                builder: (context, value, child) {
                  return Text(value == null ? '-' : value.toStringAsFixed(2));
                },
              ),
            ),
            ListTile(
              title: Text('Размер позиции (Crypto)'),
              trailing: ValueListenableBuilder(
                valueListenable: wm.positionSizeCrypto,
                builder: (context, value, child) {
                  return Text(value == null ? '-' : value.toStringAsFixed(2));
                },
              ),
            ),
            ListTile(
              title: Text('Размер позиции (USD)'),
              trailing: ValueListenableBuilder(
                valueListenable: wm.positionSizeUsd,
                builder: (context, value, child) {
                  return Text(value == null ? '-' : value.toStringAsFixed(2));
                },
              ),
            ),
            ListTile(
              title: Text('Потенциальная прибыль'),
              trailing: ValueListenableBuilder(
                valueListenable: wm.profitUsd,
                builder: (context, value, child) {
                  return Text(value == null ? '-' : value.toStringAsFixed(2));
                },
              ),
            ),
            ListTile(
              title: Text('Risk / Reward'),
              trailing: ValueListenableBuilder(
                valueListenable: wm.rr,
                builder: (context, value, child) {
                  return Text(value == null ? '-' : value.toStringAsFixed(2));
                },
              ),
            ),
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
