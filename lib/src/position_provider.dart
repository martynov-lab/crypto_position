import 'package:crypto_position/src/share_preferences/shared_preferences_helper.dart';
import 'package:crypto_position/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PositionProvider extends StatelessWidget {
  final SharedPreferencesHelper sharedPreferencesHelper;
  final ThemeNotifier themeNotifier;
  final Widget child;

  const PositionProvider({
    super.key,
    required this.child,
    required this.sharedPreferencesHelper,
    required this.themeNotifier,
  });

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<SharedPreferencesHelper>.value(value: sharedPreferencesHelper),
      ChangeNotifierProvider<ThemeNotifier>.value(value: themeNotifier),
    ],
    child: child,
  );
}
