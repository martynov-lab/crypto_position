import 'package:core/core.dart';
import 'package:crypto_position/src/presentation/screener/settings_reference.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screener/screener.dart';
import 'package:ui_kit/ui_kit.dart';

/// Filters form mapping 1:1 to [ClientConfig]. Seeds from the documented server
/// defaults, validates via `POST /config/validate`, and re-subscribes on apply.
class FiltersView extends StatefulWidget {
  final ClientConfig initial;
  final void Function(ClientConfig) onApply;
  final Future<Result<ConfigValidation, Object>> Function(ClientConfig)
      onValidate;

  const FiltersView({
    super.key,
    required this.initial,
    required this.onApply,
    required this.onValidate,
  });

  @override
  State<FiltersView> createState() => _FiltersViewState();
}

/// Selectable market-kind combos for `market_pairs`. Only perp/perp is live
/// server-side today; the spot legs are accepted ahead of the spot ingest.
const _marketPairChoices = <(MarketPair, String)>[
  (MarketPair.perpPerp, 'фьюч/фьюч'),
  (MarketPair(buy: 'spot', sell: 'spot'), 'спот/спот'),
  (MarketPair(buy: 'spot', sell: 'perp'), 'спот/фьюч'),
  (MarketPair(buy: 'perp', sell: 'spot'), 'фьюч/спот'),
];

class _FiltersViewState extends State<FiltersView>
    with AutomaticKeepAliveClientMixin<FiltersView> {
  // The form's edits live only in local state (`_text`/`_exchanges`), seeded
  // once from `widget.initial` in initState. Without this mixin, TabBarView
  // disposes this page once it scrolls far enough from the visible tab (no
  // keep-alive by default) — reopening it then re-runs initState with
  // `initial` frozen at whatever it was when ScreenerScreen last built (e.g.
  // app start), silently discarding any filters applied since.
  @override
  bool get wantKeepAlive => true;

  late final Map<String, TextEditingController> _text;
  late final Set<String> _exchanges;
  late final Set<MarketPair> _marketPairs;
  late bool _includeFunding;
  late bool _includeFundingCost;
  late bool _enableDynamics;
  late bool _requireTransferable;
  late bool _requireCommonNetwork;

  @override
  void initState() {
    super.initState();
    final config = widget.initial;
    _text = {
      'quote': TextEditingController(text: config.quote ?? ScreenerDefaults.quote),
      // Percent fields: stored/sent as fractions ("0.006" = 0.6%), shown and
      // edited here as plain percent numbers ("0.6") — friendlier to type.
      'minNet':
          _seedPercent(config.minNetSpreadPct, ScreenerDefaults.minNetSpreadPct),
      'alertNet': _seedPercent(
          config.alertNetSpreadPct, ScreenerDefaults.alertNetSpreadPct),
      'maxNet':
          _seedPercent(config.maxNetSpreadPct, ScreenerDefaults.maxNetSpreadPct),
      'minRoundTrip': _seedPercent(
          config.minRoundTripPct, ScreenerDefaults.minRoundTripPct),
      'targetNotional':
          _seed(config.targetNotionalQ, ScreenerDefaults.targetNotionalQ),
      'minExecutable': _seed(
          config.minExecutableNotional, ScreenerDefaults.minExecutableNotional),
      'depthLevels': _seed(config.depthLevelsN, ScreenerDefaults.depthLevelsN),
      // Millisecond fields: stored/sent as ms, shown and edited in seconds.
      'maxBookAge':
          _seedSeconds(config.maxBookAgeMs, ScreenerDefaults.maxBookAgeMs),
      'maxLegSkew':
          _seedSeconds(config.maxLegSkewMs, ScreenerDefaults.maxLegSkewMs),
      'maxPriceDeviation': _seedPercent(
          config.maxPriceDeviationPct, ScreenerDefaults.maxPriceDeviationPct),
      'minFundingApr': _seedPercent(
          config.minFundingDiffApr, ScreenerDefaults.minFundingDiffApr),
      'fundingHold':
          _seed(config.fundingHoldHours, ScreenerDefaults.fundingHoldHours),
      'maxBaseline': _seedPercent(
          config.maxBaselineSpreadPct, ScreenerDefaults.maxBaselineSpreadPct),
      'minSpikeZ': _seed(config.minSpikeZ, ScreenerDefaults.minSpikeZ),
      'spikeBypassMult': _seed(
          config.spikeBypassRoundTripMult,
          ScreenerDefaults.spikeBypassRoundTripMult),
      'maxSpreadDuration': _seedSeconds(
          config.maxSpreadDurationMs, ScreenerDefaults.maxSpreadDurationMs),
      'minSamples':
          _seed(config.minDynamicsSamples, ScreenerDefaults.minDynamicsSamples),
      'maxChartSpread': _seedPercent(
          config.maxChartSpreadPct, ScreenerDefaults.maxChartSpreadPct),
      // Shown in days (the server retention/query window is measured in
      // days-scale spans, e.g. the 3-day default), sent as ms.
      'historyWindow':
          _seedDays(config.historyWindowMs, ScreenerDefaults.historyWindowMs),
      'hysteresis': _seedPercent(
          config.hysteresisStepPct, ScreenerDefaults.hysteresisStepPct),
      'episodeCloseTicks':
          _seed(config.episodeCloseTicks, ScreenerDefaults.episodeCloseTicks),
      'minLifetime': _seedSeconds(
          config.minSignalLifetimeMs, ScreenerDefaults.minSignalLifetimeMs),
      'cooldown': _seedSeconds(config.cooldownMs, ScreenerDefaults.cooldownMs),
      'maxPerMin':
          _seed(config.maxSignalsPerMin, ScreenerDefaults.maxSignalsPerMin),
      'allow': TextEditingController(text: config.allowSymbols?.join(', ') ?? ''),
      'deny': TextEditingController(text: config.denySymbols?.join(', ') ?? ''),
      'minVolume':
          _seed(config.min24hQuoteVolume, ScreenerDefaults.min24hQuoteVolume),
      // No documented default (ceiling off unless the user sets one);
      // blank round-trips as `maxVolumeOff` = ceiling off.
      'maxVolume': TextEditingController(text: config.max24hQuoteVolume ?? ''),
      'minOi': TextEditingController(text: config.minOpenInterest ?? ''),
    };
    _exchanges = {...(config.exchanges ?? ScreenerDefaults.allExchanges)};
    _marketPairs = {...(config.marketPairs ?? ScreenerDefaults.marketPairs)};
    _includeFunding =
        config.includeFundingDiff ?? ScreenerDefaults.includeFundingDiff;
    _includeFundingCost =
        config.includeFundingCost ?? ScreenerDefaults.includeFundingCost;
    _enableDynamics = config.enableDynamics ?? ScreenerDefaults.enableDynamics;
    _requireTransferable =
        config.requireTransferable ?? ScreenerDefaults.requireTransferable;
    _requireCommonNetwork =
        config.requireCommonNetwork ?? ScreenerDefaults.requireCommonNetwork;
  }

  static TextEditingController _seed(Object? fromConfig, Object defaultValue) =>
      TextEditingController(text: '${fromConfig ?? defaultValue}');

  /// Seeds a percent field: the wire value is a fraction ("0.006" = 0.6%),
  /// shown/edited here as a plain percent number ("0.6").
  static TextEditingController _seedPercent(
    String? fromConfig,
    String defaultFraction,
  ) =>
      TextEditingController(
        text: Decimals.toPercentInput(fromConfig) ??
            Decimals.toPercentInput(defaultFraction)!,
      );

  /// Reads a percent field back to the wire fraction, or `null` if left blank.
  static String? _readPercent(String text) => Decimals.fromPercentInput(text);

  /// Seeds a millisecond field: the wire value is ms, shown/edited here in
  /// seconds (may be fractional, e.g. 750 ms -> "0.75").
  static TextEditingController _seedSeconds(int? fromConfigMs, int defaultMs) =>
      TextEditingController(text: _msToSeconds(fromConfigMs ?? defaultMs));

  static String _msToSeconds(int ms) {
    if (ms % 1000 == 0) return (ms ~/ 1000).toString();
    var s = (ms / 1000).toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }

  /// Reads a seconds field back to whole milliseconds, or `null` if blank.
  static int? _readSeconds(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final seconds = double.tryParse(trimmed);
    if (seconds == null) return null;
    return (seconds * 1000).round();
  }

  static const _msPerDay = 86400000;

  /// Seeds a millisecond field shown/edited in days (may be fractional, e.g.
  /// half a day -> "0.5"). Used only for `history_window_ms`.
  static TextEditingController _seedDays(int? fromConfigMs, int defaultMs) =>
      TextEditingController(text: _msToDays(fromConfigMs ?? defaultMs));

  static String _msToDays(int ms) {
    if (ms % _msPerDay == 0) return (ms ~/ _msPerDay).toString();
    var s = (ms / _msPerDay).toStringAsFixed(4);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }

  /// Reads a days field back to whole milliseconds, or `null` if blank.
  static int? _readDays(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final days = double.tryParse(trimmed);
    if (days == null) return null;
    return (days * _msPerDay).round();
  }

  /// Normalizes a user-typed symbol to its base asset: strips a `/QUOTE` or
  /// trailing `USDT` so "BBUSDT" / "BB/USDT" / "bb" all become "BB". The server
  /// matches deny/allow on the base asset only, case-insensitively.
  static String _baseAsset(String raw) {
    var symbol = raw.toUpperCase();
    final slash = symbol.indexOf('/');
    if (slash >= 0) symbol = symbol.substring(0, slash);
    const quote = 'USDT';
    if (symbol.length > quote.length && symbol.endsWith(quote)) {
      symbol = symbol.substring(0, symbol.length - quote.length);
    }
    return symbol;
  }

  @override
  void dispose() {
    for (final controller in _text.values) {
      controller.dispose();
    }
    super.dispose();
  }

  ClientConfig _buildConfig() {
    String? str(String key) {
      final value = _text[key]!.text.trim();
      return value.isEmpty ? null : value;
    }

    int? intVal(String key) => int.tryParse(_text[key]!.text.trim());

    List<String>? csv(String key) {
      final parts = _text[key]!
          .text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts;
    }

    // allow/deny match on the base asset only: "BBUSDT" / "BB/USDT" → "BB".
    List<String>? symbols(String key) => csv(key)?.map(_baseAsset).toList();

    return ClientConfig(
      exchanges:
          _exchanges.length == ScreenerDefaults.allExchanges.length
              ? null
              : _exchanges.toList(),
      quote: str('quote'),
      allowSymbols: symbols('allow'),
      denySymbols: symbols('deny'),
      marketPairs: setEquals(_marketPairs, {...ScreenerDefaults.marketPairs})
          ? null
          : _marketPairs.toList(),
      min24hQuoteVolume: str('minVolume'),
      // Cleared field → explicit null on the wire → ceiling off.
      max24hQuoteVolume:
          str('maxVolume') ?? ClientConfig.maxVolumeOff,
      minOpenInterest: str('minOi'),
      minNetSpreadPct: _readPercent(_text['minNet']!.text),
      alertNetSpreadPct: _readPercent(_text['alertNet']!.text),
      maxNetSpreadPct: _readPercent(_text['maxNet']!.text),
      minRoundTripPct: _readPercent(_text['minRoundTrip']!.text),
      targetNotionalQ: str('targetNotional'),
      minExecutableNotional: str('minExecutable'),
      depthLevelsN: intVal('depthLevels'),
      includeFundingDiff: _includeFunding,
      minFundingDiffApr: _readPercent(_text['minFundingApr']!.text),
      fundingHoldHours: str('fundingHold'),
      includeFundingCost: _includeFundingCost,
      requireTransferable: _requireTransferable,
      requireCommonNetwork: _requireCommonNetwork,
      maxBookAgeMs: _readSeconds(_text['maxBookAge']!.text),
      maxLegSkewMs: _readSeconds(_text['maxLegSkew']!.text),
      maxPriceDeviationPct: _readPercent(_text['maxPriceDeviation']!.text),
      enableDynamics: _enableDynamics,
      maxBaselineSpreadPct: _readPercent(_text['maxBaseline']!.text),
      minSpikeZ: str('minSpikeZ'),
      spikeBypassRoundTripMult: str('spikeBypassMult'),
      maxSpreadDurationMs: _readSeconds(_text['maxSpreadDuration']!.text),
      minDynamicsSamples: intVal('minSamples'),
      maxChartSpreadPct: _readPercent(_text['maxChartSpread']!.text),
      historyWindowMs: _readDays(_text['historyWindow']!.text),
      hysteresisStepPct: _readPercent(_text['hysteresis']!.text),
      episodeCloseTicks: intVal('episodeCloseTicks'),
      minSignalLifetimeMs: _readSeconds(_text['minLifetime']!.text),
      cooldownMs: _readSeconds(_text['cooldown']!.text),
      maxSignalsPerMin: intVal('maxPerMin'),
    );
  }

  Future<void> _validate() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await widget.onValidate(_buildConfig());
    final message = result.fold(
      (validation) =>
          validation.valid ? 'Конфигурация валидна' : 'Ошибка: ${validation.error}',
      (error) => 'Не удалось проверить: $error',
    );
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _apply() {
    widget.onApply(_buildConfig());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Фильтры применены — переподписка')),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Площадки'),
        Wrap(
          spacing: 8,
          children: [
            for (final exchange in ScreenerDefaults.allExchanges)
              FilterChip(
                label: Text(exchange),
                selected: _exchanges.contains(exchange),
                onSelected: (selected) => setState(() {
                  selected
                      ? _exchanges.add(exchange)
                      : _exchanges.remove(exchange);
                }),
              ),
          ],
        ),
        _section('Рынки ног (покупка/продажа)'),
        Wrap(
          spacing: 8,
          children: [
            for (final (pair, label) in _marketPairChoices)
              FilterChip(
                label: Text(label),
                // Only perp/perp is ingested today; spot combos are accepted
                // by the server but produce no signals until spot ingest lands.
                selected: _marketPairs.contains(pair),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _marketPairs.add(pair);
                  } else if (_marketPairs.length > 1) {
                    // An empty market_pairs fails server validation.
                    _marketPairs.remove(pair);
                  }
                }),
              ),
          ],
        ),
        _section('Спред'),
        _field('minRoundTrip', 'Мин. прибыль за круг (главный фильтр)',
            unit: '%'),
        _field('minNet', 'Мин. чистый спред на входе (info)', unit: '%'),
        _field('alertNet', 'Порог alert-уведомления', unit: '%'),
        _field('maxNet', 'Макс. чистый спред (ghost cap)', unit: '%'),
        _field('targetNotional', 'Целевой объём VWAP (USDT)'),
        _field('minExecutable', 'Мин. исполнимый объём (USDT)'),
        _field('depthLevels', 'Уровней стакана для VWAP', number: true),
        _field('maxBookAge', 'Макс. возраст стакана',
            number: true, decimal: true, unit: 'с'),
        _field('maxLegSkew', 'Макс. разбег между ногами',
            number: true, decimal: true, unit: 'с'),
        _field('maxPriceDeviation', 'Макс. отклонение цены от медианы',
            unit: '%'),
        _field('quote', 'Котируемый актив'),
        _section('Фандинг'),
        SwitchListTile(
          title: const Text('Учитывать фандинг'),
          value: _includeFunding,
          onChanged: (value) => setState(() => _includeFunding = value),
        ),
        _field('minFundingApr', 'Мин. годовой фандинг-дифф', unit: '%'),
        _field('fundingHold', 'Часы удержания для фандинга'),
        SwitchListTile(
          title: const Text('Вычитать фандинг из прибыли круга'),
          value: _includeFundingCost,
          onChanged: (value) => setState(() => _includeFundingCost = value),
        ),
        _section('Динамика спреда'),
        SwitchListTile(
          title: const Text('Фильтры динамики'),
          value: _enableDynamics,
          onChanged: (value) => setState(() => _enableDynamics = value),
        ),
        _field('maxBaseline', 'Макс. базовый спред', unit: '%'),
        _field('minSpikeZ', 'Мин. z-скор всплеска'),
        _field('spikeBypassMult', 'Множитель обхода всплеска (сильная прибыль)'),
        _field('maxSpreadDuration', 'Макс. длительность спреда',
            number: true, decimal: true, unit: 'с'),
        _field('minSamples', 'Прогрев (сэмплов)', number: true),
        _field('maxChartSpread', 'Макс. спред на графике (фильтр аномалий)',
            unit: '%'),
        _field('historyWindow', 'Глубина длинной истории спреда (по умолчанию 3)',
            number: true, decimal: true, unit: 'суток'),
        _section('Частота сигналов'),
        _field('hysteresis', 'Шаг гистерезиса', unit: '%'),
        _field('episodeCloseTicks', 'Отказов подряд до закрытия эпизода',
            number: true),
        _field('minLifetime', 'Мин. время жизни сигнала',
            number: true, decimal: true, unit: 'с'),
        _field('cooldown', 'Пауза между сигналами',
            number: true, decimal: true, unit: 'с'),
        _field('maxPerMin', 'Лимит сигналов в минуту', number: true),
        _section('Символы и требования'),
        _field('allow', 'Allow-лист (базовый актив: BB, ETH)'),
        _field('deny', 'Deny-лист (базовый актив: BB, ETH)'),
        _field('minVolume', 'Объём 24ч: от (USDT)'),
        _field('maxVolume', 'Объём 24ч: до (USDT, пусто — без потолка)'),
        _field('minOi', 'Мин. открытый интерес'),
        SwitchListTile(
          title: const Text('Требовать перевод актива'),
          value: _requireTransferable,
          onChanged: (value) => setState(() => _requireTransferable = value),
        ),
        SwitchListTile(
          title: const Text('Требовать общую сеть'),
          value: _requireCommonNetwork,
          onChanged: (value) => setState(() => _requireCommonNetwork = value),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppButton.outlined(
                label: 'Проверить',
                onPressed: _validate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Применить',
                onPressed: _apply,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _field(
    String key,
    String label, {
    bool number = false,
    bool decimal = false,
    // Shown inline in the field (not just the label) so the field's unit
    // (%, seconds, days) is unambiguous regardless of the wire unit.
    String? unit,
  }) {
    final help = kFilterHelp[key];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AppTextField(
        controller: _text[key],
        labelText: label,
        keyboardType: number
            ? TextInputType.numberWithOptions(decimal: decimal)
            : TextInputType.text,
        suffixIcon: unit == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: 1,
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
        helpTooltip: help?.tooltip,
        onHelpPressed: help == null ? null : () => _showHelp(help),
      ),
    );
  }

  /// Desktop platforms open a popup dialog; mobile opens a bottom sheet.
  bool get _isDesktop {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  void _showHelp(SettingHelp help) {
    if (_isDesktop) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(help.key),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(child: _HelpContent(help: help)),
          ),
          actions: [
            AppButton(
              label: 'Понятно',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(help.key, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _HelpContent(help: help),
              ],
            ),
          ),
        ),
      );
    }
  }
}

/// Meta line + full description shared by the desktop dialog and the mobile
/// bottom sheet.
class _HelpContent extends StatelessWidget {
  final SettingHelp help;

  const _HelpContent({required this.help});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          help.meta,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 12),
        Text(help.description, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
