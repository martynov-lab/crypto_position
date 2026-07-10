import 'package:crypto_position/src/bitget_session_service.dart';
import 'package:crypto_position/src/bybit_session_service.dart';
import 'package:crypto_position/src/gate_session_service.dart';
import 'package:crypto_position/src/mexc_session_service.dart';
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
  final BitgetSessionService _bitget;
  final GateSessionService _gate;
  final MexcSessionService _mexc;

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
  ExchangeAccountRepository? _boundBitgetRepo;
  ExchangeAccountRepository? _boundGateRepo;
  ExchangeAccountRepository? _boundMexcRepo;

  HomeScreenWm(
    super.model, {
    required BybitSessionService bybit,
    required OkxSessionService okx,
    required BitgetSessionService bitget,
    required GateSessionService gate,
    required MexcSessionService mexc,
  })  : _bybit = bybit,
        _okx = okx,
        _bitget = bitget,
        _gate = gate,
        _mexc = mexc;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _bybit.session.addListener(_onSessionsChanged);
    _okx.session.addListener(_onSessionsChanged);
    _bitget.session.addListener(_onSessionsChanged);
    _gate.session.addListener(_onSessionsChanged);
    _mexc.session.addListener(_onSessionsChanged);
    _bybit.hasCredentials.addListener(_syncStatus);
    _okx.hasCredentials.addListener(_syncStatus);
    _bitget.hasCredentials.addListener(_syncStatus);
    _gate.hasCredentials.addListener(_syncStatus);
    _mexc.hasCredentials.addListener(_syncStatus);
    _bybit.loading.addListener(_syncStatus);
    _okx.loading.addListener(_syncStatus);
    _bitget.loading.addListener(_syncStatus);
    _gate.loading.addListener(_syncStatus);
    _mexc.loading.addListener(_syncStatus);
    _onSessionsChanged();
    _syncStatus();
  }

  @override
  void dispose() {
    _bybit.session.removeListener(_onSessionsChanged);
    _okx.session.removeListener(_onSessionsChanged);
    _bitget.session.removeListener(_onSessionsChanged);
    _gate.session.removeListener(_onSessionsChanged);
    _mexc.session.removeListener(_onSessionsChanged);
    _bybit.hasCredentials.removeListener(_syncStatus);
    _okx.hasCredentials.removeListener(_syncStatus);
    _bitget.hasCredentials.removeListener(_syncStatus);
    _gate.hasCredentials.removeListener(_syncStatus);
    _mexc.hasCredentials.removeListener(_syncStatus);
    _bybit.loading.removeListener(_syncStatus);
    _okx.loading.removeListener(_syncStatus);
    _bitget.loading.removeListener(_syncStatus);
    _gate.loading.removeListener(_syncStatus);
    _mexc.loading.removeListener(_syncStatus);
    _unbind(_boundBybitRepo);
    _unbind(_boundOkxRepo);
    _unbind(_boundBitgetRepo);
    _unbind(_boundGateRepo);
    _unbind(_boundMexcRepo);
    _accounts.dispose();
    _hasAnyCredentials.dispose();
    _loading.dispose();
    super.dispose();
  }

  void _onSessionsChanged() {
    _boundBybitRepo = _rebind(_boundBybitRepo, _bybit.session.value?.repository);
    _boundOkxRepo = _rebind(_boundOkxRepo, _okx.session.value?.repository);
    _boundBitgetRepo =
        _rebind(_boundBitgetRepo, _bitget.session.value?.repository);
    _boundGateRepo = _rebind(_boundGateRepo, _gate.session.value?.repository);
    _boundMexcRepo = _rebind(_boundMexcRepo, _mexc.session.value?.repository);
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
    _addAccount(list, 'Bitget', _bitget.session.value?.repository);
    _addAccount(list, 'Gate', _gate.session.value?.repository);
    _addAccount(list, 'MEXC', _mexc.session.value?.repository);
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
    _hasAnyCredentials.value = _bybit.hasCredentials.value ||
        _okx.hasCredentials.value ||
        _bitget.hasCredentials.value ||
        _gate.hasCredentials.value ||
        _mexc.hasCredentials.value;
    _loading.value = _bybit.loading.value ||
        _okx.loading.value ||
        _bitget.loading.value ||
        _gate.loading.value ||
        _mexc.loading.value;
  }
}

HomeScreenWm homeScreenWmFactory({required BuildContext context}) {
  return HomeScreenWm(
    HomeScreenModel(),
    bybit: context.read<BybitSessionService>(),
    okx: context.read<OkxSessionService>(),
    bitget: context.read<BitgetSessionService>(),
    gate: context.read<GateSessionService>(),
    mexc: context.read<MexcSessionService>(),
  );
}
