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
        for (final connection in connections) ...[
          const SizedBox(height: 8),
          _ApiConnectionCard(connection: connection),
        ],
      ],
    );
  }

  Widget _buildThemeCard(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark =
        themeNotifier.mode == ThemeMode.dark ||
        (themeNotifier.mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Card(
      child: SwitchListTile(
        secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
        title: const Text('Тёмная тема'),
        value: isDark,
        onChanged: (_) => themeNotifier.toggle(),
      ),
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
