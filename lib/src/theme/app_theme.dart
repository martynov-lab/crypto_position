import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class AppTheme {
  static ThemeData get light => AppThemeData.light;
  static ThemeData get dark => AppThemeData.dark;
}

const keyThemeMode = 'THEME_MODE';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }
}
