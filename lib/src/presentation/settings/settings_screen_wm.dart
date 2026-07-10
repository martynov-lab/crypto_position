import 'package:crypto_position/src/bitget_session_service.dart';
import 'package:crypto_position/src/bybit_session_service.dart';
import 'package:crypto_position/src/gate_session_service.dart';
import 'package:crypto_position/src/mexc_session_service.dart';
import 'package:crypto_position/src/okx_session_service.dart';
import 'package:crypto_position/src/presentation/settings/settings_screen.dart';
import 'package:crypto_position/src/presentation/settings/settings_screen_model.dart';
import 'package:crypto_position/src/presentation/settings/widgets/settings_view.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Settings tab: manages the API-key connections for every exchange
/// (Bybit, OKX). Reads the session services and drives connect/logout.
class SettingsScreenWm
    extends WidgetModel<SettingsScreen, SettingsScreenModel> {
  final apiKeyController = TextEditingController();
  final apiSecretController = TextEditingController();
  final okxApiKeyController = TextEditingController();
  final okxApiSecretController = TextEditingController();
  final okxPassphraseController = TextEditingController();
  final bitgetApiKeyController = TextEditingController();
  final bitgetApiSecretController = TextEditingController();
  final bitgetPassphraseController = TextEditingController();
  final gateApiKeyController = TextEditingController();
  final gateApiSecretController = TextEditingController();
  final mexcApiKeyController = TextEditingController();
  final mexcApiSecretController = TextEditingController();

  final BybitSessionService _sessionService;
  final OkxSessionService _okxSessionService;
  final BitgetSessionService _bitgetSessionService;
  final GateSessionService _gateSessionService;
  final MexcSessionService _mexcSessionService;

  SettingsScreenWm(
    super.model, {
    required BybitSessionService sessionService,
    required OkxSessionService okxSessionService,
    required BitgetSessionService bitgetSessionService,
    required GateSessionService gateSessionService,
    required MexcSessionService mexcSessionService,
  })  : _sessionService = sessionService,
        _okxSessionService = okxSessionService,
        _bitgetSessionService = bitgetSessionService,
        _gateSessionService = gateSessionService,
        _mexcSessionService = mexcSessionService;

  /// Connection cards, one per exchange. Reads the current state of both
  /// session services; [connectionsListenable] triggers rebuilds when any of
  /// that state changes.
  List<ExchangeConnection> get connections => [
    ExchangeConnection(
      title: 'Подключение к Bybit',
      hasCredentials: _sessionService.hasCredentials.value,
      loading: _sessionService.loading.value,
      error: _sessionService.error.value,
      apiKeyController: apiKeyController,
      apiSecretController: apiSecretController,
      onSaveCredentials: saveCredentials,
      onLogout: logout,
    ),
    ExchangeConnection(
      title: 'Подключение к OKX',
      hasCredentials: _okxSessionService.hasCredentials.value,
      loading: _okxSessionService.loading.value,
      error: _okxSessionService.error.value,
      apiKeyController: okxApiKeyController,
      apiSecretController: okxApiSecretController,
      passphraseController: okxPassphraseController,
      onSaveCredentials: saveOkxCredentials,
      onLogout: okxLogout,
    ),
    ExchangeConnection(
      title: 'Подключение к Bitget',
      hasCredentials: _bitgetSessionService.hasCredentials.value,
      loading: _bitgetSessionService.loading.value,
      error: _bitgetSessionService.error.value,
      apiKeyController: bitgetApiKeyController,
      apiSecretController: bitgetApiSecretController,
      passphraseController: bitgetPassphraseController,
      onSaveCredentials: saveBitgetCredentials,
      onLogout: bitgetLogout,
    ),
    ExchangeConnection(
      title: 'Подключение к Gate',
      hasCredentials: _gateSessionService.hasCredentials.value,
      loading: _gateSessionService.loading.value,
      error: _gateSessionService.error.value,
      apiKeyController: gateApiKeyController,
      apiSecretController: gateApiSecretController,
      onSaveCredentials: saveGateCredentials,
      onLogout: gateLogout,
    ),
    ExchangeConnection(
      title: 'Подключение к MEXC',
      hasCredentials: _mexcSessionService.hasCredentials.value,
      loading: _mexcSessionService.loading.value,
      error: _mexcSessionService.error.value,
      apiKeyController: mexcApiKeyController,
      apiSecretController: mexcApiSecretController,
      onSaveCredentials: saveMexcCredentials,
      onLogout: mexcLogout,
    ),
  ];

  Listenable get connectionsListenable => Listenable.merge([
    _sessionService.hasCredentials,
    _sessionService.loading,
    _sessionService.error,
    _okxSessionService.hasCredentials,
    _okxSessionService.loading,
    _okxSessionService.error,
    _bitgetSessionService.hasCredentials,
    _bitgetSessionService.loading,
    _bitgetSessionService.error,
    _gateSessionService.hasCredentials,
    _gateSessionService.loading,
    _gateSessionService.error,
    _mexcSessionService.hasCredentials,
    _mexcSessionService.loading,
    _mexcSessionService.error,
  ]);

  @override
  void dispose() {
    apiKeyController.dispose();
    apiSecretController.dispose();
    okxApiKeyController.dispose();
    okxApiSecretController.dispose();
    okxPassphraseController.dispose();
    bitgetApiKeyController.dispose();
    bitgetApiSecretController.dispose();
    bitgetPassphraseController.dispose();
    gateApiKeyController.dispose();
    gateApiSecretController.dispose();
    mexcApiKeyController.dispose();
    mexcApiSecretController.dispose();
    super.dispose();
  }

  Future<void> saveCredentials() async {
    final key = apiKeyController.text.trim();
    final secret = apiSecretController.text.trim();
    if (key.isEmpty || secret.isEmpty) return;

    await _sessionService.saveCredentials(key, secret);
  }

  Future<void> logout() async {
    await _sessionService.logout();
  }

  Future<void> saveOkxCredentials() async {
    final key = okxApiKeyController.text.trim();
    final secret = okxApiSecretController.text.trim();
    final passphrase = okxPassphraseController.text.trim();
    if (key.isEmpty || secret.isEmpty || passphrase.isEmpty) return;

    await _okxSessionService.saveCredentials(key, secret, passphrase);
  }

  Future<void> okxLogout() async {
    await _okxSessionService.logout();
  }

  Future<void> saveBitgetCredentials() async {
    final key = bitgetApiKeyController.text.trim();
    final secret = bitgetApiSecretController.text.trim();
    final passphrase = bitgetPassphraseController.text.trim();
    if (key.isEmpty || secret.isEmpty || passphrase.isEmpty) return;

    await _bitgetSessionService.saveCredentials(key, secret, passphrase);
  }

  Future<void> bitgetLogout() async {
    await _bitgetSessionService.logout();
  }

  Future<void> saveGateCredentials() async {
    final key = gateApiKeyController.text.trim();
    final secret = gateApiSecretController.text.trim();
    if (key.isEmpty || secret.isEmpty) return;

    await _gateSessionService.saveCredentials(key, secret);
  }

  Future<void> gateLogout() async {
    await _gateSessionService.logout();
  }

  Future<void> saveMexcCredentials() async {
    final key = mexcApiKeyController.text.trim();
    final secret = mexcApiSecretController.text.trim();
    if (key.isEmpty || secret.isEmpty) return;

    await _mexcSessionService.saveCredentials(key, secret);
  }

  Future<void> mexcLogout() async {
    await _mexcSessionService.logout();
  }
}

SettingsScreenWm settingsScreenWmFactory({required BuildContext context}) {
  return SettingsScreenWm(
    SettingsScreenModel(),
    sessionService: context.read<BybitSessionService>(),
    okxSessionService: context.read<OkxSessionService>(),
    bitgetSessionService: context.read<BitgetSessionService>(),
    gateSessionService: context.read<GateSessionService>(),
    mexcSessionService: context.read<MexcSessionService>(),
  );
}
