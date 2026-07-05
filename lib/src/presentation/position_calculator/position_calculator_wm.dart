import 'package:crypto_position/src/presentation/position_calculator/position_calculator.dart';
import 'package:crypto_position/src/presentation/position_calculator/position_calculator_model.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TakeProfitEntry {
  final TextEditingController priceController;
  final TextEditingController percentController;

  TakeProfitEntry({String? price, String? percent})
    : priceController = TextEditingController(text: price ?? ''),
      percentController = TextEditingController(text: percent ?? '');

  void dispose() {
    priceController.dispose();
    percentController.dispose();
  }
}

class PositionCalculatorWm
    extends WidgetModel<PositionCalculator, PositionCalculatorModel> {
  final ValueNotifier<double?> _positionSizeCrypto = ValueNotifier(0.0);
  final ValueNotifier<double?> _positionSizeUsd = ValueNotifier(0.0);
  final ValueNotifier<double?> _riskUsd = ValueNotifier(0.0);
  final ValueNotifier<double?> _profitUsd = ValueNotifier(0.0);
  final ValueNotifier<double?> _rr = ValueNotifier(0.0);

  final accountController = TextEditingController();
  final riskController = TextEditingController();
  final entryController = TextEditingController();
  final stopController = TextEditingController();
  final openCommissionController = TextEditingController(text: '0.1');
  final closeCommissionController = TextEditingController(text: '0.1');

  final ValueNotifier<List<TakeProfitEntry>> _takeProfits = ValueNotifier([]);
  ValueListenable<List<TakeProfitEntry>> get takeProfits => _takeProfits;

  final ValueNotifier<List<double?>> _tpProfits = ValueNotifier([]);
  ValueListenable<List<double?>> get tpProfits => _tpProfits;

  final ValueNotifier<String?> _validationError = ValueNotifier(null);
  ValueListenable<String?> get validationError => _validationError;

  ValueListenable<double?> get positionSizeCrypto => _positionSizeCrypto;
  ValueListenable<double?> get positionSizeUsd => _positionSizeUsd;
  ValueListenable<double?> get riskUsd => _riskUsd;
  ValueListenable<double?> get profitUsd => _profitUsd;
  ValueListenable<double?> get rr => _rr;

  PositionCalculatorWm(super.model);

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _takeProfits.value = [TakeProfitEntry(percent: '100')];
    _loadAccountValue();
    accountController.addListener(_onAccountChanged);
    riskController.addListener(_onRiskChanged);
  }

  @override
  void dispose() {
    accountController.removeListener(_onAccountChanged);
    riskController.removeListener(_onRiskChanged);
    accountController.dispose();
    riskController.dispose();
    entryController.dispose();
    stopController.dispose();
    openCommissionController.dispose();
    closeCommissionController.dispose();
    for (final tp in _takeProfits.value) {
      tp.dispose();
    }
    super.dispose();
  }

  void addTakeProfit() {
    _takeProfits.value = [..._takeProfits.value, TakeProfitEntry()];
  }

  void removeTakeProfit(int index) {
    if (_takeProfits.value.length <= 1) return;
    final list = [..._takeProfits.value];
    list[index].dispose();
    list.removeAt(index);
    _takeProfits.value = list;
  }

  Future<void> _loadAccountValue() async {
    final depositValue = await model.getDepositValue();
    final riskValue = await model.getRiskValue();

    accountController.text = depositValue;
    riskController.text = riskValue;
  }

  void _onAccountChanged() {
    model.setDepositValue(accountController.text);
  }

  void _onRiskChanged() {
    model.setRiskValue(riskController.text);
  }

  void calculate() {
    final accountSize = double.tryParse(accountController.text) ?? 0;
    final riskPercent = double.tryParse(riskController.text) ?? 0;
    final entry = double.tryParse(entryController.text) ?? 0;
    final stop = double.tryParse(stopController.text) ?? 0;
    final openCommissionPercent =
        double.tryParse(openCommissionController.text) ?? 0;
    final closeCommissionPercent =
        double.tryParse(closeCommissionController.text) ?? 0;

    if (accountSize <= 0 || entry <= 0 || stop <= 0) {
      return;
    }

    double percentSum = 0;
    for (final tp in _takeProfits.value) {
      percentSum += double.tryParse(tp.percentController.text) ?? 0;
    }
    if (percentSum > 100) {
      _validationError.value =
          'Сумма процентов тейк-профитов не должна превышать 100%';
      return;
    }
    _validationError.value = null;

    final riskAmount = accountSize * riskPercent / 100;
    final stopDistance = (entry - stop).abs();
    final openCommissionPerCoin = entry * openCommissionPercent / 100;
    final stopCommissionPerCoin = stop * closeCommissionPercent / 100;
    final totalRiskPerCoin =
        stopDistance + openCommissionPerCoin + stopCommissionPerCoin;
    final sizeCrypto = riskAmount / totalRiskPerCoin;
    final sizeUsd = sizeCrypto * entry;

    final isLong = stop < entry;
    final tpProfits = <double?>[];
    double totalProfit = 0;
    for (final tp in _takeProfits.value) {
      final tpPrice = double.tryParse(tp.priceController.text) ?? 0;
      final tpPercent = double.tryParse(tp.percentController.text) ?? 0;
      if (tpPrice <= 0 || tpPercent <= 0) {
        tpProfits.add(null);
        continue;
      }
      final profitPerCoin = isLong ? tpPrice - entry : entry - tpPrice;
      final tpCommission = tpPrice * closeCommissionPercent / 100;
      final netProfitPerCoin =
          profitPerCoin - openCommissionPerCoin - tpCommission;
      final portion = tpPercent / 100;
      final tpProfit = sizeCrypto * portion * netProfitPerCoin;
      tpProfits.add(tpProfit);
      totalProfit += tpProfit;
    }

    _positionSizeCrypto.value = sizeCrypto;
    _positionSizeUsd.value = sizeUsd;
    _riskUsd.value = riskAmount;
    _tpProfits.value = tpProfits;
    _profitUsd.value = totalProfit;
    _rr.value = riskAmount > 0 ? totalProfit / riskAmount : 0;
  }
}

PositionCalculatorWm positionCalculatorWMFactory({
  required BuildContext context,
}) {
  return PositionCalculatorWm(PositionCalculatorModel(context.read()));
}
