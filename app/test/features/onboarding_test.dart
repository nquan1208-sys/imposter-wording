import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/main.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/features/setup/setup_store.dart';
import '../data/fixtures.dart';

Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  final content = ContentRepository(
    cache: MemoryFile(),
    fetchPage: (t, l, f, e) => fixturePage(fixture(), t, l, f, e),
  );
  final store = SetupStore(content: content, file: MemoryFile());
  await content.load();
  await store.restore();
  addTearDown(store.dispose);
  addTearDown(content.dispose);
  final container = ProviderContainer(
    overrides: [
      contentRepositoryProvider.overrideWithValue(content),
      setupStoreProvider.overrideWithValue(store),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MyApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('cold start opens Vietnamese landing with start enabled', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Kẻ mạo danh'), findsOneWidget);
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

    container.read(StoreProvider.app).setLocale(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text('Imposter'), findsOneWidget);
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
