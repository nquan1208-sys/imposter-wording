import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/config/app_config.dart';
import 'package:untitled/base/dependency/app_service.dart';
import 'package:untitled/base/dependency/router/utils/route_name.dart';

import 'package:untitled/base/dependency/router/utils/route_page.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.current = await AppConfig.load();
  await Supabase.initialize(
    url: AppConfig.current.supabaseUrl,
    publishableKey: AppConfig.current.supabasePublishableKey,
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: false,
      detectSessionInUri: false,
      localStorage: EmptyLocalStorage(),
    ),
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final messenger = GlobalKey<ScaffoldMessengerState>();
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) recoverPicker();
  }

  Future<void> recoverPicker() async {
    bool lost;
    try {
      lost = !(await ref.read(imagePickerProvider).retrieveLostData()).isEmpty;
    } catch (_) {
      lost = true;
    }
    if (!mounted || !lost) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = messenger.currentState;
      if (mounted && state != null) {
        state.showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(state.context).localImageDraftLost,
            ),
          ),
        );
      }
    });
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final routerService = ref.watch(AppService.router);
    final setupStore = ref.watch(setupStoreProvider);
    return SignalBuilder(
      builder: (context) => MaterialApp(
        scaffoldMessengerKey: messenger,
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        locale: Locale(setupStore.setup.value.contentLocale),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        darkTheme: AppTheme.dark,
        builder: (context, child) => AnnotatedRegion(
          value: AppTheme.dark.appBarTheme.systemOverlayStyle!,
          child: child!,
        ),
        onGenerateRoute: RoutePage.onGenerateRoute,
        navigatorKey: routerService.navigatorKey,
        initialRoute: RouteName.splash,
      ),
    );
  }
}
