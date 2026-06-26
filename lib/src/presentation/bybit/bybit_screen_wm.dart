import 'dart:async';

import 'package:bybit_api/bybit_api.dart';
import 'package:crypto_position/src/presentation/bybit/bybit_screen.dart';
import 'package:crypto_position/src/presentation/bybit/bybit_screen_model.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BybitScreenWm extends WidgetModel<BybitScreen, BybitScreenModel> {
  final apiKeyController = TextEditingController();
  final apiSecretController = TextEditingController();

  final ValueNotifier<bool> _hasCredentials = ValueNotifier(false);
  final ValueNotifier<WalletBalance?> _balance = ValueNotifier(null);
  final ValueNotifier<bool> _loading = ValueNotifier(false);
  final ValueNotifier<String?> _error = ValueNotifier(null);

  ValueListenable<bool> get hasCredentials => _hasCredentials;
  ValueListenable<WalletBalance?> get balance => _balance;
  ValueListenable<bool> get loading => _loading;
  ValueListenable<String?> get error => _error;

  BybitRepository? _repository;
  StreamSubscription? _wsSub;

  BybitScreenWm(super.model);

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _checkCredentials();
  }

  @override
  void dispose() {
    apiKeyController.dispose();
    apiSecretController.dispose();
    _wsSub?.cancel();
    _repository?.dispose();
    super.dispose();
  }

  Future<void> _checkCredentials() async {
    final apiKey = await model.getApiKey();
    final apiSecret = await model.getApiSecret();
    if (apiKey != null && apiSecret != null && apiKey.isNotEmpty) {
      _hasCredentials.value = true;
      _connectApi(apiKey, apiSecret);
    }
  }

  Future<void> saveCredentials() async {
    final key = apiKeyController.text.trim();
    final secret = apiSecretController.text.trim();
    if (key.isEmpty || secret.isEmpty) return;

    await model.saveCredentials(key, secret);
    _hasCredentials.value = true;
    _connectApi(key, secret);
  }

  Future<void> logout() async {
    _wsSub?.cancel();
    _repository?.dispose();
    _repository = null;
    _balance.value = null;
    await model.clearCredentials();
    _hasCredentials.value = false;
  }

  Future<void> _connectApi(String apiKey, String apiSecret) async {
    _loading.value = true;
    _error.value = null;

    _repository = BybitRepository(apiKey: apiKey, apiSecret: apiSecret);

    try {
      final walletBalance = await _repository!.fetchBalance();
      _balance.value = walletBalance;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _loading.value = false;
    }

    _wsSub = _repository!.walletUpdates.listen((update) {
      _balance.value = update;
    });
    _repository!.connectWs();
  }
}

BybitScreenWm bybitScreenWmFactory({required BuildContext context}) {
  return BybitScreenWm(BybitScreenModel());
}
