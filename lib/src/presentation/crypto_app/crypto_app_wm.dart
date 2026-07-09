import 'dart:async';

import 'package:crypto_position/src/bybit_session_service.dart';
import 'package:crypto_position/src/okx_session_service.dart';
import 'package:crypto_position/src/presentation/crypto_app/crypto_app.dart';
import 'package:crypto_position/src/presentation/crypto_app/crypto_app_model.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// App-level WM: kicks off the exchange sessions on start.
class CryptoAppWm extends WidgetModel<CryptoApp, CryptoAppModel> {
  final BybitSessionService _bybitSessionService;
  final OkxSessionService _okxSessionService;

  CryptoAppWm(
    super.model, {
    required BybitSessionService bybitSessionService,
    required OkxSessionService okxSessionService,
  })  : _bybitSessionService = bybitSessionService,
        _okxSessionService = okxSessionService;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    unawaited(_bybitSessionService.init());
    unawaited(_okxSessionService.init());
  }
}

CryptoAppWm cryptoAppWmFactory({required BuildContext context}) {
  return CryptoAppWm(
    CryptoAppModel(),
    bybitSessionService: context.read<BybitSessionService>(),
    okxSessionService: context.read<OkxSessionService>(),
  );
}
