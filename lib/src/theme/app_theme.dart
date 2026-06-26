import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    colorSchemeSeed: Colors.indigo,
    brightness: Brightness.light,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
    ),
  );

  static ThemeData get dark => ThemeData(
    colorSchemeSeed: Colors.indigo,
    brightness: Brightness.dark,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
    ),
  );
}

const keyThemeMode = 'THEME_MODE';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
