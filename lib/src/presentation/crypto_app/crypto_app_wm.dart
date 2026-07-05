import 'dart:async';

import 'package:crypto_position/src/bybit_session_service.dart';
import 'package:crypto_position/src/presentation/crypto_app/crypto_app.dart';
import 'package:crypto_position/src/presentation/crypto_app/crypto_app_model.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// App-level WM: kicks off the Bybit session on start.
class CryptoAppWm extends WidgetModel<CryptoApp, CryptoAppModel> {
  final BybitSessionService _sessionService;

  CryptoAppWm(super.model, {required BybitSessionService sessionService})
    : _sessionService = sessionService;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    unawaited(_sessionService.init());
  }
}

CryptoAppWm cryptoAppWmFactory({required BuildContext context}) {
  return CryptoAppWm(
    CryptoAppModel(),
    sessionService: context.read<BybitSessionService>(),
  );
}
