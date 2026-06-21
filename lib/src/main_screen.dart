import 'package:crypto_position/src/route/router.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  // final SharedPreferencesHelper sharedPreferencesHelper;

  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router);

    // MaterialApp(
    //   home: Scaffold(
    //     body: PositionProvider(
    //       sharedPreferencesHelper: sharedPreferencesHelper,
    //       child: PositionCalculator(),
    //     ),
    //   ),
    // );
  }
}
