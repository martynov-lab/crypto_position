import 'package:crypto_position/src/presentation/settings/settings_screen_wm.dart';
import 'package:crypto_position/src/presentation/settings/widgets/settings_view.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends ElementaryWidget<SettingsScreenWm> {
  SettingsScreen({super.key})
    : super((context) => settingsScreenWmFactory(context: context));

  @override
  Widget build(SettingsScreenWm wm) {
    return ListenableBuilder(
      listenable: wm.connectionsListenable,
      builder: (context, _) => SettingsView(connections: wm.connections),
    );
  }
}
