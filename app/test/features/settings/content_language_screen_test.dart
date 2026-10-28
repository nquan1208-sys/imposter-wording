import 'package:untitled/widgets/app_selection_card.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/data/content_language_repository.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/features/settings/content_language_screen.dart';
import 'package:untitled/features/word_game/word_game_screen.dart';
import 'package:untitled/main.dart';
import 'package:untitled/models/app_settings.dart';
import '../../data/fixtures.dart';
import '../../data/memory_app_settings_storage.dart';

void main() {
  late SetupStore store;
  late MemoryStorage file;
  late ContentLanguageRepository languages;
  late ProviderContainer container;
  late Map<String, ContentRepository> repositories;
  late Completer<void>? contentGate;

  Future<void> pump(WidgetTester tester, {String ui = 'vi'}) async {
    contentGate = null;
    languages = fixtureLanguages();
    await languages.load();
    repositories = {};
    ContentRepository resolve(String locale) =>
        repositories.putIfAbsent(locale, () {
          final repo = ContentRepository(
            contentLocale: locale,
            cache: MemoryStorage(),
            fetchPage: (t, l, f, e) async {
              if (l != 'vi') await contentGate?.future;
              return fixturePage(localizedFixture(l), t, l, f, e);
            },
          );
          repo.load();
          return repo;
        });
    file = MemoryStorage();
    store = SetupStore(
      content: resolve('vi'),
      file: file,
      languages: languages,
      repositoryForLocale: resolve,
    );
    await store.content.load();
    await store.restore();
    await store.setContentLocale(ui);
    await store.content.load();
    await store.pendingWrites;
    container = ProviderContainer(
      overrides: [
        setupStoreProvider.overrideWithValue(store),
        contentRepositoryProvider.overrideWith(
          (ref, locale) => resolve(locale),
        ),
        localStorageProvider.overrideWithValue(
          MemoryAppSettingsStorage(settings: AppSettings(uiLocale: ui)),
        ),
      ],
    );
    await container.read(StoreProvider.app).restore();
    addTearDown(() {
      container.dispose();
      store.dispose();
      languages.dispose();
      for (final repo in repositories.values) {
        repo.dispose();
      }
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(ui == 'en' ? 'Start' : 'Bắt đầu'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(
    WidgetTester tester,
    Finder finder, {
    double delta = 160,
  }) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        delta,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .last,
      );
    }
    await tester.ensureVisible(finder.last);
    await tester.pumpAndSettle();
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'one choice changes interface and content only after a successful save',
    (tester) async {
      await pump(tester);
      await tap(tester, find.text('Ngôn ngữ'));
      expect(find.byType(ContentLanguageScreen), findsOneWidget);
      expect(find.text('日本語'), findsNothing);
      file.failWrite = true;
      await tap(tester, find.text('English'));
      expect(store.setup.value.contentLocale, 'vi');
      expect(find.text('Ngôn ngữ'), findsOneWidget);
      file.failWrite = false;
      contentGate = Completer<void>();
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(store.setup.value.contentLocale, 'en');
      expect(store.contentReady, false);
      expect(find.text('Language'), findsOneWidget);
      contentGate!.complete();
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.widgetWithText(AppSelectionCard, 'English')),
        isSemantics(isSelected: true, hasSelectedState: true),
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tap(tester, find.text('Start game'));
      expect(
        tester
            .widget<WordGameScreen>(find.byType(WordGameScreen))
            .session
            .contentLocale,
        'en',
      );
      expect(await store.setContentLocale('vi'), false);
    },
  );

  testWidgets('unified language change cancels picker draft', (tester) async {
    await pump(tester);
    await tap(tester, find.byKey(const Key('categoryPicker')));
    await tap(tester, find.widgetWithText(AppSelectionCard, 'vi b'));
    await tap(tester, find.text('Ngôn ngữ'), delta: -160);
    await tap(tester, find.text('English'));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Confirm'));
    expect(store.setup.value.categoryIds, isEmpty);
    await tap(tester, find.text('Start game'));
    final session = tester
        .widget<WordGameScreen>(find.byType(WordGameScreen))
        .session;
    expect(session.contentLocale, 'en');
    expect(session.categoryName, startsWith('en '));
  });

  testWidgets(
    'picker cancels draft when language changes twice before a frame',
    (tester) async {
      await pump(tester);
      await tap(tester, find.byKey(const Key('categoryPicker')));
      await tap(tester, find.widgetWithText(AppSelectionCard, 'vi b'));
      await store.setContentLocale('en');
      await store.setContentLocale('vi');
      await store.pendingWrites;
      await tester.pumpAndSettle();
      await tap(tester, find.text('Xác nhận'));
      expect(store.setup.value.categoryIds, isEmpty);
    },
  );

  testWidgets(
    'small screen, scaled text, unavailable language and cache notice',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(tester, ui: 'en');
      languages.cached.value = true;
      languages.loadFailed.value = true;
      await tap(tester, find.text('Language'));
      await tester.scrollUntilVisible(
        find.text('Using the language list saved on this device.'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Using the language list saved on this device.'),
        findsOneWidget,
      );
      languages.languages.value = languages.languages.value!
          .where((l) => l.code != 'en')
          .toList();
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 1000));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('The saved language is unavailable.'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('The saved language is unavailable.'),
        findsOneWidget,
      );
      expect(store.localeAvailable, false);
      expect(store.setup.value.contentLocale, 'en');
      expect(tester.takeException(), isNull);
    },
  );
}
