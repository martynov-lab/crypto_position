import 'package:crypto_position/src/bybit_account_session.dart';
import 'package:crypto_position/src/bybit_session_service.dart';
import 'package:crypto_position/src/presentation/home/home_screen.dart';
import 'package:crypto_position/src/presentation/home/home_screen_model.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreenWm extends WidgetModel<HomeScreen, HomeScreenModel> {
  final BybitSessionService _sessionService;

  ValueListenable<bool> get hasCredentials => _sessionService.hasCredentials;
  ValueListenable<bool> get loading => _sessionService.loading;
  ValueListenable<String?> get error => _sessionService.error;
  ValueListenable<BybitAccountSession?> get session => _sessionService.session;

  HomeScreenWm(super.model, {required BybitSessionService sessionService})
    : _sessionService = sessionService;
}

HomeScreenWm homeScreenWmFactory({required BuildContext context}) {
  return HomeScreenWm(
    HomeScreenModel(),
    sessionService: context.read<BybitSessionService>(),
  );
}
