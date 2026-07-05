import 'package:crypto_position/src/presentation/crypto_app/crypto_app.dart';
import 'package:crypto_position/src/position_provider.dart';
import 'package:crypto_position/src/share_preferences/flutter_shared_preferences_helper.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferencesHelper =
      SharedPreferencesHelperFlutter.withDefaultAsyncBackend();

  runApp(
    PositionProvider(
      sharedPreferencesHelper: sharedPreferencesHelper,
      child: CryptoApp(),
    ),
  );
}
