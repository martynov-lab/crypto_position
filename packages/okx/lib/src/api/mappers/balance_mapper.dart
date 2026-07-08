import '../../domain/models/balance_model.dart';
import '../dto/balance_dto.dart';

extension BalanceMapper on BalanceDto {
  BalanceModel toModel() => BalanceModel(
        totalEquity: _parseAmount(totalEq),
        coins: details.map((coin) => coin.toModel()).toList(),
      );
}

extension CoinBalanceMapper on CoinBalanceDto {
  CoinBalanceModel toModel() => CoinBalanceModel(
        coin: ccy,
        equity: _parseAmount(eq),
        cashBalance: _parseAmount(cashBal),
        usdValue: _parseAmount(eqUsd),
        unrealisedPnl: _parseAmount(upl),
      );
}

/// OKX returns '' for fields that are not applicable.
double _parseAmount(String value) => value.isEmpty ? 0 : double.parse(value);
