import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

import 'models/balance_model.dart';
import 'models/position_model.dart';

/// Common contract every exchange account repository satisfies, so the app can
/// treat Bybit, OKX and future exchanges through one interface.
abstract interface class ExchangeAccountRepository {
  /// Current balance: seeded by [fetchBalance], kept live by the WS stream.
  ValueListenable<BalanceModel?> get balance;

  /// Open positions: seeded by [fetchPositions], kept live by the WS stream.
  ValueListenable<List<PositionModel>?> get positions;

  Future<Result<BalanceModel, Object>> fetchBalance();

  Future<Result<List<PositionModel>, Object>> fetchPositions();

  void dispose();
}
