import 'dart:async';

import 'package:crypto_position/src/bitget_session_service.dart';
import 'package:crypto_position/src/bybit_session_service.dart';
import 'package:crypto_position/src/gate_session_service.dart';
import 'package:crypto_position/src/keep_alive_service.dart';
import 'package:crypto_position/src/mexc_session_service.dart';
import 'package:crypto_position/src/okx_session_service.dart';
import 'package:crypto_position/src/screener_service.dart';
import 'package:crypto_position/src/presentation/crypto_app/crypto_app.dart';
import 'package:crypto_position/src/presentation/crypto_app/crypto_app_model.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// App-level WM: kicks off the exchange sessions on start.
class CryptoAppWm extends WidgetModel<CryptoApp, CryptoAppModel> {
  final BybitSessionService _bybitSessionService;
  final OkxSessionService _okxSessionService;
  final BitgetSessionService _bitgetSessionService;
  final GateSessionService _gateSessionService;
  final MexcSessionService _mexcSessionService;
  final ScreenerService _screenerService;
  final KeepAliveService _keepAliveService;

  CryptoAppWm(
    super.model, {
    required BybitSessionService bybitSessionService,
    required OkxSessionService okxSessionService,
    required BitgetSessionService bitgetSessionService,
    required GateSessionService gateSessionService,
    required MexcSessionService mexcSessionService,
    required ScreenerService screenerService,
    required KeepAliveService keepAliveService,
  })  : _bybitSessionService = bybitSessionService,
        _okxSessionService = okxSessionService,
        _bitgetSessionService = bitgetSessionService,
        _gateSessionService = gateSessionService,
        _mexcSessionService = mexcSessionService,
        _screenerService = screenerService,
        _keepAliveService = keepAliveService;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    unawaited(_bybitSessionService.init());
    unawaited(_okxSessionService.init());
    unawaited(_bitgetSessionService.init());
    unawaited(_gateSessionService.init());
    unawaited(_mexcSessionService.init());
    _screenerService.init();
    unawaited(_keepAliveService.start());
  }
}

CryptoAppWm cryptoAppWmFactory({required BuildContext context}) {
  return CryptoAppWm(
    CryptoAppModel(),
    bybitSessionService: context.read<BybitSessionService>(),
    okxSessionService: context.read<OkxSessionService>(),
    bitgetSessionService: context.read<BitgetSessionService>(),
    gateSessionService: context.read<GateSessionService>(),
    mexcSessionService: context.read<MexcSessionService>(),
    screenerService: context.read<ScreenerService>(),
    keepAliveService: context.read<KeepAliveService>(),
  );
}
