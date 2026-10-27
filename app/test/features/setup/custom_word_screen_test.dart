import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/features/custom_content/custom_word_screen.dart';
import 'package:untitled/features/setup/category_screen.dart';
import 'package:untitled/features/setup/setup_screen.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/features/word_game/word_game_screen.dart';
import 'package:untitled/features/question_game/question_game_screen.dart';
import 'package:flutter/services.dart';
import 'package:untitled/main.dart';
import 'package:untitled/l10n/gen_l10n/app_localizations.dart';
import 'package:untitled/theme/app_theme.dart';
import '../../data/fixtures.dart';

void main() {
  late ContentRepository content;
  late SetupStore store;
  late MemoryStorage file;
  late ProviderContainer container;

  Future<void> tap(WidgetTester tester, String text) async {
    final matches = find.text(text);
    if (matches.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        matches,
        180,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .last,
      );
    }
    final target = matches.last;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> pump(
    WidgetTester tester, {
    bool offline = false,
    bool english = true,
  }) async {
    content = ContentRepository(
      cache: MemoryStorage(),
      fetchPage: (t, l, f, e) => fixturePage(fixture(), t, l, f, e),
    );
    file = MemoryStorage();
    store = SetupStore(content: content, file: file);
    await store.restore();
    if (!offline) await content.load();
    await store.setPlayerCount(3);
    container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(content),
        setupStoreProvider.overrideWithValue(store),
      ],
    );
    if (english) {
      container.read(StoreProvider.app).setLocale(const Locale('en'));
    }
    addTearDown(() {
      container.dispose();
      store.dispose();
      content.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    await tap(tester, english ? 'Start' : 'Bắt đầu');
  }

  Future<void> picker(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('categoryPicker')));
    await tester.tap(find.byKey(const Key('categoryPicker')));
    await tester.pumpAndSettle();
  }

  Future<void> word(
    WidgetTester tester,
    String value, {
    bool batch = false,
  }) async {
    await tap(tester, batch ? 'Import words' : 'Add word');
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      value,
    );
    await tap(tester, 'Confirm');
  }

  Future<void> questionEntry(
    WidgetTester tester,
    String civilian,
    String imposter, {
    bool batch = false,
    bool english = true,
  }) async {
    await tap(
      tester,
      batch
          ? (english ? 'Import question pairs' : 'Nhập nhiều cặp câu hỏi')
          : (english ? 'Add question pair' : 'Thêm cặp câu hỏi'),
    );
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.first, civilian);
    await tester.enterText(fields.last, imposter);
    await tap(tester, english ? 'Confirm' : 'Xác nhận');
  }

  for (final english in [true, false]) {
    testWidgets('custom-only offline question game and replay ($english)', (
      tester,
    ) async {
      await pump(tester, offline: true, english: english);
      await store.setGameType('question');
      await tester.pumpAndSettle();
      await picker(tester);
      await tap(
        tester,
        english ? 'Create custom category' : 'Tạo danh mục tùy chỉnh',
      );
      await tester.enterText(find.byType(TextField), 'Local questions');
      await questionEntry(tester, 'Civilian?', 'Imposter?', english: english);
      await tap(tester, english ? 'Save category' : 'Lưu danh mục');
      expect(store.setup.value.categoryIds, isEmpty);
      await tap(tester, english ? 'Confirm' : 'Xác nhận');
      expect(store.setup.value.categoryIds, {'custom-question-1'});
      await tap(tester, english ? 'Start game' : 'Bắt đầu ván chơi');
      final session = tester
          .widget<QuestionGameScreen>(find.byType(QuestionGameScreen))
          .session;
      final semantics = tester.ensureSemantics();
      for (final player in session.setup.players) {
        final target = find.byKey(ValueKey(player.id));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(find.text('Imposter?'), findsNothing);
        expect(find.text('Civilian?'), findsNothing);
        await tap(tester, english ? 'Tap to reveal' : 'Nhấn để hiển thị');
        final imposter = session.imposterIds.contains(player.id);
        expect(find.text(imposter ? 'Imposter?' : 'Civilian?'), findsOneWidget);
        expect(
          find.bySemanticsLabel(imposter ? 'Civilian?' : 'Imposter?'),
          findsNothing,
        );
        await tester.enterText(
          find.byKey(const Key('privateAnswer')),
          'Answer',
        );
        await tap(tester, english ? 'Submit answer' : 'Gửi câu trả lời');
      }
      expect(find.text('Civilian?'), findsOneWidget);
      expect(find.text('Imposter?'), findsNothing);
      await tap(tester, english ? 'Start round' : 'Bắt đầu vòng');
      expect(find.bySemanticsLabel('Imposter?'), findsNothing);
      await tap(tester, english ? 'Find the imposters' : 'Tìm kẻ giả mạo');
      expect(find.text('Imposter?'), findsOneWidget);
      await tap(tester, english ? 'Play again' : 'Chơi lại');
      expect(
        store.setup.value.customQuestionCategories.single.name,
        'Local questions',
      );
      await tap(tester, english ? 'Start game' : 'Bắt đầu ván chơi');
      expect(
        tester
            .widget<QuestionGameScreen>(find.byType(QuestionGameScreen))
            .session
            .prompt
            .imposterQuestion,
        'Imposter?',
      );
      semantics.dispose();
    });
  }

  testWidgets('question import errors, discard, failed save and picker draft', (
    tester,
  ) async {
    await pump(tester, offline: true);
    await store.setGameType('question');
    await tester.pumpAndSettle();
    await picker(tester);
    await tap(tester, 'Create custom category');
    await tester.enterText(find.byType(TextField), 'Draft');
    await questionEntry(tester, 'A\n\nC', 'B\nD\nE', batch: true);
    expect(find.textContaining('Check rows 2:'), findsOneWidget);
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.first, 'A\nC');
    await tester.enterText(fields.last, 'B\nD');
    await tap(tester, 'Cancel');
    await tap(tester, 'Cancel');
    expect(find.text('A\nC'), findsOneWidget);
    await tap(tester, 'Confirm');
    await tester.tap(find.byTooltip('Remove pair 2'));
    await tester.pumpAndSettle();
    file.failWrite = true;
    await tap(tester, 'Save category');
    expect(
      find.text(
        'Could not save. Your question pairs are still here. Try saving again.',
      ),
      findsOneWidget,
    );
    expect(store.setup.value.nextCustomQuestionCategoryId, 1);
    file.failWrite = false;
    await tap(tester, 'Save category');
    expect(store.setup.value.customQuestionCategories.single.pairs.length, 1);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(store.setup.value.categoryIds, isEmpty);
    await picker(tester);
    await tap(tester, 'Create custom category');
    await tester.enterText(find.byType(TextField), 'Unsaved');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tap(tester, 'Discard');
    expect(store.setup.value.customQuestionCategories.length, 1);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    file.failWrite = true;
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tap(tester, 'Remove and leave');
    expect(find.byType(SetupScreen), findsOneWidget);
    expect(store.setup.value.customQuestionCategories.length, 1);
    file.failWrite = false;
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tap(tester, 'Remove and leave');
    expect(store.setup.value.hasCustomContent, false);
  });

  testWidgets(
    'question form supports small screen, large text, keyboard and semantics',
    (tester) async {
      await pump(tester, offline: true);
      await store.setGameType('question');
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                viewInsets: const EdgeInsets.only(bottom: 200),
              ),
              child: child!,
            ),
            home: const CustomWordScreen(family: false, gameType: 'question'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Local');
      await tap(tester, 'Add question pair');
      expect(find.bySemanticsLabel('Civilian question'), findsOneWidget);
      expect(find.bySemanticsLabel('Imposter question'), findsOneWidget);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), 'A?');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.enterText(fields.last, 'B?');
      await tap(tester, 'Confirm');
      expect(
        tester
            .getRect(find.widgetWithText(FilledButton, 'Save category'))
            .bottom,
        lessThanOrEqualTo(368),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  for (final english in [true, false]) {
    for (final dark in [false, true]) {
      testWidgets(
        'small form, large text, keyboard and semantics (en=$english, dark=$dark)',
        (tester) async {
          await pump(tester, english: english);
          await tester.binding.setSurfaceSize(const Size(320, 568));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                locale: Locale(english ? 'en' : 'vi'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: dark ? AppTheme.dark : AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                    viewInsets: const EdgeInsets.only(bottom: 200),
                  ),
                  child: child!,
                ),
                home: const CustomWordScreen(family: true),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.bySemanticsLabel(english ? 'Category name' : 'Tên danh mục'),
            findsOneWidget,
          );
          final nameField = find.byType(TextField);
          await tester.enterText(nameField, 'Local');
          await tester.ensureVisible(nameField);
          await tester.pumpAndSettle();
          await tap(tester, english ? 'Add word' : 'Thêm từ');
          expect(tester.takeException(), isNull);
          final entry = find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          );
          await tester.enterText(entry, 'Apple');
          await tap(tester, english ? 'Confirm' : 'Xác nhận');
          final checkbox = find.byType(CheckboxListTile);
          await tester.scrollUntilVisible(
            checkbox,
            120,
            scrollable: find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                )
                .first,
          );
          await tester.ensureVisible(checkbox);
          final control = find.descendant(
            of: checkbox,
            matching: find.byType(Checkbox),
          );
          await tester.ensureVisible(control);
          await tester.pumpAndSettle();
          await tester.tap(control);
          await tester.pumpAndSettle();
          final save = find.widgetWithText(
            FilledButton,
            english ? 'Save category' : 'Lưu danh mục',
          );
          expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
          expect(tester.getRect(save).bottom, lessThanOrEqualTo(368));
          expect(tester.takeException(), isNull);
          semantics.dispose();
        },
      );
    }
  }

  testWidgets(
    'batch import, delete, name collision, failed save and picker draft cancellation',
    (tester) async {
      await pump(tester);
      await store.setCategories({'a'});
      await picker(tester);
      await tap(tester, 'Create custom category');
      await tester.enterText(find.byType(TextField), ' category B ');
      await tester.pump();
      expect(
        find.text('This category name already exists. Choose another name.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), ' Office ');
      await word(tester, '  Alpha \nalpha\n\n Beta\r\nGamma ', batch: true);
      expect(find.text('3 eligible words'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove Gamma'));
      await tester.pumpAndSettle();
      expect(find.text('2 eligible words'), findsOneWidget);
      file.failWrite = true;
      await tap(tester, 'Save category');
      expect(find.byType(CustomWordScreen), findsOneWidget);
      expect(
        find.text(
          'Could not save. Your words are still here. Try saving again.',
        ),
        findsOneWidget,
      );
      expect(store.setup.value.customWordCategories, isEmpty);
      file.failWrite = false;
      await tap(tester, 'Save category');
      expect(find.byType(CategoryScreen), findsOneWidget);
      final id = store.setup.value.customWordCategories.single.id;
      final custom = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Office'),
      );
      expect(custom.onPressed, isNotNull);
      expect(store.setup.value.categoryIds, {'a'});
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(store.setup.value.categoryIds, {'a'});
      expect(store.setup.value.customWordCategories.single.id, id);
      await picker(tester);
      await tap(tester, 'Office');
      await tap(tester, 'Confirm');
      expect(store.setup.value.categoryIds, {'a', id});
    },
  );

  testWidgets(
    'form and nested word draft guard Back without publishing partial content',
    (tester) async {
      await pump(tester);
      await picker(tester);
      await tap(tester, 'Create custom category');
      await tester.enterText(find.byType(TextField), 'Draft');
      await tap(tester, 'Add word');
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Pending',
      );
      await tap(tester, 'Cancel');
      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      await tap(tester, 'Cancel');
      expect(find.text('Pending'), findsOneWidget);
      await tap(tester, 'Confirm');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tap(tester, 'Cancel');
      expect(find.byType(CustomWordScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tap(tester, 'Discard');
      expect(find.byType(CategoryScreen), findsOneWidget);
      expect(store.setup.value.customWordCategories, isEmpty);
    },
  );

  testWidgets(
    'Family creation requires suitability and preserves the picker tab',
    (tester) async {
      await pump(tester);
      await picker(tester);
      await tap(tester, 'Family mode');
      await tap(tester, 'Create custom category');
      await tester.enterText(find.byType(TextField), 'Family words');
      await word(tester, 'Apple');
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save category'),
            )
            .onPressed,
        isNull,
      );
      await tap(tester, 'I confirm these words are suitable for family play.');
      await tap(tester, 'Save category');
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
      expect(
        store.setup.value.family,
        false,
        reason: 'tab remains a picker draft',
      );
      final custom = store.setup.value.customWordCategories.single;
      expect(custom.isFamilyFriendly, true);
      await tap(tester, 'Confirm');
      expect(store.setup.value.family, true);
      expect(store.setup.value.categoryIds, {custom.id});
    },
  );

  testWidgets(
    'one-word custom-only offline game completes and replay retains content',
    (tester) async {
      await pump(tester, offline: true);
      await picker(tester);
      await tap(tester, 'Create custom category');
      await tester.enterText(find.byType(TextField), 'Solo');
      await word(tester, 'Only word');
      await tap(tester, 'Save category');
      await tap(tester, 'Confirm');
      await tap(tester, 'Start game');
      final session = tester
          .widget<WordGameScreen>(find.byType(WordGameScreen))
          .session;
      for (final player in session.setup.players) {
        final target = find.byKey(ValueKey(player.id));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(find.text('Only word'), findsNothing);
        await tap(tester, 'Tap to reveal');
        expect(
          find.text('Only word'),
          session.imposterIds.contains(player.id)
              ? findsNothing
              : findsOneWidget,
        );
        await tap(tester, 'Got it!');
      }
      await tap(tester, 'Announce results');
      final imposter = session.setup.players.firstWhere(
        (p) => session.imposterIds.contains(p.id),
      );
      await tap(tester, imposter.name);
      await tap(tester, 'Confirm');
      expect(find.text('Only word'), findsOneWidget);
      await tap(tester, 'Play again');
      expect(find.byType(SetupScreen), findsOneWidget);
      expect(store.setup.value.customWordCategories.single.words, [
        'Only word',
      ]);
      await tap(tester, 'Start game');
      expect(
        tester
            .widget<WordGameScreen>(find.byType(WordGameScreen))
            .session
            .prompt
            .text,
        'Only word',
      );
    },
  );

  testWidgets(
    'leaving setup confirms deletion, handles write errors, and preserves roster',
    (tester) async {
      await pump(tester);
      await store.createCustomWordCategory('Office', ['x'], family: false);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Remove custom content and leave?'), findsOneWidget);
      await tap(tester, 'Cancel');
      expect(store.setup.value.customWordCategories.length, 1);
      file.failWrite = true;
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tap(tester, 'Remove and leave');
      expect(find.byType(SetupScreen), findsOneWidget);
      expect(store.setup.value.customWordCategories.length, 1);
      file.failWrite = false;
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tap(tester, 'Remove and leave');
      expect(find.byType(SetupScreen), findsNothing);
      expect(store.setup.value.customWordCategories, isEmpty);
      expect(store.setup.value.players.length, 3);
    },
  );
}
