import 'dart:async';

import 'package:crypto_position/src/bitget_session_service.dart';
import 'package:crypto_position/src/bybit_session_service.dart';
import 'package:crypto_position/src/gate_session_service.dart';
import 'package:crypto_position/src/mexc_session_service.dart';
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
  final BitgetSessionService _bitgetSessionService;
  final GateSessionService _gateSessionService;
  final MexcSessionService _mexcSessionService;

  CryptoAppWm(
    super.model, {
    required BybitSessionService bybitSessionService,
    required OkxSessionService okxSessionService,
    required BitgetSessionService bitgetSessionService,
    required GateSessionService gateSessionService,
    required MexcSessionService mexcSessionService,
  })  : _bybitSessionService = bybitSessionService,
        _okxSessionService = okxSessionService,
        _bitgetSessionService = bitgetSessionService,
        _gateSessionService = gateSessionService,
        _mexcSessionService = mexcSessionService;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    unawaited(_bybitSessionService.init());
    unawaited(_okxSessionService.init());
    unawaited(_bitgetSessionService.init());
    unawaited(_gateSessionService.init());
    unawaited(_mexcSessionService.init());
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
  );
}
