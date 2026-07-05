import 'package:crypto_position/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';

class SettingsView extends StatelessWidget {
  final bool hasCredentials;
  final bool loading;
  final String? error;
  final TextEditingController apiKeyController;
  final TextEditingController apiSecretController;
  final VoidCallback onSaveCredentials;
  final VoidCallback onLogout;

  const SettingsView({
    super.key,
    required this.hasCredentials,
    required this.loading,
    required this.error,
    required this.apiKeyController,
    required this.apiSecretController,
    required this.onSaveCredentials,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildThemeCard(context),
        const SizedBox(height: 8),
        _buildApiCard(context),
      ],
    );
  }

  Widget _buildThemeCard(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = themeNotifier.mode == ThemeMode.dark ||
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

  Widget _buildApiCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Подключение к Bybit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (hasCredentials)
              _buildConnectedState(context)
            else
              _buildLoginForm(context),
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(
                error!,
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
            onPressed: onLogout,
            label: 'Отключить API',
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: apiKeyController,
          labelText: 'API Key',
          prefixIcon: const Icon(Icons.vpn_key),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: apiSecretController,
          obscureText: true,
          labelText: 'API Secret',
          prefixIcon: const Icon(Icons.lock),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            onPressed: onSaveCredentials,
            icon: const Icon(Icons.add),
            label: 'Добавить',
          ),
        ),
      ],
    );
  }
}
