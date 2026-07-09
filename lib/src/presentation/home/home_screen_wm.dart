import 'package:crypto_position/src/bybit_session_service.dart';
import 'package:crypto_position/src/okx_session_service.dart';
import 'package:crypto_position/src/presentation/home/exchange_account.dart';
import 'package:crypto_position/src/presentation/home/home_screen.dart';
import 'package:crypto_position/src/presentation/home/home_screen_model.dart';
import 'package:elementary/elementary.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Aggregates the balances and open positions of every connected exchange
/// (Bybit, OKX) into a single reactive [accounts] list for the Main tab.
class HomeScreenWm extends WidgetModel<HomeScreen, HomeScreenModel> {
  final BybitSessionService _bybit;
  final OkxSessionService _okx;

  final _accounts = ValueNotifier<List<ExchangeAccount>>([]);
  final _hasAnyCredentials = ValueNotifier<bool>(false);
  final _loading = ValueNotifier<bool>(false);

  ValueListenable<List<ExchangeAccount>> get accounts => _accounts;
  ValueListenable<bool> get hasAnyCredentials => _hasAnyCredentials;
  ValueListenable<bool> get loading => _loading;

  // Repositories currently listened to, so their listeners can be detached
  // when a session is replaced or closed.
  ExchangeAccountRepository? _boundBybitRepo;
  ExchangeAccountRepository? _boundOkxRepo;

  HomeScreenWm(
    super.model, {
    required BybitSessionService bybit,
    required OkxSessionService okx,
  })  : _bybit = bybit,
        _okx = okx;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _bybit.session.addListener(_onSessionsChanged);
    _okx.session.addListener(_onSessionsChanged);
    _bybit.hasCredentials.addListener(_syncStatus);
    _okx.hasCredentials.addListener(_syncStatus);
    _bybit.loading.addListener(_syncStatus);
    _okx.loading.addListener(_syncStatus);
    _onSessionsChanged();
    _syncStatus();
  }

  @override
  void dispose() {
    _bybit.session.removeListener(_onSessionsChanged);
    _okx.session.removeListener(_onSessionsChanged);
    _bybit.hasCredentials.removeListener(_syncStatus);
    _okx.hasCredentials.removeListener(_syncStatus);
    _bybit.loading.removeListener(_syncStatus);
    _okx.loading.removeListener(_syncStatus);
    _unbind(_boundBybitRepo);
    _unbind(_boundOkxRepo);
    _accounts.dispose();
    _hasAnyCredentials.dispose();
    _loading.dispose();
    super.dispose();
  }

  void _onSessionsChanged() {
    _boundBybitRepo = _rebind(_boundBybitRepo, _bybit.session.value?.repository);
    _boundOkxRepo = _rebind(_boundOkxRepo, _okx.session.value?.repository);
    _rebuild();
  }

  /// Detaches from [current] and attaches to [next] when they differ.
  ExchangeAccountRepository? _rebind(
    ExchangeAccountRepository? current,
    ExchangeAccountRepository? next,
  ) {
    if (identical(current, next)) return current;
    _unbind(current);
    next?.balance.addListener(_rebuild);
    next?.positions.addListener(_rebuild);
    return next;
  }

  void _unbind(ExchangeAccountRepository? repo) {
    repo?.balance.removeListener(_rebuild);
    repo?.positions.removeListener(_rebuild);
  }

  void _rebuild() {
    final list = <ExchangeAccount>[];
    _addAccount(list, 'Bybit', _bybit.session.value?.repository);
    _addAccount(list, 'OKX', _okx.session.value?.repository);
    _accounts.value = list;
  }

  void _addAccount(
    List<ExchangeAccount> list,
    String name,
    ExchangeAccountRepository? repo,
  ) {
    final balance = repo?.balance.value;
    if (balance == null) return;
    list.add(
      ExchangeAccount(
        name: name,
        balance: balance,
        positions: repo?.positions.value ?? const [],
      ),
    );
  }

  void _syncStatus() {
    _hasAnyCredentials.value =
        _bybit.hasCredentials.value || _okx.hasCredentials.value;
    _loading.value = _bybit.loading.value || _okx.loading.value;
  }
}

HomeScreenWm homeScreenWmFactory({required BuildContext context}) {
  return HomeScreenWm(
    HomeScreenModel(),
    bybit: context.read<BybitSessionService>(),
    okx: context.read<OkxSessionService>(),
  );
}
