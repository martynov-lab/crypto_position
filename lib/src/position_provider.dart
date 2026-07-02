import 'package:bybit/bybit.dart';
import 'package:crypto_position/src/bybit_account_repository_factory.dart';
import 'package:crypto_position/src/share_preferences/shared_preferences_helper.dart';
import 'package:crypto_position/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
      ChangeNotifierProvider<ThemeNotifier>.value(value: ThemeNotifier()),
      Provider<FlutterSecureStorage>.value(value: FlutterSecureStorage()),
      Provider<BybitConfig>.value(value: BybitConfig()),
      Provider<DioClientFactory>.value(value: DioClientFactory()),
      Provider<WsClientFactory>.value(value: WsClientFactory()),
      Provider<BybitAccountRepositoryFactory>(
        create: (context) =>
            BybitAccountRepositoryFactory(context.read<BybitConfig>()),
      ),
    ],
    child: child,
  );
}
