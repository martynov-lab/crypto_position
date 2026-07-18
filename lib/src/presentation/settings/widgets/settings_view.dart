import 'package:crypto_position/src/fees/fee_settings_store.dart';
import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';

/// View data for one exchange's API-connection card.
class ExchangeConnection {
  final String title;
  final bool hasCredentials;
  final bool loading;
  final String? error;
  final TextEditingController apiKeyController;
  final TextEditingController apiSecretController;

  /// Passphrase input, for exchanges that require one (e.g. OKX). Null hides it.
  final TextEditingController? passphraseController;
  final VoidCallback onSaveCredentials;
  final VoidCallback onLogout;

  const ExchangeConnection({
    required this.title,
    required this.hasCredentials,
    required this.loading,
    required this.error,
    required this.apiKeyController,
    required this.apiSecretController,
    this.passphraseController,
    required this.onSaveCredentials,
    required this.onLogout,
  });
}

class SettingsView extends StatelessWidget {
  final List<ExchangeConnection> connections;

  const SettingsView({super.key, required this.connections});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildThemeCard(context),
        const SizedBox(height: 8),
        const _FeeSettingsCard(),
        for (final connection in connections) ...[
          const SizedBox(height: 8),
          _ApiConnectionCard(connection: connection),
        ],
      ],
    );
  }

  Widget _buildThemeCard(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Тема', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Системная'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Светлая'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Тёмная'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {themeNotifier.mode},
              onSelectionChanged: (selection) =>
                  themeNotifier.setMode(selection.first),
            ),
          ],
        ),
      ),
    );
  }
}

/// Editable maker-fee (%) per exchange, used by the arbitrage calculator.
class _FeeSettingsCard extends StatelessWidget {
  const _FeeSettingsCard();

  @override
  Widget build(BuildContext context) {
    final store = context.read<FeeSettingsStore>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Комиссии maker (%)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final exchange in ExchangeId.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FeeRow(store: store, exchange: exchange),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeeRow extends StatefulWidget {
  final FeeSettingsStore store;
  final ExchangeId exchange;

  const _FeeRow({required this.store, required this.exchange});

  @override
  State<_FeeRow> createState() => _FeeRowState();
}

class _FeeRowState extends State<_FeeRow> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.store.makerPct(widget.exchange).toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(widget.exchange.label)),
        Expanded(
          child: AppTextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            labelText: 'maker %',
            onChanged: (value) {
              final pct = double.tryParse(value);
              if (pct != null) {
                widget.store.setMakerPct(widget.exchange, pct);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ApiConnectionCard extends StatelessWidget {
  final ExchangeConnection connection;

  const _ApiConnectionCard({required this.connection});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              connection.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (connection.loading)
              const Center(child: CircularProgressIndicator())
            else if (connection.hasCredentials)
              _buildConnectedState(context)
            else
              _buildLoginForm(context),
            if (connection.error != null) ...[
              const SizedBox(height: 16),
              Text(
                connection.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('API ключ подключён'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AppButton.outlined(
            onPressed: connection.onLogout,
            label: 'Отключить API',
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    final passphraseController = connection.passphraseController;
    return Column(
      children: [
        AppTextField(
          controller: connection.apiKeyController,
          labelText: 'API Key',
          prefixIcon: const Icon(Icons.vpn_key),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: connection.apiSecretController,
          obscureText: true,
          labelText: 'API Secret',
          prefixIcon: const Icon(Icons.lock),
        ),
        if (passphraseController != null) ...[
          const SizedBox(height: 16),
          AppTextField(
            controller: passphraseController,
            obscureText: true,
            labelText: 'Passphrase',
            prefixIcon: const Icon(Icons.password),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            onPressed: connection.onSaveCredentials,
            icon: const Icon(Icons.add),
            label: 'Добавить',
          ),
        ),
      ],
    );
  }
}
