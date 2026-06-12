import 'package:flutter/material.dart';

enum TradeDirection { long, short }

class PositionCalculatorPage extends StatefulWidget {
  const PositionCalculatorPage({super.key});

  @override
  State<PositionCalculatorPage> createState() => _PositionCalculatorPageState();
}

class _PositionCalculatorPageState extends State<PositionCalculatorPage> {
  final accountController = TextEditingController();
  final riskController = TextEditingController(text: '1');
  final entryController = TextEditingController();
  final stopController = TextEditingController();
  final takeProfitController = TextEditingController();
  final openCommissionController = TextEditingController(text: '0.1');
  final closeCommissionController = TextEditingController(text: '0.1');

  TradeDirection direction = TradeDirection.long;

  double? positionSizeCrypto;
  double? positionSizeUsd;
  double? riskUsd;
  double? profitUsd;
  double? rr;

  void calculate() {
    final accountSize = double.tryParse(accountController.text) ?? 0;
    final riskPercent = double.tryParse(riskController.text) ?? 0;
    final entry = double.tryParse(entryController.text) ?? 0;
    final stop = double.tryParse(stopController.text) ?? 0;
    final takeProfit = double.tryParse(takeProfitController.text) ?? 0;
    final openCommissionPercent =
        double.tryParse(openCommissionController.text) ?? 0;
    final closeCommissionPercent =
        double.tryParse(closeCommissionController.text) ?? 0;

    if (accountSize <= 0 || entry <= 0 || stop <= 0 || takeProfit <= 0) {
      return;
    }

    final riskAmount = accountSize * riskPercent / 100;
    final stopDistance = (entry - stop).abs();
    final openCommissionPerCoin = entry * openCommissionPercent / 100;
    final stopCommissionPerCoin = stop * closeCommissionPercent / 100;
    final totalRiskPerCoin =
        stopDistance + openCommissionPerCoin + stopCommissionPerCoin;
    final sizeCrypto = riskAmount / totalRiskPerCoin;
    final sizeUsd = sizeCrypto * entry;
    final profitDistance = (takeProfit - entry).abs();
    final takeProfitCommissionPerCoin =
        takeProfit * closeCommissionPercent / 100;
    final netProfitPerCoin =
        profitDistance - openCommissionPerCoin - takeProfitCommissionPerCoin;
    final profit = sizeCrypto * netProfitPerCoin;

    setState(() {
      positionSizeCrypto = sizeCrypto;
      positionSizeUsd = sizeUsd;
      riskUsd = riskAmount;
      profitUsd = profit;
      rr = profit / riskAmount;
    });
  }

  @override
  void dispose() {
    accountController.dispose();
    riskController.dispose();
    entryController.dispose();
    stopController.dispose();
    takeProfitController.dispose();
    openCommissionController.dispose();
    closeCommissionController.dispose();
    super.dispose();
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

  Widget buildResult(String label, double? value) {
    return ListTile(
      title: Text(label),
      trailing: Text(value == null ? '-' : value.toStringAsFixed(2)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              selected: {direction},
              onSelectionChanged: (value) {
                setState(() {
                  direction = value.first;
                });
              },
            ),
            const SizedBox(height: 16),
            buildField('Размер счёта (USD)', accountController),
            buildField('Риск (%)', riskController),
            buildField('Цена входа', entryController),
            buildField('Стоп-лосс', stopController),
            buildField('Тейк-профит', takeProfitController),
            buildField('Комиссия открытия (%)', openCommissionController),
            buildField('Комиссия закрытия (%)', closeCommissionController),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: calculate,
                child: const Text('Рассчитать'),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            buildResult('Риск (USD)', riskUsd),
            buildResult('Размер позиции (Crypto)', positionSizeCrypto),
            buildResult('Размер позиции (USD)', positionSizeUsd),
            buildResult('Потенциальная прибыль', profitUsd),
            buildResult('Risk / Reward', rr),
          ],
        ),
      ),
    );
  }
}
