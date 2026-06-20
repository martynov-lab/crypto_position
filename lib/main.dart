import 'package:crypto_position/src/position_calculator.dart';
import 'package:crypto_position/src/position_provider.dart';
import 'package:crypto_position/src/share_preferences/flutter_shared_preferences_helper.dart';
import 'package:crypto_position/src/share_preferences/shared_preferences_helper.dart';
import 'package:flutter/material.dart';

void main() {
  final sharedPreferencesHelper =
      SharedPreferencesHelperFlutter.withDefaultAsyncBackend();
  runApp(MainApp(sharedPreferencesHelper: sharedPreferencesHelper));
}

class MainApp extends StatelessWidget {
  final SharedPreferencesHelper sharedPreferencesHelper;
  const MainApp({super.key, required this.sharedPreferencesHelper});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PositionProvider(
          sharedPreferencesHelper: sharedPreferencesHelper,
          child: PositionCalculator(),
        ),
      ),
    );
  }
}
