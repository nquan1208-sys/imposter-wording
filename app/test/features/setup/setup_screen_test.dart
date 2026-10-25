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
  late MemoryStorage file;
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester, {
    FetchContentPage? fetch,
    MemoryStorage? cache,
    bool load = true,
    bool english = false,
  }) async {
    content = ContentRepository(
      cache: cache ?? MemoryStorage(),
      fetchPage: fetch ?? (t, l, f, e) => fixturePage(fixture(), t, l, f, e),
    );
    file = MemoryStorage();
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
        ? find.byKey(const Key('categoryPicker'))
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

  testWidgets('roster edits validate, reorder, cancel and persist', (
    tester,
  ) async {
    await pump(tester, english: true);
    await tap(tester, 'Players');
    await tester.enterText(find.byKey(const ValueKey('name-player-1')), '  ');
    await tester.pumpAndSettle();
    expect(find.text('Enter a name.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm'))
          .onPressed,
      null,
    );
    await tester.enterText(
      find.byKey(const ValueKey('name-player-1')),
      '  Alex  ',
    );
    await tester.tap(find.byTooltip('Move down').first);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tap(tester, 'Cancel');
    expect(store.setup.value.players.first.name, 'Player 1');
    await tap(tester, 'Confirm');
    expect(store.setup.value.players[1].name, 'Alex');
    expect(store.setup.value.players[1].id, 'player-1');
    await tap(tester, 'Players');
    await tester.tap(find.byTooltip('Remove player').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove player'), findsNWidgets(3));
    await tester.scrollUntilVisible(
      find.text('Add player'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tap(tester, 'Add player');
    await tap(tester, 'Confirm');
    expect(store.setup.value.players, hasLength(4));
    expect(store.setup.value.players.last.id, 'player-5');
    await tap(tester, 'Players');
    await tester.enterText(find.byType(TextFormField).first, 'Unsaved');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tap(tester, 'Discard');
    expect(store.setup.value.players.any((p) => p.name == 'Unsaved'), false);
    expect(file.data!['players'], hasLength(4));
  });

  testWidgets('imposter sheet cancel/confirm and rule switches', (
    tester,
  ) async {
    await pump(tester, english: true);
    store.setPlayerCount(7);
    await tester.pumpAndSettle();
    await tap(tester, 'Imposters');
    await tester.tap(find.byTooltip('More imposters'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(store.setup.value.imposters, 1);
    await tap(tester, 'Imposters');
    await tester.tap(find.byTooltip('More imposters'));
    await tester.pumpAndSettle();
    await tap(tester, 'Confirm');
    expect(store.setup.value.imposters, 2);
    await tap(tester, 'Imposters');
    await tap(tester, 'Random');
    await tap(tester, 'Confirm');
    expect(store.setup.value.randomImposters, true);
    for (final label in [
      'Imposters never start',
      'Show category to imposters',
      'Imposters know each other',
    ]) {
      await tap(tester, label);
    }
    expect(store.setup.value.imposterNotFirst, true);
    expect(store.setup.value.showCategory, true);
    expect(store.setup.value.knowEachOther, true);
  });

  testWidgets(
    'landing opens setup; picker cancel discards and confirm commits',
    (tester) async {
      await pump(tester);
      expect(find.text('4'), findsOneWidget);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('4 người chơi'), findsOneWidget);
      semantics.dispose();
      expect(find.byType(Switch), findsNWidgets(3));
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

  testWidgets('player card opens roster and saved count follows roster', (
    tester,
  ) async {
    await pump(tester, english: true);
    expect(find.text('Edit player names'), findsNothing);
    await tap(tester, 'Players');
    expect(find.text('Edit player names'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byTooltip('Fewer players'), findsNothing);
    expect(find.byTooltip('More players'), findsNothing);
    await tester.tap(find.byTooltip('Remove player').first);
    await tester.pumpAndSettle();
    for (final button in tester.widgetList<IconButton>(
      find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Remove player',
      ),
    )) {
      expect(button.onPressed, null);
    }
    await tap(tester, 'Confirm');
    expect(store.setup.value.players.length, 3);
    expect(find.bySemanticsLabel('3 players'), findsOneWidget);

    await tap(tester, 'Players');
    await tap(tester, 'Add player');
    await tap(tester, 'Confirm');
    expect(find.bySemanticsLabel('4 players'), findsOneWidget);
    await tap(tester, 'Players');
    await tester.tap(find.byTooltip('Remove player').first);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tap(tester, 'Discard');
    expect(find.bySemanticsLabel('4 players'), findsOneWidget);

    store.setPlayerCount(100);
    await tester.pumpAndSettle();
    await tap(tester, 'Players');
    await tester.scrollUntilVisible(
      find.text('Add player'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Add player'))
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

  testWidgets('saving fewer players clamps the displayed imposter count', (
    tester,
  ) async {
    await pump(tester, english: true);
    store.setPlayerCount(5);
    store.setRules(imposters: 2);
    await tester.pumpAndSettle();
    await tap(tester, 'Players');
    await tester.tap(find.byTooltip('Remove player').first);
    await tester.pumpAndSettle();
    await tap(tester, 'Confirm');
    expect(find.bySemanticsLabel('4 players'), findsOneWidget);
    expect(find.bySemanticsLabel('Imposters: 1'), findsOneWidget);
    expect(store.setup.value.imposters, 1);
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
      cache: MemoryStorage(data),
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
        await tester.enterText(
          find.byKey(const ValueKey('name-player-1')),
          '  An  ',
        );
        await tester.pumpAndSettle();
        await tap(tester, 'Xác nhận');
        expect(store.setup.value.players.first.name, 'An');
        await tap(tester, 'Kẻ mạo danh');
        await tap(tester, 'Ngẫu nhiên');
        await tap(tester, 'Xác nhận');
        expect(store.setup.value.randomImposters, true);
        await tester.scrollUntilVisible(
          find.text('Người chơi'),
          -180,
          scrollable: find.byType(Scrollable).first,
        );
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
