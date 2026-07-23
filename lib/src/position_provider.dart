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
import 'package:crypto_position/src/fees/fee_settings_store.dart';
import 'package:crypto_position/src/market_data/bitget_market_data.dart';
import 'package:crypto_position/src/market_data/bybit_market_data.dart';
import 'package:crypto_position/src/market_data/exchange_id.dart';
import 'package:crypto_position/src/market_data/gate_market_data.dart';
import 'package:crypto_position/src/market_data/market_data_provider.dart';
import 'package:crypto_position/src/market_data/market_data_registry.dart';
import 'package:crypto_position/src/market_data/mexc_market_data.dart';
import 'package:crypto_position/src/market_data/okx_market_data.dart';
import 'package:crypto_position/src/always_on_lifecycle_service.dart';
import 'package:crypto_position/src/keep_alive_service.dart';
import 'package:crypto_position/src/notification_service.dart';
import 'package:crypto_position/src/screener_service.dart';
import 'package:crypto_position/src/tab_badge_service.dart';
import 'package:crypto_position/src/trade/exchange_account_registry.dart';
import 'package:crypto_position/src/trade/trade_executor_registry.dart';
import 'package:exchange/exchange.dart';
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
        // Always-on lifecycle: sockets survive focus loss / backgrounding so
        // background notifications keep receiving position events.
        create: (_) => ReconnectionService(
          lifecycleService: const AlwaysOnLifecycleService(),
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
      Provider<NotificationService>(
        create: (_) => NotificationService()..init(),
      ),
      Provider<KeepAliveService>(create: (_) => KeepAliveService()),
      Provider<TabBadgeService>(
        create: (context) => TabBadgeService(
          bybit: context.read<BybitSessionService>(),
          okx: context.read<OkxSessionService>(),
          bitget: context.read<BitgetSessionService>(),
          gate: context.read<GateSessionService>(),
          mexc: context.read<MexcSessionService>(),
          screener: context.read<ScreenerService>(),
          notifications: context.read<NotificationService>(),
        ),
        dispose: (_, value) => value.dispose(),
      ),
      ChangeNotifierProvider<FeeSettingsStore>(
        create: (context) =>
            FeeSettingsStore(context.read<SharedPreferencesHelper>())..load(),
      ),
      Provider<MarketDataRegistry>(
        create: (context) => MarketDataRegistry(
          providers: <ExchangeId, MarketDataProvider>{
            ExchangeId.bybit: BybitMarketData(),
            ExchangeId.okx: OkxMarketData(),
            ExchangeId.bitget: BitgetMarketData(),
            ExchangeId.gate: GateMarketData(),
            ExchangeId.mexc: MexcMarketData(),
          },
          connectedFlags: {
            ExchangeId.bybit: context
                .read<BybitSessionService>()
                .hasCredentials,
            ExchangeId.okx: context.read<OkxSessionService>().hasCredentials,
            ExchangeId.bitget: context
                .read<BitgetSessionService>()
                .hasCredentials,
            ExchangeId.gate: context.read<GateSessionService>().hasCredentials,
            ExchangeId.mexc: context.read<MexcSessionService>().hasCredentials,
          },
        ),
      ),
      Provider<TradeExecutorRegistry>(
        create: (context) => TradeExecutorRegistry(<
          ExchangeId,
          TradeExecutor? Function()
        >{
          ExchangeId.bybit: () =>
              context.read<BybitSessionService>().session.value?.tradeExecutor,
          ExchangeId.okx: () =>
              context.read<OkxSessionService>().session.value?.tradeExecutor,
          ExchangeId.bitget: () =>
              context.read<BitgetSessionService>().session.value?.tradeExecutor,
          ExchangeId.gate: () =>
              context.read<GateSessionService>().session.value?.tradeExecutor,
          ExchangeId.mexc: () =>
              context.read<MexcSessionService>().session.value?.tradeExecutor,
        }),
      ),
      Provider<ExchangeAccountRegistry>(
        create: (context) => ExchangeAccountRegistry(<
          ExchangeId,
          ExchangeAccountRepository? Function()
        >{
          ExchangeId.bybit: () =>
              context.read<BybitSessionService>().session.value?.repository,
          ExchangeId.okx: () =>
              context.read<OkxSessionService>().session.value?.repository,
          ExchangeId.bitget: () =>
              context.read<BitgetSessionService>().session.value?.repository,
          ExchangeId.gate: () =>
              context.read<GateSessionService>().session.value?.repository,
          ExchangeId.mexc: () =>
              context.read<MexcSessionService>().session.value?.repository,
        }),
      ),
    ],
    child: child,
  );
}
