import 'package:crypto_position/src/presentation/crypto_app/crypto_app_wm.dart';
import 'package:crypto_position/src/route/router.dart';
import 'package:crypto_position/src/theme/app_theme.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CryptoApp extends ElementaryWidget<CryptoAppWm> {
  CryptoApp({super.key})
    : super((context) => cryptoAppWmFactory(context: context));

  @override
  Widget build(CryptoAppWm wm) {
    return Builder(
      builder: (context) {
        final themeNotifier = context.watch<ThemeNotifier>();
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeNotifier.mode,
        );
      },
    );
  }
}
