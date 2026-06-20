import 'package:crypto_position/src/share_preferences/shared_preferences_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PositionProvider extends StatelessWidget {
  final SharedPreferencesHelper sharedPreferencesHelper;
  final Widget child;

  const PositionProvider({
    super.key,
    required this.child,
    required this.sharedPreferencesHelper,
  });

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<SharedPreferencesHelper>.value(value: sharedPreferencesHelper),
    ],
    child: child,
  );
}
