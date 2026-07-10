import 'package:core/core.dart';
import 'package:crypto_position/src/bitget_session_service.dart';
import 'package:crypto_position/src/bybit_session_service.dart';
import 'package:crypto_position/src/gate_session_service.dart';
import 'package:crypto_position/src/okx_session_service.dart';
import 'package:crypto_position/src/presentation/journal/exchange_journal.dart';
import 'package:crypto_position/src/presentation/journal/journal_screen.dart';
import 'package:crypto_position/src/presentation/journal/journal_screen_model.dart';
import 'package:elementary/elementary.dart';
import 'package:exchange/exchange.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Journal tab: a per-exchange closed-trades journal (Bybit, OKX), each backed
/// by its own [ExchangeJournal] and reloaded when its session connects.
class JournalScreenWm extends WidgetModel<JournalScreen, JournalScreenModel> {
  final BybitSessionService _bybit;
  final OkxSessionService _okx;
  final BitgetSessionService _bitget;
  final GateSessionService _gate;

  late final ExchangeJournal bybitJournal = ExchangeJournal(_fetchBybit);
  late final ExchangeJournal okxJournal = ExchangeJournal(_fetchOkx);
  late final ExchangeJournal bitgetJournal = ExchangeJournal(_fetchBitget);
  late final ExchangeJournal gateJournal = ExchangeJournal(_fetchGate);

  ValueListenable<bool> get bybitHasCredentials => _bybit.hasCredentials;
  ValueListenable<bool> get okxHasCredentials => _okx.hasCredentials;
  ValueListenable<bool> get bitgetHasCredentials => _bitget.hasCredentials;
  ValueListenable<bool> get gateHasCredentials => _gate.hasCredentials;

  JournalScreenWm(
    super.model, {
    required BybitSessionService bybit,
    required OkxSessionService okx,
    required BitgetSessionService bitget,
    required GateSessionService gate,
  })  : _bybit = bybit,
        _okx = okx,
        _bitget = bitget,
        _gate = gate;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _bybit.session.addListener(_onBybitSessionChanged);
    _okx.session.addListener(_onOkxSessionChanged);
    _bitget.session.addListener(_onBitgetSessionChanged);
    _gate.session.addListener(_onGateSessionChanged);
    if (_bybit.session.value != null) bybitJournal.load();
    if (_okx.session.value != null) okxJournal.load();
    if (_bitget.session.value != null) bitgetJournal.load();
    if (_gate.session.value != null) gateJournal.load();
  }

  @override
  void dispose() {
    _bybit.session.removeListener(_onBybitSessionChanged);
    _okx.session.removeListener(_onOkxSessionChanged);
    _bitget.session.removeListener(_onBitgetSessionChanged);
    _gate.session.removeListener(_onGateSessionChanged);
    bybitJournal.dispose();
    okxJournal.dispose();
    bitgetJournal.dispose();
    gateJournal.dispose();
    super.dispose();
  }

  void _onBybitSessionChanged() {
    _bybit.session.value != null ? bybitJournal.load() : bybitJournal.clear();
  }

  void _onOkxSessionChanged() {
    _okx.session.value != null ? okxJournal.load() : okxJournal.clear();
  }

  void _onBitgetSessionChanged() {
    _bitget.session.value != null
        ? bitgetJournal.load()
        : bitgetJournal.clear();
  }

  void _onGateSessionChanged() {
    _gate.session.value != null ? gateJournal.load() : gateJournal.clear();
  }

  Future<Result<List<ClosedTradeModel>, Object>> _fetchBybit(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final session = _bybit.session.value;
    if (session == null) return const Ok([]);

    final all = <ClosedTradeModel>[];
    for (final category in ['linear', 'inverse']) {
      final result = await session.repository.fetchClosedTrades(
        category: category,
        startDate: startDate,
        endDate: endDate,
      );
      switch (result) {
        case Ok(:final value):
          all.addAll(value);
        case Err(:final error):
          return Err(error);
      }
    }
    return Ok(all);
  }

  Future<Result<List<ClosedTradeModel>, Object>> _fetchOkx(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final session = _okx.session.value;
    if (session == null) return const Ok([]);

    return session.repository.fetchClosedTrades(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<Result<List<ClosedTradeModel>, Object>> _fetchBitget(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final session = _bitget.session.value;
    if (session == null) return const Ok([]);

    return session.repository.fetchClosedTrades(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<Result<List<ClosedTradeModel>, Object>> _fetchGate(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final session = _gate.session.value;
    if (session == null) return const Ok([]);

    return session.repository.fetchClosedTrades(
      startDate: startDate,
      endDate: endDate,
    );
  }
}

JournalScreenWm journalScreenWmFactory({required BuildContext context}) {
  return JournalScreenWm(
    JournalScreenModel(),
    bybit: context.read<BybitSessionService>(),
    okx: context.read<OkxSessionService>(),
    bitget: context.read<BitgetSessionService>(),
    gate: context.read<GateSessionService>(),
  );
}
