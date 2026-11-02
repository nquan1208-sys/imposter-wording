import 'package:untitled/widgets/app_selection_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/features/question_game/question_game_screen.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/main.dart';
import '../../data/memory_app_settings_storage.dart';
import '../../data/fixtures.dart';
import 'package:untitled/models/content.dart';

void main() {
  late ContentRepository content;
  late SetupStore setup;
  late ProviderContainer container;
  late JsonMap fetchData;

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        160,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> pump(
    WidgetTester tester, {
    bool english = false,
    bool family = false,
    bool showCategory = true,
    bool knowEachOther = true,
    bool random = false,
    int imposters = 2,
    int playerCount = 5,
  }) async {
    fetchData = fixture(locale: english ? 'en' : 'vi');
    content = ContentRepository(
      contentLocale: english ? 'en' : 'vi',
      cache: MemoryStorage(),
      fetchPage: (t, l, f, e) => fixturePage(fetchData, t, l, f, e),
    );
    setup = SetupStore(content: content, file: MemoryStorage());
    await content.load();
    await setup.restore();
    if (english) await setup.setContentLocale('en');
    await setup.setPlayerCount(playerCount);
    await setup.setRules(
      imposters: imposters,
      showCategory: showCategory,
      knowEachOther: knowEachOther,
      randomImposters: random,
      imposterNotFirst: true,
    );
    await setup.setFamily(family);
    final presetId = await setup.createPreset(
      'Question team',
      setup.setup.value,
    );
    await setup.confirmDraft(setup.setup.value.presets.single.setup, presetId);
    container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(MemoryAppSettingsStorage()),
        contentRepositoryProvider(
          english ? 'en' : 'vi',
        ).overrideWithValue(content),
        setupStoreProvider.overrideWithValue(setup),
      ],
    );
    await container.read(StoreProvider.app).restore();
    if (english) {
      expect(await setup.setContentLocale('en'), isTrue);
    }
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      setup.dispose();
      content.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    await tap(tester, find.text(english ? 'Start' : 'Bắt đầu'));
    await tap(
      tester,
      find.text(english ? 'Question game' : 'Trò chơi câu hỏi'),
    );
    expect(setup.setup.value.gameType, 'question');
    expect(
      find.text(
        english
            ? 'Show category to imposters'
            : 'Hiển thị tên danh mục cho kẻ mạo danh',
      ),
      findsNothing,
    );
    expect(
      find.text(
        english ? 'Imposters know each other' : 'Kẻ mạo danh biết nhau',
      ),
      findsOneWidget,
    );
    await tap(tester, find.byKey(const Key('categoryPicker')));
    expect(find.text('Category a'), findsNothing);
    await tap(tester, find.widgetWithText(AppSelectionCard, 'Category q'));
    await tap(
      tester,
      find.widgetWithText(FilledButton, english ? 'Confirm' : 'Xác nhận'),
    );
    expect(setup.setup.value.categoryIds, {'q'});
    await tap(
      tester,
      find.widgetWithText(
        FilledButton,
        english ? 'Start game' : 'Bắt đầu ván chơi',
      ),
    );
  }

  testWidgets(
    'question handoff stays lazy and private with 100 players and large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(tester, english: true, playerCount: 100);
      final cards = find.byType(AppSelectionCard);
      expect(cards.evaluate().length, lessThan(100));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('player-100')),
        400,
        maxScrolls: 150,
        scrollable: find.byType(Scrollable).last,
      );
      await tap(tester, find.byKey(const ValueKey('player-100')));
      expect(find.byKey(const Key('secretCard')), findsOneWidget);
      expect(find.byKey(const Key('privateAnswer')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'teammates leave widgets and semantics on conceal, back and submission',
    (tester) async {
      await pump(tester, english: true);
      final session = tester
          .widget<QuestionGameScreen>(find.byType(QuestionGameScreen))
          .session;
      final imposter = session.setup.players.firstWhere(
        (p) => session.imposterIds.contains(p.id),
      );
      final other = session.setup.players.firstWhere(
        (p) => p.id != imposter.id && session.imposterIds.contains(p.id),
      );
      final semantics = tester.ensureSemantics();
      final teammates = find.byKey(const Key('questionTeammates'));
      await tap(tester, find.byKey(ValueKey(imposter.id)));
      expect(teammates, findsNothing);
      expect(find.bySemanticsLabel(other.name), findsNothing);
      await tap(tester, find.text('Tap to reveal'));
      expect(
        find.descendant(of: teammates, matching: find.text(other.name)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: teammates, matching: find.text(imposter.name)),
        findsNothing,
      );
      expect(find.bySemanticsLabel(other.name), findsOneWidget);
      fetchData = {'categories': [], 'words': [], 'questions': []};
      await content.load();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<QuestionGameScreen>(find.byType(QuestionGameScreen))
            .session,
        same(session),
      );
      expect(teammates, findsOneWidget);
      await setup.setRules(knowEachOther: false, showCategory: false);
      expect(
        find.descendant(of: teammates, matching: find.text(other.name)),
        findsOneWidget,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(teammates, findsNothing);
      expect(find.bySemanticsLabel(other.name), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(teammates, findsNothing);
      await tap(tester, find.text('Tap to reveal'));
      expect(teammates, findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(teammates, findsNothing);
      await tap(tester, find.byKey(ValueKey(imposter.id)));
      await tap(tester, find.text('Tap to reveal'));
      await tester.enterText(find.byKey(const Key('privateAnswer')), 'answer');
      await tap(tester, find.text('Submit answer'));
      expect(teammates, findsNothing);
      final civilian = session.setup.players.firstWhere(
        (p) => !session.imposterIds.contains(p.id),
      );
      await tap(tester, find.byKey(ValueKey(civilian.id)));
      await tap(tester, find.text('Tap to reveal'));
      expect(teammates, findsNothing);
      semantics.dispose();
    },
  );

  for (final show in [false, true]) {
    for (final know in [false, true]) {
      for (final random in [false, true]) {
        testWidgets(
          'question ignores word-only category=$show, know=$know random=$random',
          (tester) async {
            await pump(
              tester,
              english: true,
              showCategory: show,
              knowEachOther: know,
              random: random,
            );
            final session = tester
                .widget<QuestionGameScreen>(find.byType(QuestionGameScreen))
                .session;
            final id = session.imposterIds.first;
            await tap(tester, find.byKey(ValueKey(id)));
            expect(find.text(session.categoryName), findsNothing);
            await tap(tester, find.text('Tap to reveal'));
            expect(find.text(session.categoryName), findsNothing);
            expect(
              find.byKey(const Key('questionTeammates')),
              know && session.imposterIds.length > 1
                  ? findsOneWidget
                  : findsNothing,
            );
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            final civilian = session.setup.players.firstWhere(
              (p) => !session.imposterIds.contains(p.id),
            );
            await tap(tester, find.byKey(ValueKey(civilian.id)));
            await tap(tester, find.text('Tap to reveal'));
            expect(find.text(session.categoryName), findsOneWidget);
            expect(find.byKey(const Key('questionTeammates')), findsNothing);
          },
        );
      }
    }
  }

  for (final english in [false, true]) {
    for (final family in [false, true]) {
      testWidgets(
        'private flow, drafts, lifecycle, reveal and replay (en: $english, family: $family)',
        (tester) async {
          tester.view.physicalSize = family
              ? const Size(844, 390)
              : const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          tester.platformDispatcher.platformBrightnessTestValue = family
              ? Brightness.dark
              : Brightness.light;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          final semantics = tester.ensureSemantics();
          try {
            await pump(tester, english: english, family: family);
            final session = tester
                .widget<QuestionGameScreen>(find.byType(QuestionGameScreen))
                .session;
            final reveal = english ? 'Tap to reveal' : 'Nhấn để hiển thị';
            final submit = english ? 'Submit answer' : 'Gửi câu trả lời';
            final first = session.setup.players.first.id;
            final second = session.setup.players[1].id;
            await tap(tester, find.byKey(ValueKey(first)));
            expect(find.text(session.prompt.civilianQuestion), findsNothing);
            expect(find.text(session.prompt.imposterQuestion), findsNothing);
            expect(find.byKey(const Key('privateAnswer')), findsNothing);
            expect(
              find.bySemanticsLabel(session.prompt.imposterQuestion),
              findsNothing,
            );
            await tap(tester, find.text(reveal));
            await tester.enterText(
              find.byKey(const Key('privateAnswer')),
              '  private draft  ',
            );
            await tester.pumpAndSettle();
            tester.view.viewInsets = const FakeViewPadding(bottom: 180);
            await tester.pumpAndSettle();
            final submitRect = tester.getRect(
              find.widgetWithText(FilledButton, submit),
            );
            expect(
              submitRect.bottom,
              lessThanOrEqualTo(tester.view.physicalSize.height - 180),
            );
            tester.view.resetViewInsets();
            await tester.pumpAndSettle();
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
            await tester.pumpAndSettle();
            expect(find.byType(TextField), findsNothing);
            expect(find.text(session.prompt.imposterQuestion), findsNothing);
            expect(find.text(session.prompt.civilianQuestion), findsNothing);
            expect(find.bySemanticsLabel('private draft'), findsNothing);
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
            await tester.pumpAndSettle();
            expect(find.byType(TextField), findsNothing);
            await tap(tester, find.text(reveal));
            expect(
              tester.widget<TextField>(find.byType(TextField)).controller!.text,
              '  private draft  ',
            );
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            await tap(tester, find.byKey(ValueKey(second)));
            await tap(tester, find.text(reveal));
            expect(
              tester.widget<TextField>(find.byType(TextField)).controller!.text,
              '',
            );
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            for (final p in session.setup.players) {
              await tap(tester, find.byKey(ValueKey(p.id)));
              expect(find.byType(TextField), findsNothing);
              await tap(tester, find.text(reveal));
              expect(
                find.text(
                  session.imposterIds.contains(p.id)
                      ? session.prompt.imposterQuestion
                      : session.prompt.civilianQuestion,
                ),
                findsOneWidget,
              );
              expect(
                find.text(
                  english ? 'You are the imposter' : 'Bạn là kẻ mạo danh',
                ),
                findsNothing,
              );
              if (p.id == first) {
                expect(
                  tester
                      .widget<TextField>(find.byType(TextField))
                      .controller!
                      .text,
                  '  private draft  ',
                );
              }
              await tester.enterText(find.byType(TextField), '   ');
              await tester.pumpAndSettle();
              expect(
                tester
                    .widget<FilledButton>(
                      find.widgetWithText(FilledButton, submit),
                    )
                    .onPressed,
                null,
              );
              await tester.enterText(
                find.byType(TextField),
                '  answer ${p.id}  ',
              );
              await tester.pumpAndSettle();
              await tap(tester, find.widgetWithText(FilledButton, submit));
              if (p != session.setup.players.last) {
                expect(find.text('answer ${p.id}'), findsNothing);
                if (find.byKey(ValueKey(p.id)).evaluate().isEmpty) {
                  await tester.scrollUntilVisible(
                    find.byKey(ValueKey(p.id)),
                    160,
                    scrollable: find.byType(Scrollable).first,
                  );
                }
                await tester.ensureVisible(find.byKey(ValueKey(p.id)));
                expect(
                  tester
                      .widget<AppSelectionCard>(find.byKey(ValueKey(p.id)))
                      .onTap,
                  null,
                );
              }
            }
            expect(find.text(session.prompt.civilianQuestion), findsOneWidget);
            expect(find.text('answer $first'), findsNothing);
            await tap(
              tester,
              find.widgetWithText(
                FilledButton,
                english ? 'Start round' : 'Bắt đầu vòng',
              ),
            );
            expect(find.text(session.prompt.imposterQuestion), findsNothing);
            expect(
              find.bySemanticsLabel(session.prompt.imposterQuestion),
              findsNothing,
            );
            for (final p in session.setup.players) {
              await tester.scrollUntilVisible(
                find.text('answer ${p.id}'),
                160,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.ensureVisible(find.text('answer ${p.id}'));
              await tester.pumpAndSettle();
              expect(find.text('answer ${p.id}').hitTestable(), findsOneWidget);
              expect(
                find.bySemanticsLabel(session.prompt.imposterQuestion),
                findsNothing,
              );
            }
            await tap(
              tester,
              find.widgetWithText(
                FilledButton,
                english ? 'Find the imposters' : 'Tìm kẻ giả mạo',
              ),
            );
            for (final p in session.setup.players) {
              final response = find.text('answer ${p.id}');
              await tester.scrollUntilVisible(
                response,
                160,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.ensureVisible(response);
              await tester.pumpAndSettle();
              final card = find
                  .ancestor(of: response, matching: find.byType(Card))
                  .first;
              expect(
                find.descendant(
                  of: card,
                  matching: find.text(session.prompt.imposterQuestion),
                ),
                session.imposterIds.contains(p.id)
                    ? findsOneWidget
                    : findsNothing,
              );
            }

            final previous = setup.setup.value.toJson();
            await tap(
              tester,
              find.widgetWithText(
                FilledButton,
                english ? 'Play again' : 'Chơi lại',
              ),
            );
            expect(setup.setup.value.toJson(), previous);
            await tap(
              tester,
              find.widgetWithText(
                FilledButton,
                english ? 'Start game' : 'Bắt đầu ván chơi',
              ),
            );
            final next = tester
                .widget<QuestionGameScreen>(find.byType(QuestionGameScreen))
                .session;
            expect(identical(next, session), false);
            await tap(tester, find.byKey(ValueKey(first)));
            await tap(tester, find.text(reveal));
            expect(
              tester.widget<TextField>(find.byType(TextField)).controller!.text,
              '',
            );
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            await tap(
              tester,
              find.widgetWithText(TextButton, english ? 'Cancel' : 'Hủy'),
            );
            expect(find.byType(QuestionGameScreen), findsOneWidget);
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            await tap(
              tester,
              find.widgetWithText(
                TextButton,
                english ? 'End game' : 'Kết thúc ván',
              ),
            );
            await tap(
              tester,
              find.widgetWithText(
                AppSelectionCard,
                english ? 'Word game' : 'Trò chơi từ ngữ',
              ),
            );
            expect(setup.setup.value.gameType, 'word');
            expect(setup.setup.value.categoryIds, isEmpty);
            expect(setup.setup.value.showCategory, true);
            expect(tester.takeException(), null);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}
