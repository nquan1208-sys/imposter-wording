import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/features/landing/landing_screen.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/features/splash/splash_screen.dart';
import 'package:untitled/main.dart';
import 'package:untitled/models/game_setup.dart';

import '../../data/fixtures.dart';
import '../../data/memory_app_settings_storage.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    FetchContentPage? fetch,
    MemoryStorage? cache,
    String locale = 'vi',
    MemoryAppSettingsStorage? settings,
  }) async {
    final content = ContentRepository(
      contentLocale: locale,
      cache: cache ?? MemoryStorage(),
      fetchPage:
          fetch ??
          (t, l, f, e) => fixturePage(fixture(locale: locale), t, l, f, e),
    );
    final setup = SetupStore(
      content: content,
      file: MemoryStorage(
        GameSetup.defaults().copyWith(contentLocale: locale).toJson(),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        setupStoreProvider.overrideWithValue(setup),
        localStorageProvider.overrideWithValue(
          settings ?? MemoryAppSettingsStorage(),
        ),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      setup.dispose();
      content.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pump();
  }

  testWidgets('ready data still keeps the logo visible for 300ms', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).image, isA<AssetImage>());
    await tester.pump(const Duration(milliseconds: 299));
    expect(find.byType(LandingScreen), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(
      Navigator.of(tester.element(find.byType(LandingScreen))).canPop(),
      false,
    );
  });

  testWidgets(
    'waits beyond the minimum until selected-language content loads',
    (tester) async {
      final gate = Completer<void>();
      final locales = <String>[];
      await pumpApp(
        tester,
        locale: 'en',
        fetch: (t, l, f, e) async {
          locales.add(l);
          await gate.future;
          return fixturePage(fixture(locale: l), t, l, f, e);
        },
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(LandingScreen), findsNothing);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Start'), findsOneWidget);
      expect(locales, everyElement('en'));
    },
  );

  testWidgets('offline cache opens home after loading fails', (tester) async {
    await pumpApp(
      tester,
      cache: MemoryStorage(fixture()),
      fetch: (t, l, f, e) async {
        throw const SocketException('offline');
      },
    );
    await tester.pumpAndSettle();
    expect(find.byType(LandingScreen), findsOneWidget);
  });

  testWidgets('missing data shows retry and a successful retry opens home', (
    tester,
  ) async {
    var offline = true;
    await pumpApp(
      tester,
      locale: 'en',
      fetch: (t, l, f, e) async {
        if (offline) throw const SocketException('offline');
        return fixturePage(fixture(locale: l), t, l, f, e);
      },
    );
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    offline = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(LandingScreen), findsOneWidget);
  });

  testWidgets('failed settings restore can recover through retry', (
    tester,
  ) async {
    final settings = MemoryAppSettingsStorage(failRead: true);
    await pumpApp(tester, settings: settings);
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsOneWidget);
    settings.failRead = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(LandingScreen), findsOneWidget);
  });

  testWidgets(
    'failed startup can continue home without claiming data is ready',
    (tester) async {
      await pumpApp(
        tester,
        locale: 'en',
        fetch: (t, l, f, e) async => throw const SocketException('offline'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to home'));
      await tester.pumpAndSettle();
      expect(find.byType(LandingScreen), findsOneWidget);
    },
  );

  testWidgets('disposing splash cancels its minimum timer', (tester) async {
    await pumpApp(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
