import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/main.dart';

Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MyApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('cold start opens Vietnamese landing with start disabled', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Kẻ mạo danh'), findsOneWidget);
    expect(find.text('Trò chơi từ ngữ'), findsOneWidget);
    final start = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Bắt đầu'),
    );
    expect(start.onPressed, isNull);
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
  });

  testWidgets('setLocale switches strings to English', (tester) async {
    final container = await pumpApp(tester);

    container.read(StoreProvider.app).setLocale(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text('Imposter'), findsOneWidget);
    expect(find.text('How to play'), findsOneWidget);
  });
}
