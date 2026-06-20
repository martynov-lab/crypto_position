import 'package:crypto_position/src/position_calculator.dart';
import 'package:crypto_position/src/position_calculator_model.dart';
import 'package:crypto_position/src/trade_direction.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PositionCalculatorWm
    extends WidgetModel<PositionCalculator, PositionCalculatorModel> {
  TradeDirection direction = TradeDirection.long;

  final ValueNotifier<double?> _positionSizeCrypto = ValueNotifier(0.0);
  final ValueNotifier<double?> _positionSizeUsd = ValueNotifier(0.0);
  final ValueNotifier<double?> _riskUsd = ValueNotifier(0.0);
  final ValueNotifier<double?> _profitUsd = ValueNotifier(0.0);
  final ValueNotifier<double?> _rr = ValueNotifier(0.0);

  final accountController = TextEditingController();
  final riskController = TextEditingController(text: '1');
  final entryController = TextEditingController();
  final stopController = TextEditingController();
  final takeProfitController = TextEditingController();
  final openCommissionController = TextEditingController(text: '0.1');
  final closeCommissionController = TextEditingController(text: '0.1');

  ValueListenable<double?> get positionSizeCrypto => _positionSizeCrypto;
  ValueListenable<double?> get positionSizeUsd => _positionSizeUsd;
  ValueListenable<double?> get riskUsd => _riskUsd;
  ValueListenable<double?> get profitUsd => _profitUsd;
  ValueListenable<double?> get rr => _rr;

  PositionCalculatorWm(super.model);

  @override
  void initWidgetModel() {
    super.initWidgetModel();

    _loadAccountValue();
    accountController.addListener(_onAccountChanged);
  }

  @override
  void dispose() {
    accountController.dispose();
    accountController.removeListener(_onAccountChanged);
    riskController.dispose();
    entryController.dispose();
    stopController.dispose();
    takeProfitController.dispose();
    openCommissionController.dispose();
    closeCommissionController.dispose();

    super.dispose();
  }

  Future<void> _loadAccountValue() async {
    final value = await model.getValue();

    accountController.text = value;
  }

  void _onAccountChanged() {
    model.setValue(accountController.text);
  }

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

    _positionSizeCrypto.value = sizeCrypto;
    _positionSizeUsd.value = sizeUsd;
    _riskUsd.value = riskAmount;
    _profitUsd.value = profit;
    _rr.value = profit / riskAmount;
  }
}

PositionCalculatorWm positionCalculatorWMFactory({
  required BuildContext context,
}) {
  return PositionCalculatorWm(PositionCalculatorModel(context.read()));
}
