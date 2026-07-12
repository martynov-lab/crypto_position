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

class _FiltersViewState extends State<FiltersView> {
  late final Map<String, TextEditingController> _text;
  late final Set<String> _exchanges;
  late final Set<MarketPair> _marketPairs;
  late bool _includeFunding;
  late bool _enableDynamics;
  late bool _requireTransferable;
  late bool _requireCommonNetwork;

  @override
  void initState() {
    super.initState();
    final config = widget.initial;
    _text = {
      'quote': TextEditingController(text: config.quote ?? ScreenerDefaults.quote),
      'minNet': _seed(config.minNetSpreadPct, ScreenerDefaults.minNetSpreadPct),
      'maxNet': _seed(config.maxNetSpreadPct, ScreenerDefaults.maxNetSpreadPct),
      'targetNotional':
          _seed(config.targetNotionalQ, ScreenerDefaults.targetNotionalQ),
      'minExecutable': _seed(
          config.minExecutableNotional, ScreenerDefaults.minExecutableNotional),
      'depthLevels': _seed(config.depthLevelsN, ScreenerDefaults.depthLevelsN),
      'maxBookAge': _seed(config.maxBookAgeMs, ScreenerDefaults.maxBookAgeMs),
      'minFundingApr':
          _seed(config.minFundingDiffApr, ScreenerDefaults.minFundingDiffApr),
      'fundingHold':
          _seed(config.fundingHoldHours, ScreenerDefaults.fundingHoldHours),
      'maxBaseline': _seed(
          config.maxBaselineSpreadPct, ScreenerDefaults.maxBaselineSpreadPct),
      'minSpikeZ': _seed(config.minSpikeZ, ScreenerDefaults.minSpikeZ),
      'maxSpreadDuration': _seed(
          config.maxSpreadDurationMs, ScreenerDefaults.maxSpreadDurationMs),
      'minSamples':
          _seed(config.minDynamicsSamples, ScreenerDefaults.minDynamicsSamples),
      'maxChartSpread':
          _seed(config.maxChartSpreadPct, ScreenerDefaults.maxChartSpreadPct),
      'hysteresis':
          _seed(config.hysteresisStepPct, ScreenerDefaults.hysteresisStepPct),
      'minLifetime':
          _seed(config.minSignalLifetimeMs, ScreenerDefaults.minSignalLifetimeMs),
      'cooldown': _seed(config.cooldownMs, ScreenerDefaults.cooldownMs),
      'maxPerMin':
          _seed(config.maxSignalsPerMin, ScreenerDefaults.maxSignalsPerMin),
      'allow': TextEditingController(text: config.allowSymbols?.join(', ') ?? ''),
      'deny': TextEditingController(text: config.denySymbols?.join(', ') ?? ''),
      'minVolume':
          _seed(config.min24hQuoteVolume, ScreenerDefaults.min24hQuoteVolume),
      // `maxVolumeOff` ('') round-trips as an empty field = ceiling off.
      'maxVolume':
          _seed(config.max24hQuoteVolume, ScreenerDefaults.max24hQuoteVolume),
      'minOi': TextEditingController(text: config.minOpenInterest ?? ''),
    };
    _exchanges = {...(config.exchanges ?? ScreenerDefaults.allExchanges)};
    _marketPairs = {...(config.marketPairs ?? ScreenerDefaults.marketPairs)};
    _includeFunding =
        config.includeFundingDiff ?? ScreenerDefaults.includeFundingDiff;
    _enableDynamics = config.enableDynamics ?? ScreenerDefaults.enableDynamics;
    _requireTransferable =
        config.requireTransferable ?? ScreenerDefaults.requireTransferable;
    _requireCommonNetwork =
        config.requireCommonNetwork ?? ScreenerDefaults.requireCommonNetwork;
  }

  static TextEditingController _seed(Object? fromConfig, Object defaultValue) =>
      TextEditingController(text: '${fromConfig ?? defaultValue}');

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
      minNetSpreadPct: str('minNet'),
      maxNetSpreadPct: str('maxNet'),
      targetNotionalQ: str('targetNotional'),
      minExecutableNotional: str('minExecutable'),
      depthLevelsN: intVal('depthLevels'),
      includeFundingDiff: _includeFunding,
      minFundingDiffApr: str('minFundingApr'),
      fundingHoldHours: str('fundingHold'),
      requireTransferable: _requireTransferable,
      requireCommonNetwork: _requireCommonNetwork,
      maxBookAgeMs: intVal('maxBookAge'),
      enableDynamics: _enableDynamics,
      maxBaselineSpreadPct: str('maxBaseline'),
      minSpikeZ: str('minSpikeZ'),
      maxSpreadDurationMs: intVal('maxSpreadDuration'),
      minDynamicsSamples: intVal('minSamples'),
      maxChartSpreadPct: str('maxChartSpread'),
      hysteresisStepPct: str('hysteresis'),
      minSignalLifetimeMs: intVal('minLifetime'),
      cooldownMs: intVal('cooldown'),
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
        _section('Спред (доли, 0.03 = 3%)'),
        _field('minNet', 'Мин. чистый спред'),
        _field('maxNet', 'Макс. чистый спред (ghost cap)'),
        _field('targetNotional', 'Целевой объём VWAP (USDT)'),
        _field('minExecutable', 'Мин. исполнимый объём (USDT)'),
        _field('depthLevels', 'Уровней стакана для VWAP', number: true),
        _field('maxBookAge', 'Макс. возраст стакана (мс)', number: true),
        _field('quote', 'Котируемый актив'),
        _section('Фандинг'),
        SwitchListTile(
          title: const Text('Учитывать фандинг'),
          value: _includeFunding,
          onChanged: (value) => setState(() => _includeFunding = value),
        ),
        _field('minFundingApr', 'Мин. годовой фандинг-дифф'),
        _field('fundingHold', 'Часы удержания для фандинга'),
        _section('Динамика спреда'),
        SwitchListTile(
          title: const Text('Фильтры динамики'),
          value: _enableDynamics,
          onChanged: (value) => setState(() => _enableDynamics = value),
        ),
        _field('maxBaseline', 'Макс. базовый спред'),
        _field('minSpikeZ', 'Мин. z-скор всплеска'),
        _field('maxSpreadDuration', 'Макс. длительность спреда (мс)', number: true),
        _field('minSamples', 'Прогрев (сэмплов)', number: true),
        _field('maxChartSpread', 'Макс. спред на графике (фильтр аномалий)'),
        _section('Частота сигналов'),
        _field('hysteresis', 'Шаг гистерезиса'),
        _field('minLifetime', 'Мин. время жизни сигнала (мс)', number: true),
        _field('cooldown', 'Пауза между сигналами (мс)', number: true),
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

  Widget _field(String key, String label, {bool number = false}) {
    final help = kFilterHelp[key];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AppTextField(
        controller: _text[key],
        labelText: label,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: false)
            : TextInputType.text,
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
