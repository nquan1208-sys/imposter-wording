import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/main.dart';
import 'package:untitled/models/content.dart';
import '../../data/fixtures.dart';

void main() {
  late ContentRepository content;
  late SetupStore store;
  late MemoryFile file;
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester, {
    FetchContentPage? fetch,
    MemoryFile? cache,
    bool load = true,
    bool english = false,
  }) async {
    content = ContentRepository(
      cache: cache ?? MemoryFile(),
      fetchPage: fetch ?? (t, l, f, e) => fixturePage(fixture(), t, l, f, e),
    );
    file = MemoryFile();
    store = SetupStore(content: content, file: file);
    addTearDown(content.dispose);
    addTearDown(store.dispose);
    await store.restore();
    if (load) await content.load();
    container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(content),
        setupStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    if (english) {
      container.read(StoreProvider.app).setLocale(const Locale('en'));
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(english ? 'Start' : 'Bắt đầu'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final target = text == 'Danh mục' || text == 'Categories'
        ? find.byType(ListTile)
        : find.text(text);
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        180,
        scrollable: find.byType(Scrollable).last,
      );
    }
    final finder = target.last;
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'landing opens setup; picker cancel discards and confirm commits',
    (tester) async {
      await pump(tester);
      expect(find.text('4'), findsOneWidget);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('4 người chơi'), findsOneWidget);
      semantics.dispose();
      expect(find.byType(Switch), findsNothing);
      expect(find.byIcon(Icons.settings), findsNothing);
      final player = tester.getRect(find.text('Người chơi'));
      final imposter = tester.getRect(find.text('Kẻ mạo danh'));
      expect(player.center.dy, imposter.center.dy);
      expect(player.center.dx, lessThan(imposter.center.dx));
      expect(find.text('3 từ phù hợp'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Bắt đầu ván chơi'),
            )
            .onPressed,
        isNotNull,
      );
      await tap(tester, 'Danh mục');
      await tap(tester, 'Category b');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(store.setup.value.categoryIds, isEmpty);
      await tap(tester, 'Danh mục');
      await tap(tester, 'Category b');
      await tap(tester, 'Xác nhận');
      expect(store.setup.value.categoryIds, {'b'});
      expect(find.text('1 từ phù hợp'), findsOneWidget);
      await tap(tester, 'Gia đình');
      expect(store.setup.value.categoryIds, isEmpty);
      expect(find.text('Tất cả danh mục'), findsOneWidget);
      expect(find.textContaining('Đã bỏ danh mục'), findsOneWidget);
      expect(find.text('1 từ phù hợp'), findsOneWidget);
      await tap(tester, 'Danh mục');
      expect(find.text('Category b'), findsNothing);
      await tap(tester, 'Category a');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(store.setup.value.categoryIds, isEmpty);
    },
  );

  testWidgets('player sheet bounds, confirmation and navigation retain setup', (
    tester,
  ) async {
    await pump(tester, english: true);
    await tap(tester, 'Players');
    await tester.tap(find.byTooltip('Fewer players'));
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Fewer players',
            ),
          )
          .onPressed,
      null,
    );
    await tap(tester, 'Confirm');
    expect(store.setup.value.players.length, 3);
    store.setPlayerCount(100);
    await tester.pumpAndSettle();
    await tap(tester, 'Players');
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'More players',
            ),
          )
          .onPressed,
      null,
    );
    await tap(tester, 'Confirm');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tap(tester, 'Start');
    expect(find.text('100'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('100 players'), findsOneWidget);
    semantics.dispose();
    expect(find.text('Word game'), findsOneWidget);
    expect(find.text('Imposters'), findsOneWidget);
  });

  testWidgets('loading, error and retry without cache', (tester) async {
    var offline = true;
    final gate = Completer<List<JsonMap>>();
    await pump(
      tester,
      load: false,
      english: true,
      fetch: (t, l, f, e) async {
        if (offline) return gate.future;
        return fixturePage(fixture(), t, l, f, e);
      },
    );
    final pending = content.load();
    await tester.pump();
    expect(find.text('Loading Vietnamese content…'), findsOneWidget);
    gate.completeError(const SocketException('offline'));
    await pending;
    await tester.pumpAndSettle();
    expect(
      find.text('Content could not be refreshed. Please retry.'),
      findsOneWidget,
    );
    offline = false;
    await tap(tester, 'Retry');
    expect(find.text('3 eligible words'), findsOneWidget);
  });

  testWidgets('offline cache, empty family mode and persistence retry', (
    tester,
  ) async {
    final data = fixture();
    for (final w in data['words'] as List) {
      w['is_family_friendly'] = false;
    }
    await pump(
      tester,
      english: true,
      cache: MemoryFile(data),
      fetch: (t, l, f, e) async => throw const SocketException('offline'),
    );
    expect(find.text('Using saved content.'), findsOneWidget);
    file.failWrite = true;
    await tap(tester, 'Family');
    expect(find.text('0 eligible words'), findsOneWidget);
    expect(find.text('No eligible words in this mode.'), findsOneWidget);
    expect(
      find.text('Setup could not be saved. Your changes are still here.'),
      findsOneWidget,
    );
    file.failWrite = false;
    // Settings retry is the first retry; content retry remains below it.
    await tester.ensureVisible(find.text('Retry').first);
    await tester.tap(find.text('Retry').first);
    await tester.pumpAndSettle();
    expect(store.writeFailed.value, false);
    expect(file.data!['mode'], 'family');
  });

  testWidgets('unreadable settings require retry or confirmed reset', (
    tester,
  ) async {
    await pump(tester, english: true);
    file.failRead = true;
    await store.restore();
    await tester.pumpAndSettle();
    expect(
      find.text('Saved setup could not be read. Retry or reset to continue.'),
      findsOneWidget,
    );
    await tap(tester, 'Reset setup');
    await tap(tester, 'Cancel');
    expect(store.readFailed.value, true);
    expect(file.writes, 0);
    await tap(tester, 'Reset setup');
    await tap(tester, 'Reset setup');
    expect(store.readFailed.value, false);
    expect(file.writes, greaterThan(0));
  });

  testWidgets(
    'content replacement while picking shows removed selection and confirms All',
    (tester) async {
      await pump(tester, english: true);
      await tap(tester, 'Categories');
      await tap(tester, 'Category b');
      final data = fixture();
      (data['words'] as List).removeWhere((w) => w['category_id'] == 'b');
      content.snapshot.value = ContentSnapshot.fromJson(data, 'vi');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Unavailable categories were removed.'),
        findsOneWidget,
      );
      await tap(tester, 'Confirm');
      expect(store.setup.value.categoryIds, isEmpty);
      expect(find.text('All categories'), findsOneWidget);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 768),
  ]) {
    testWidgets(
      'large text keeps setup, sheet and adaptive picker usable at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pump(tester);
        await tap(tester, 'Người chơi');
        await tap(tester, 'Xác nhận');
        await tap(tester, 'Danh mục');
        await tap(tester, 'Category a');
        await tap(tester, 'Xác nhận');
        await tester.scrollUntilVisible(
          find.text('Bắt đầu ván chơi'),
          180,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        final buttonRect = tester.getRect(
          find.widgetWithText(FilledButton, 'Bắt đầu ván chơi'),
        );
        expect(buttonRect.top, greaterThanOrEqualTo(0));
        expect(buttonRect.bottom, lessThanOrEqualTo(size.height));
        expect(tester.takeException(), null);
      },
    );
  }
}
