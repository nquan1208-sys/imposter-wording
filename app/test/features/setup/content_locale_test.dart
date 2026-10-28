import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/features/word_game/word_game_store.dart';
import 'package:untitled/features/question_game/question_game_store.dart';
import 'package:untitled/models/content.dart';
import 'package:untitled/models/custom_question_category.dart';
import 'package:untitled/models/game_setup.dart';
import '../../data/fixtures.dart';

void main() {
  test('legacy defaults, roundtrip and presets exclude content locale', () {
    final old = GameSetup.defaults().toJson()..remove('contentLocale');
    expect(GameSetup.fromJson(old).contentLocale, 'vi');
    final japanese = GameSetup.fromJson(old).copyWith(contentLocale: 'ja');
    expect(GameSetup.fromJson(japanese.toJson()).contentLocale, 'ja');
    expect(japanese.withRoster(GameSetup.defaults()).contentLocale, 'ja');
    expect(
      PlayerPreset('preset-1', 'Group', japanese).toJson(),
      isNot(contains('contentLocale')),
    );
    for (final invalid in ['', ' en', 1]) {
      expect(
        () => GameSetup.fromJson({...old, 'contentLocale': invalid}),
        throwsFormatException,
      );
    }
  });

  late SetupStore store;
  late MemoryStorage file;
  late Map<String, ContentRepository> repositories;
  late Map<String, MemoryStorage> caches;
  late Map<String, Completer<void>> gates;
  late Map<String, JsonMap> data;
  late bool offline;

  setUp(() async {
    offline = false;
    caches = {};
    gates = {};
    data = {
      for (final locale in ['vi', 'en', 'ja']) locale: localizedFixture(locale),
    };
    repositories = {};
    ContentRepository resolve(String locale) =>
        repositories.putIfAbsent(locale, () {
          final repo = ContentRepository(
            contentLocale: locale,
            cache: caches.putIfAbsent(locale, MemoryStorage.new),
            pageSize: 2,
            fetchPage: (table, locale, from, to) async {
              if (offline) throw StateError('offline');
              await gates[locale]?.future;
              return fixturePage(data[locale]!, table, locale, from, to);
            },
          );
          repo.load();
          return repo;
        });
    final languages = fixtureLanguages();
    await languages.load();
    file = MemoryStorage();
    store = SetupStore(
      content: resolve('vi'),
      file: file,
      repositoryForLocale: resolve,
      languages: languages,
    );
    await store.content.load();
    await store.restore();
    addTearDown(() {
      store.dispose();
      languages.dispose();
      for (final repository in repositories.values) {
        repository.dispose();
      }
    });
  });

  test(
    'write failure preserves complete setup and repository; retry commits locale',
    () async {
      await store.setPlayerCount(6);
      final custom = await store.createCustomWordCategory('Mine', [
        'Local',
      ], family: false);
      final preset = await store.createPreset('Group', store.setup.value);
      final previous = store.setup.value.toJson();
      file.failWrite = true;
      expect(await store.setContentLocale('en'), false);
      expect(store.setup.value.toJson(), previous);
      expect(store.content.contentLocale, 'vi');
      expect(repositories.keys, ['vi']);
      file.failWrite = false;
      expect(await store.save(), true);
      await store.content.load();
      await store.pendingWrites;
      expect(store.setup.value.contentLocale, 'en');
      expect(store.setup.value.players, hasLength(6));
      expect(store.setup.value.customWordCategories.single.id, custom);
      expect(
        await store.confirmDraft(
          store.setup.value.presets.single.setup,
          preset,
        ),
        true,
      );
      expect(store.setup.value.contentLocale, 'en');
      await store.restore();
      expect(store.setup.value.contentLocale, 'en');
    },
  );

  test(
    'VI EN VI late response cannot replace active snapshot or selections',
    () async {
      await store.setCategories({'a', 'b'});
      gates['en'] = Completer<void>();
      expect(await store.setContentLocale('en'), true);
      expect(store.contentReady, false);
      expect(WordGameSession.create(store), isNull);
      expect(await store.setCategories({'a'}), false);
      expect(await store.setContentLocale('vi'), true);
      await store.pendingWrites;
      expect(store.setup.value.categoryIds, {'a', 'b'});
      gates['en']!.complete();
      await repositories['en']!.load();
      await store.pendingWrites;
      expect(store.content.contentLocale, 'vi');
      expect(store.categories.first.name, 'vi a');
      expect(store.setup.value.categoryIds, {'a', 'b'});
      expect(caches['en']!.data!['words'][0]['t'][0]['locale'], 'en');
      expect(caches['vi']!.data!['words'][0]['t'][0]['locale'], 'vi');
    },
  );

  test(
    'new snapshot keeps shared IDs, updates names and removes invalid IDs',
    () async {
      await store.setCategories({'a', 'b'});
      data['en']!['categories'] = [category('a', locale: 'en', family: true)];
      data['en']!['words'] = [word('1', 'a', locale: 'en')];
      data['en']!['questions'] = [];
      await store.setContentLocale('en');
      await store.content.load();
      await store.pendingWrites;
      expect(store.setup.value.categoryIds, {'a'});
      expect(store.selectionRemoved.value, true);
      expect(WordGameSession.create(store)!.categoryName, 'Category a');
      expect(await store.setContentLocale('ja'), false);
      data['en'] = {'categories': [], 'words': [], 'questions': []};
      await store.content.load();
      await store.pendingWrites;
      expect(store.setup.value.categoryIds, isEmpty);
      expect(store.contentReady, true);
      expect(WordGameSession.create(store), isNull);
    },
  );

  test(
    'custom draft locale, both games and modes, immutable sessions and offline restore',
    () async {
      const image = '0123456789abcdef0123456789abcdef.img';
      await store.setContentLocale('en');
      await store.content.load();
      await store.pendingWrites;
      final id = await store.createCustomWordCategory(
        'VI draft',
        ['Local VI'],
        contentLocale: 'vi',
        family: true,
        imageIds: {'Local VI': image},
      );
      expect(
        store.eligibleWords(family: false).any((w) => w.categoryId == id),
        false,
      );
      for (final family in [false, true]) {
        await store.setFamily(family);
        final session = WordGameSession.create(store)!;
        expect(session.contentLocale, 'en');
        expect(session.categoryName, startsWith('en '));
      }
      await store.setGameType('question');
      await store.createCustomQuestionCategory('VI draft question', [
        CustomQuestionEntry('A', 'B'),
      ], contentLocale: 'vi');
      final session = QuestionGameSession.create(store)!;
      expect(session.contentLocale, 'en');
      store.sessionActive.value = true;
      expect(await store.setContentLocale('vi'), false);
      store.sessionActive.value = false;
      await store.setContentLocale('vi');
      await store.content.load();
      await store.pendingWrites;
      expect(QuestionGameSession.create(store)!.contentLocale, 'vi');
      expect(session.contentLocale, 'en');
      expect(session.categoryName, 'en q');
      offline = true;
      final offlineRepo = ContentRepository(
        contentLocale: 'vi',
        cache: caches['vi']!,
        fetchPage: (_, _, _, _) async => throw StateError('offline'),
      );
      final restored = SetupStore(
        content: offlineRepo,
        file: file,
        languages: store.languages,
      );
      addTearDown(() {
        restored.dispose();
        offlineRepo.dispose();
      });
      await offlineRepo.load();
      await restored.restore();
      expect(QuestionGameSession.create(restored)!.contentLocale, 'vi');
      expect(restored.setup.value.localImageIds, {image});
      await store.setContentLocale('vi');
      await store.pendingWrites;
      await store.setGameType('word');
      expect(
        store.eligibleWords(family: false).any((w) => w.categoryId == id),
        true,
      );
    },
  );

  test(
    'successful list removal blocks play and preserves saved locale; cached list works',
    () async {
      expect(WordGameSession.create(store), isNotNull);
      store.languages!.languages.value = [];
      expect(store.localeAvailable, false);
      expect(WordGameSession.create(store), isNull);
      expect(store.setup.value.contentLocale, 'vi');
      await store.languages!.load();
      expect(store.localeAvailable, true);
    },
  );
}
