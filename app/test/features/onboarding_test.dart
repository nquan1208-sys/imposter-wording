import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled/base/dependency/app_service.dart';
import 'package:untitled/base/dependency/router/utils/route_input.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/main.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/features/setup/setup_store.dart';
import '../data/memory_app_settings_storage.dart';
import '../data/fixtures.dart';

Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  final content = ContentRepository(
    cache: MemoryStorage(),
    fetchPage: (t, l, f, e) => fixturePage(fixture(), t, l, f, e),
  );
  final english = ContentRepository(
    contentLocale: 'en',
    cache: MemoryStorage(),
    fetchPage: (t, l, f, e) => fixturePage(fixture(locale: 'en'), t, l, f, e),
  );
  await english.load();
  addTearDown(english.dispose);
  final store = SetupStore(
    content: content,
    file: MemoryStorage(),
    repositoryForLocale: (locale) => locale == 'en' ? english : content,
  );
  await content.load();
  await store.restore();
  addTearDown(store.dispose);
  addTearDown(content.dispose);
  final container = ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(MemoryAppSettingsStorage()),
      contentRepositoryProvider('vi').overrideWithValue(content),
      setupStoreProvider.overrideWithValue(store),
    ],
  );
  addTearDown(container.dispose);
  await container.read(StoreProvider.app).restore();
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MyApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'dark appearance overrides a light device and fallback returns home',
    (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final container = await pumpApp(tester);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(
        Theme.of(tester.element(find.text('OddCue'))).brightness,
        Brightness.dark,
      );
      final systemBars = tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
          )
          .value;
      expect(systemBars.statusBarIconBrightness, Brightness.light);
      expect(systemBars.systemNavigationBarIconBrightness, Brightness.light);
      final navigation = container
          .read(AppService.router)
          .push(RouteInput(routeName: '/missing'));
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy trang'), findsOneWidget);
      await tester.tap(find.text('Về trang chủ'));
      await tester.pumpAndSettle();
      await navigation;
      expect(find.text('OddCue'), findsOneWidget);
      expect(find.text('Về trang chủ'), findsNothing);
    },
  );

  for (final size in [
    const Size(375, 812),
    const Size(812, 375),
    const Size(1024, 1366),
  ]) {
    testWidgets('onboarding remains operable at $size with reduced motion', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpApp(tester);
      final start = find.widgetWithText(FilledButton, 'Bắt đầu');
      expect(tester.getSize(start).width, lessThanOrEqualTo(592));
      expect(start.hitTestable(), findsOneWidget);
      await tester.tap(find.text('Cách chơi'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('proTipCard')),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cold start opens Vietnamese landing with start enabled', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('OddCue'), findsOneWidget);
    expect(find.text('Trò chơi từ ngữ'), findsOneWidget);
    final start = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Bắt đầu'),
    );
    expect(start.onPressed, isNotNull);
    expect(find.text('Sắp ra mắt'), findsNothing);
  });

  testWidgets('how to play scrolls and UI back returns to landing', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Cách chơi'));
    await tester.pumpAndSettle();

    expect(find.text('Thiết lập trò chơi'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('proTipCard')),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Mẹo chuyên nghiệp'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Trò chơi từ ngữ'), findsOneWidget);
    expect(find.text('Thiết lập trò chơi'), findsNothing);
  });

  testWidgets('system back from how to play returns to landing', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Cách chơi'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Trò chơi từ ngữ'), findsOneWidget);
  });

  testWidgets('small screen with large text keeps buttons reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(tester);

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cách chơi'));
    await tester.pumpAndSettle();
    expect(find.text('Thiết lập trò chơi'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mẹo chuyên nghiệp'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mẹo chuyên nghiệp').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English onboarding scrolls and back returns to landing', (
    tester,
  ) async {
    final container = await pumpApp(tester);

    expect(
      await container.read(setupStoreProvider).setContentLocale('en'),
      isTrue,
    );
    await tester.pumpAndSettle();

    expect(find.text('OddCue'), findsOneWidget);
    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Coming soon'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Start'))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.text('How to play'));
    await tester.pumpAndSettle();

    expect(find.text('Set up the game'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pro tip'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pro tip').hitTestable(), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Word game'), findsOneWidget);
    expect(find.text('Set up the game'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
