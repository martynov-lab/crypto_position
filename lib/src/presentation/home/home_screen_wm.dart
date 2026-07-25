import 'package:crypto_position/src/bitget_session_service.dart';
import 'package:crypto_position/src/bybit_session_service.dart';
import 'package:crypto_position/src/fees/fee_settings_store.dart';
import 'package:crypto_position/src/gate_session_service.dart';
import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/market_data_registry.dart';
import 'package:crypto_position/src/mexc_session_service.dart';
import 'package:crypto_position/src/okx_session_service.dart';
import 'package:crypto_position/src/presentation/home/exchange_account.dart';
import 'package:crypto_position/src/presentation/home/home_screen.dart';
import 'package:crypto_position/src/presentation/home/home_screen_model.dart';
import 'package:crypto_position/src/trade/exchange_account_registry.dart';
import 'package:crypto_position/src/trade/position_close_controller.dart';
import 'package:crypto_position/src/trade/trade_executor_registry.dart';
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

  final PositionCloseController _closer;

  final _accounts = ValueNotifier<List<ExchangeAccount>>([]);
  final _hasAnyCredentials = ValueNotifier<bool>(false);
  final _loading = ValueNotifier<bool>(false);
  final _selectedKeys = ValueNotifier<Set<String>>(const {});
  final _closeBusy = ValueNotifier<bool>(false);
  final _closeProgress = ValueNotifier<Map<String, CloseProgress>>(const {});
  final _closeReport = ValueNotifier<CloseReport?>(null);

  ValueListenable<List<ExchangeAccount>> get accounts => _accounts;
  ValueListenable<bool> get hasAnyCredentials => _hasAnyCredentials;
  ValueListenable<bool> get loading => _loading;

  /// [positionKey]s of the positions picked for closing. Non-empty means the
  /// list is in selection mode.
  ValueListenable<Set<String>> get selectedKeys => _selectedKeys;

  /// True while a plan is being built or orders are in flight.
  ValueListenable<bool> get closeBusy => _closeBusy;

  /// Latest progress per position key, for the in-flight exit.
  ValueListenable<Map<String, CloseProgress>> get closeProgress =>
      _closeProgress;

  ValueListenable<CloseReport?> get closeReport => _closeReport;

  /// The close strategy's timings, shown in the confirmation dialog so the user
  /// knows when the exit will start crossing the book.
  CloseTuning get tuning => _closer.tuning;

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
    required PositionCloseController closer,
  })  : _bybit = bybit,
        _okx = okx,
        _bitget = bitget,
        _gate = gate,
        _mexc = mexc,
        _closer = closer;

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
    _selectedKeys.dispose();
    _closeBusy.dispose();
    _closeProgress.dispose();
    _closeReport.dispose();
    super.dispose();
  }

  /// Adds or removes one position from the selection. Long-press and tap both
  /// land here; clearing the last one leaves selection mode.
  void toggleSelection(String key) {
    final next = Set<String>.of(_selectedKeys.value);
    if (!next.remove(key)) next.add(key);
    _selectedKeys.value = next;
  }

  void clearSelection() => _selectedKeys.value = const {};

  /// Drops selected keys whose position is no longer open, so a position closed
  /// here (or anywhere else) can't linger in the selection.
  void _pruneSelection(List<ExchangeAccount> accounts) {
    if (_selectedKeys.value.isEmpty) return;
    final open = <String>{
      for (final account in accounts)
        for (final position in account.positions)
          positionKey(account.exchange, position),
    };
    final kept = _selectedKeys.value.where(open.contains).toSet();
    if (kept.length != _selectedKeys.value.length) _selectedKeys.value = kept;
  }

  /// Builds the exit plan for the selected positions. Places no orders — the UI
  /// shows the plan for confirmation first.
  Future<List<ClosePlanItem>> planClose() async {
    final selected = _selectedKeys.value;
    if (selected.isEmpty || _closeBusy.value) return const [];

    final targets = <PositionToClose>[
      for (final account in _accounts.value)
        for (final position in account.positions)
          if (selected.contains(positionKey(account.exchange, position)))
            (exchange: account.exchange, position: position),
    ];
    if (targets.isEmpty) return const [];

    _closeBusy.value = true;
    _closeProgress.value = const {};
    _closeReport.value = null;
    try {
      return await _closer.plan(targets);
    } finally {
      _closeBusy.value = false;
    }
  }

  /// Runs the confirmed plan, then clears the selection and re-reads every
  /// exchange so the list can't show a position that is already gone.
  Future<void> executeClose(List<ClosePlanItem> items) async {
    if (items.isEmpty || _closeBusy.value) return;
    _closeBusy.value = true;
    _closeReport.value = null;
    try {
      _closeReport.value = await _closer.run(
        items,
        onProgress: (progress) {
          _closeProgress.value = {
            ..._closeProgress.value,
            progress.key: progress,
          };
        },
      );
    } finally {
      _closeBusy.value = false;
      clearSelection();
      await refresh();
    }
  }

  /// Stops the running exit after the current step.
  void abortClose() => _closer.abort();

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
    _addAccount(list, ExchangeId.bybit, _bybit.session.value?.repository);
    _addAccount(list, ExchangeId.okx, _okx.session.value?.repository);
    _addAccount(list, ExchangeId.bitget, _bitget.session.value?.repository);
    _addAccount(list, ExchangeId.gate, _gate.session.value?.repository);
    _addAccount(list, ExchangeId.mexc, _mexc.session.value?.repository);
    _accounts.value = list;
    _pruneSelection(list);
  }

  void _addAccount(
    List<ExchangeAccount> list,
    ExchangeId exchange,
    ExchangeAccountRepository? repo,
  ) {
    final balance = repo?.balance.value;
    if (balance == null) return;
    list.add(
      ExchangeAccount(
        exchange: exchange,
        name: exchange.label,
        balance: balance,
        positions: repo?.positions.value ?? const [],
      ),
    );
  }

  /// Pull-to-refresh: re-reads every connected exchange over REST, so stale
  /// state left behind by a missed WS event can always be cleared by hand.
  Future<void> refresh() => Future.wait([
        _bybit.resync(),
        _okx.resync(),
        _bitget.resync(),
        _gate.resync(),
        _mexc.resync(),
      ]);

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
    closer: PositionCloseController(
      executors: context.read<TradeExecutorRegistry>(),
      accounts: context.read<ExchangeAccountRegistry>(),
      market: context.read<MarketDataRegistry>(),
      fees: context.read<FeeSettingsStore>(),
    ),
  );
}
