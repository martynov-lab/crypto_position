import 'package:bitget/bitget.dart';
import 'package:bybit/bybit.dart';
import 'package:crypto_position/src/bitget_account_repository_factory.dart';
import 'package:crypto_position/src/bitget_session_service.dart';
import 'package:crypto_position/src/bybit_account_repository_factory.dart';
import 'package:crypto_position/src/bybit_session_service.dart';
import 'package:crypto_position/src/gate_account_repository_factory.dart';
import 'package:crypto_position/src/gate_session_service.dart';
import 'package:crypto_position/src/mexc_account_repository_factory.dart';
import 'package:crypto_position/src/mexc_session_service.dart';
import 'package:crypto_position/src/okx_account_repository_factory.dart';
import 'package:crypto_position/src/okx_session_service.dart';
import 'package:gate/gate.dart';
import 'package:mexc/mexc.dart';
import 'package:crypto_position/src/screener_service.dart';
import 'package:network/network.dart';
import 'package:okx/okx.dart';
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
      // recvWindow 60s tolerates moderate local clock skew (Bybit rejects
      // signed requests when |local - server| exceeds the window).
      Provider<BybitConfig>.value(value: BybitConfig(recvWindow: 60000)),
      Provider<BybitAccountRepositoryFactory>(
        create: (context) =>
            BybitAccountRepositoryFactory(context.read<BybitConfig>()),
      ),
      Provider<OkxConfig>.value(value: const OkxConfig()),
      Provider<OkxAccountRepositoryFactory>(
        create: (context) =>
            OkxAccountRepositoryFactory(context.read<OkxConfig>()),
      ),
      Provider<BitgetConfig>.value(value: const BitgetConfig()),
      Provider<BitgetAccountRepositoryFactory>(
        create: (context) =>
            BitgetAccountRepositoryFactory(context.read<BitgetConfig>()),
      ),
      Provider<GateConfig>.value(value: const GateConfig()),
      Provider<GateAccountRepositoryFactory>(
        create: (context) =>
            GateAccountRepositoryFactory(context.read<GateConfig>()),
      ),
      Provider<MexcConfig>.value(value: const MexcConfig()),
      Provider<MexcAccountRepositoryFactory>(
        create: (context) =>
            MexcAccountRepositoryFactory(context.read<MexcConfig>()),
      ),
      Provider<ReconnectionService>(
        create: (_) => ReconnectionService(
          lifecycleService: AppLifecycleService(),
          connectionMonitor: ConnectivityMonitor(),
        ),
        dispose: (_, value) => value.dispose(),
      ),
      Provider<BybitSessionService>(
        create: (context) => BybitSessionService(
          storage: context.read<FlutterSecureStorage>(),
          accountFactory: context.read<BybitAccountRepositoryFactory>(),
          reconnectionService: context.read<ReconnectionService>(),
        ),
        dispose: (_, value) => value.dispose(),
      ),
      Provider<OkxSessionService>(
        create: (context) => OkxSessionService(
          storage: context.read<FlutterSecureStorage>(),
          accountFactory: context.read<OkxAccountRepositoryFactory>(),
          reconnectionService: context.read<ReconnectionService>(),
        ),
        dispose: (_, value) => value.dispose(),
      ),
      Provider<BitgetSessionService>(
        create: (context) => BitgetSessionService(
          storage: context.read<FlutterSecureStorage>(),
          accountFactory: context.read<BitgetAccountRepositoryFactory>(),
          reconnectionService: context.read<ReconnectionService>(),
        ),
        dispose: (_, value) => value.dispose(),
      ),
      Provider<GateSessionService>(
        create: (context) => GateSessionService(
          storage: context.read<FlutterSecureStorage>(),
          accountFactory: context.read<GateAccountRepositoryFactory>(),
          reconnectionService: context.read<ReconnectionService>(),
        ),
        dispose: (_, value) => value.dispose(),
      ),
      Provider<MexcSessionService>(
        create: (context) => MexcSessionService(
          storage: context.read<FlutterSecureStorage>(),
          accountFactory: context.read<MexcAccountRepositoryFactory>(),
          reconnectionService: context.read<ReconnectionService>(),
        ),
        dispose: (_, value) => value.dispose(),
      ),
      Provider<ScreenerService>(
        create: (_) => ScreenerService(),
        dispose: (_, value) => value.dispose(),
      ),
    ],
    child: child,
  );
}
