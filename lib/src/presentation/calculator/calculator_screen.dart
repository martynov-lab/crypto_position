import 'package:crypto_position/src/presentation/arbitrage_calculator/arbitrage_calculator.dart';
import 'package:crypto_position/src/presentation/position_calculator/position_calculator.dart';
import 'package:flutter/material.dart';

/// Calculator tab: hosts the position-size calculator and the arbitrage
/// calculator behind a [TabBar].
class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Калькулятор'),
              Tab(text: 'Арбитраж'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PositionCalculator(),
            ArbitrageCalculator(),
          ],
        ),
      ),
    );
  }
}
