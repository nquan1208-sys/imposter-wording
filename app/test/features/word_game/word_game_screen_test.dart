import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/features/word_game/word_game_screen.dart';
import 'package:untitled/features/word_game/word_game_store.dart';
import 'package:untitled/main.dart';
import 'package:untitled/models/content.dart';
import '../../data/fixtures.dart';

void main() {
  late ContentRepository content;
  late SetupStore setup;
  late ProviderContainer container;
  late WordGameSession session;

  Future<void> tap(WidgetTester tester, String text) async {
    final target = find.text(text);
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        180,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(target.last);
    await tester.pumpAndSettle();
    await tester.tap(target.last);
    await tester.pumpAndSettle();
  }

  Future<void> pump(
    WidgetTester tester, {
    bool english = false,
    bool direct = true,
    bool advanced = false,
  }) async {
    content = ContentRepository(
      cache: MemoryStorage(),
      fetchPage: (t, l, f, e) => fixturePage(fixture(), t, l, f, e),
    );
    setup = SetupStore(content: content, file: MemoryStorage());
    await content.load();
    await setup.restore();
    setup.setPlayerCount(advanced ? 5 : 3);
    if (advanced) {
      setup.setRules(
        imposters: 2,
        showCategory: true,
        knowEachOther: true,
        imposterNotFirst: true,
      );
    }
    session = WordGameSession.create(setup, random: Random(3))!;
    container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(content),
        setupStoreProvider.overrideWithValue(setup),
      ],
    );
    if (english) {
      container.read(StoreProvider.app).setLocale(const Locale('en'));
    }
    addTearDown(() {
      container.dispose();
      setup.dispose();
      content.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    if (direct) {
      await tap(tester, english ? 'Start' : 'Bắt đầu');
      final context = tester.element(find.byType(Scaffold).first);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WordGameScreen(session: session),
        ),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> finish(WidgetTester tester, {bool english = false}) async {
    for (final p in session.setup.players) {
      final player = find.byKey(ValueKey(p.id));
      if (player.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          player,
          160,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
      }
      await tester.ensureVisible(player);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey(p.id)));
      await tester.pumpAndSettle();
      expect(find.text(session.prompt.text), findsNothing);
      await tap(tester, english ? 'Tap to reveal' : 'Nhấn để hiển thị');
      if (session.imposterIds.contains(p.id)) {
        expect(find.text(session.prompt.text), findsNothing);
        expect(
          find.text(session.categoryName),
          session.setup.showCategory ? findsOneWidget : findsNothing,
        );
      } else {
        expect(find.text(session.prompt.text), findsOneWidget);
      }
      await tap(tester, english ? 'Got it!' : 'Hiểu rồi!');
      if (p != session.setup.players.last) {
        await tester.scrollUntilVisible(
          find.byKey(ValueKey(p.id)),
          160,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(
          tester.widget<TextButton>(find.byKey(ValueKey(p.id))).onPressed,
          null,
        );
      }
    }
  }

  testWidgets(
    'teammates/category are private until reveal; exact multi-vote wins',
    (tester) async {
      await pump(tester, english: true, advanced: true);
      final semantics = tester.ensureSemantics();
      final imposter = session.setup.players.firstWhere(
        (p) => session.imposterIds.contains(p.id),
      );
      await tap(tester, imposter.name);
      expect(find.textContaining('Other imposters:'), findsNothing);
      expect(find.text(session.categoryName), findsNothing);
      expect(find.text(session.prompt.text), findsNothing);
      await tap(tester, 'Tap to reveal');
      final other = session.setup.players.firstWhere(
        (p) => session.imposterIds.contains(p.id) && p.id != imposter.id,
      );
      expect(find.text('Other imposters: ${other.name}'), findsOneWidget);
      expect(find.text(session.categoryName), findsOneWidget);
      expect(find.text(session.prompt.text), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.bySemanticsLabel(RegExp('Other imposters:')), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      semantics.dispose();
      await finish(tester, english: true);
      final starter = session.setup.players.firstWhere(
        (p) => p.id == session.startingPlayerId,
      );
      expect(find.text('${starter.name} starts the round.'), findsOneWidget);
      expect(session.imposterIds.contains(starter.id), false);
      await tap(tester, 'Announce results');
      await tap(tester, imposter.name);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm'))
            .onPressed,
        null,
      );
      await tap(tester, other.name);
      await tap(tester, 'Cancel');
      expect(find.text('Results'), findsNothing);
      await tap(tester, 'Announce results');
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm'))
            .onPressed,
        null,
      );
      await tap(tester, imposter.name);
      await tap(tester, other.name);
      await tap(tester, 'Confirm');
      expect(find.text('The group wins!'), findsOneWidget);
      expect(find.textContaining('Imposters:'), findsOneWidget);
    },
  );

  testWidgets('complete round, cancel vote, confirm winner and replay', (
    tester,
  ) async {
    await pump(tester);
    await finish(tester);
    expect(find.text('Giai đoạn bầu chọn'), findsOneWidget);
    await tap(tester, 'Thông báo kết quả');
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Xác nhận'))
          .onPressed,
      null,
    );
    await tap(tester, 'Hủy');
    expect(find.text('Kết quả'), findsNothing);
    await tap(tester, 'Thông báo kết quả');
    final imposter = session.setup.players.firstWhere(
      (p) => p.id == session.imposterIds.single,
    );
    await tap(tester, imposter.name);
    await tap(tester, 'Xác nhận');
    expect(find.text('Nhóm chiến thắng!'), findsOneWidget);
    expect(find.text(session.prompt.text), findsOneWidget);
    final previousSetup = setup.setup.value.toJson();
    await tap(tester, 'Chơi lại');
    expect(find.text('Thiết lập trò chơi'), findsOneWidget);
    expect(find.byType(WordGameScreen), findsNothing);
    expect(setup.setup.value.toJson(), previousSetup);
    await tap(tester, 'Bắt đầu ván chơi');
    expect(find.text('Người chơi'), findsOneWidget);
    expect(
      tester.widget<WordGameScreen>(find.byType(WordGameScreen)).session,
      isNot(same(session)),
    );
    for (final p in session.setup.players) {
      expect(
        tester.widget<TextButton>(find.byKey(ValueKey(p.id))).onPressed,
        isNotNull,
      );
    }
    expect(setup.setup.value.players, hasLength(3));
  });

  testWidgets(
    'conceal on lifecycle, back, semantics and rebuild keep assignment',
    (tester) async {
      await pump(tester);
      final semantics = tester.ensureSemantics();
      final civilian = session.setup.players.firstWhere(
        (p) => p.id != session.imposterIds.single,
      );
      await tap(tester, civilian.name);
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(session.prompt.text))),
        findsNothing,
      );
      expect(find.text(session.categoryName), findsNothing);
      await tap(tester, 'Nhấn để hiển thị');
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(session.prompt.text))),
        findsOneWidget,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(session.prompt.text))),
        findsNothing,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Nhấn để hiển thị'), findsOneWidget);
      content.snapshot.value = ContentSnapshot.fromJson(fixture(), 'vi');
      container.read(StoreProvider.app).setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      await tap(tester, 'Tap to reveal');
      expect(find.text(session.prompt.text), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(session.prompt.text), findsNothing);
      expect(
        tester.widget<TextButton>(find.byKey(ValueKey(civilian.id))).onPressed,
        isNotNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(tester, 'Cancel');
      expect(find.byType(WordGameScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(tester, 'End game');
      expect(find.byType(WordGameScreen), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'play again returns to setup even without content; double start guarded',
    (tester) async {
      await pump(tester, direct: false, english: true);
      await tap(tester, 'Start');
      final start = find.widgetWithText(FilledButton, 'Start game');
      await tester.tap(start);
      await tester.tap(start, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(WordGameScreen), findsOneWidget);
      // The production route has its own random session; finish all players.
      for (final p in session.setup.players) {
        await tap(tester, p.name);
        await tap(tester, 'Tap to reveal');
        await tap(tester, 'Got it!');
      }
      await tap(tester, 'Announce results');
      await tap(tester, session.setup.players.first.name);
      await tap(tester, 'Confirm');
      content.snapshot.value = ContentSnapshot.fromJson({
        'categories': [],
        'words': [],
        'questions': [],
      }, 'vi');
      await tap(tester, 'Play again');
      expect(find.text('Results'), findsNothing);
      expect(find.textContaining('Could not start a game.'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Start game'),
            )
            .onPressed,
        null,
      );
      expect(find.text('Game setup'), findsOneWidget);
      expect(find.byType(WordGameScreen), findsNothing);
    },
  );

  testWidgets('small screen, large text and 100 players remain usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester, direct: false, english: true);
    setup.setPlayerCount(100);
    await tap(tester, 'Start');
    await tap(tester, 'Start game');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('player-100')),
      400,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('player-100')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player-100')));
    await tester.pumpAndSettle();
    await tap(tester, 'Tap to reveal');
    await tap(tester, 'Got it!');
    expect(tester.takeException(), null);
  });

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 768),
  ]) {
    testWidgets('large text keeps voting and results accessible at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(tester, english: true);
      await finish(tester, english: true);
      await tap(tester, 'Announce results');
      await tap(tester, session.setup.players.first.name);
      await tap(tester, 'Confirm');
      expect(find.text('Results'), findsOneWidget);
      expect(find.text('Play again'), findsOneWidget);
      expect(tester.takeException(), null);
    });
  }
}
