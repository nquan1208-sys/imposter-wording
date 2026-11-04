import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/features/question_game/question_game_store.dart';
import 'package:untitled/models/content.dart';
import 'package:untitled/models/custom_question_category.dart';
import 'package:untitled/models/game_setup.dart';
import '../../data/fixtures.dart';

void main() {
  late ContentRepository content;
  late SetupStore store;
  late MemoryStorage file;
  List<CustomQuestionEntry> pair([
    String a = 'Civilian?',
    String b = 'Imposter?',
  ]) => [CustomQuestionEntry(a, b)];
  setUp(() async {
    content = ContentRepository(
      cache: MemoryStorage(),
      fetchPage: (t, l, f, e) => fixturePage(fixture(), t, l, f, e),
    );
    file = MemoryStorage();
    store = SetupStore(content: content, file: file);
    await content.load();
    await store.restore();
    await store.setGameType('question');
  });
  tearDown(() {
    store.dispose();
    content.dispose();
  });

  test(
    'Family excludes custom questions, prunes selections and blocks empty sessions',
    () async {
      final id = await store.createCustomQuestionCategory('Mine', pair());
      await store.setCategories({id!});
      expect(QuestionGameSession.create(store)!.prompt.categoryId, id);
      file.failWrite = true;
      expect(await store.setCategories({}, family: true), false);
      expect(store.setup.value.family, false);
      expect(store.setup.value.categoryIds, {id});
      file.failWrite = false;
      await store.save();
      expect(store.setup.value.family, false);
      expect(await store.setCategories({}, family: true), true);
      expect(store.eligibleQuestions(family: true), isEmpty);
      expect(store.eligibleQuestions(family: true, categoryIds: {id}), isEmpty);
      expect(store.categoryCounts(family: true, gameType: 'question'), isEmpty);
      expect(QuestionGameSession.create(store), isNull);
      await store.setCategories({id});
      expect(store.setup.value.categoryIds, isEmpty);
      expect(store.setup.value.customQuestionCategories.single.id, id);
      await store.restore();
      expect(store.setup.value.family, true);
      expect(QuestionGameSession.create(store), isNull);
      await store.setFamily(false);
      expect(store.eligibleQuestions(family: false), hasLength(2));
    },
  );

  test(
    'single pairs trim, differ ignoring case, and allow shared counterparts',
    () {
      final entries = parseQuestionPairs('  A  ', 'B');
      expect(entries.single.civilianQuestion, 'A');
      for (final values in [('', 'B'), ('A', ' '), (' A ', 'a')]) {
        expect(
          () => parseQuestionPairs(values.$1, values.$2),
          throwsA(isA<QuestionImportException>()),
        );
      }
      expect(parseQuestionPairs('a', 'C', existing: entries).length, 1);
      expect(parseQuestionPairs('B', 'A', existing: entries).length, 1);
      expect(
        () => parseQuestionPairs('a', ' b ', existing: entries),
        throwsA(isA<QuestionImportException>()),
      );
    },
  );

  test('bulk preserves blank rows and rejects all invalid rows atomically', () {
    expect(parseQuestionPairs(' A\r\nC\r\n', 'B\nD\n', batch: true).length, 2);
    for (final values in [
      ('A\n\nC', 'B\nD\nE', [2]),
      ('A\nC', 'B', [2]),
      ('A\n a ', 'B\n b ', [1, 2]),
      ('A\nC', 'a\nD', [1]),
      ('A\n\n', 'B\n\n', [2]),
    ]) {
      expect(
        () => parseQuestionPairs(values.$1, values.$2, batch: true),
        throwsA(
          isA<QuestionImportException>().having(
            (e) => e.rows,
            'rows',
            values.$3,
          ),
        ),
      );
    }
  });

  test('bulk duplicates against the draft identify every affected row', () {
    expect(
      () => parseQuestionPairs(
        'a\nC\nA',
        'b\nD\nB',
        batch: true,
        existing: pair('A', 'B'),
      ),
      throwsA(
        isA<QuestionImportException>().having((e) => e.rows, 'rows', [1, 3]),
      ),
    );
  });

  test(
    'local allocation skips remote category and prompt ID collisions',
    () async {
      content.snapshot.value = ContentSnapshot.fromJson({
        'categories': [
          category('custom-question-1', type: 'question'),
          category('q', type: 'question'),
        ],
        'words': [],
        'questions': [question('custom-question-2-pair-0', 'q')],
      }, 'vi');
      await store.pendingWrites;
      expect(
        await store.createCustomQuestionCategory('Local', pair()),
        'custom-question-3',
      );
      expect(store.setup.value.nextCustomQuestionCategoryId, 4);
      expect(
        store.eligibleQuestions(family: false).map((q) => q.id).toSet().length,
        2,
      );
    },
  );

  test('legacy, serialization, immutable lists and invalid counters', () {
    final old = GameSetup.defaults().toJson()
      ..remove('customQuestionCategories')
      ..remove('nextCustomQuestionCategoryId');
    expect(GameSetup.fromJson(old).nextCustomQuestionCategoryId, 1);
    expect(GameSetup.fromJson(old).customQuestionCategories, isEmpty);
    final category = CustomQuestionCategory(
      id: 'custom-question-1',
      name: 'Local',
      contentLocale: 'vi',
      pairs: pair(),
    );
    expect(
      CustomQuestionCategory.fromJson(category.toJson()).toJson(),
      category.toJson(),
    );
    expect(() => category.pairs.clear(), throwsUnsupportedError);
    expect(
      () => GameSetup.fromJson({
        ...old,
        'customQuestionCategories': [category.toJson()],
      }),
      throwsFormatException,
    );
    expect(
      () => CustomQuestionCategory(
        id: 'custom-question-1',
        name: 'Local',
        contentLocale: 'vi',
        pairs: [...pair(), ...pair()],
      ),
      throwsFormatException,
    );
  });

  test(
    'failed save retains counter; queued names recheck; IDs advance only on commit',
    () async {
      file.failWrite = true;
      expect(await store.createCustomQuestionCategory('Local', pair()), isNull);
      expect(store.setup.value.nextCustomQuestionCategoryId, 1);
      file.failWrite = false;
      expect(
        await Future.wait([
          store.createCustomQuestionCategory('Local', pair()),
          store.createCustomQuestionCategory(' local ', pair()),
          store.createCustomQuestionCategory('Other', pair()),
        ]),
        ['custom-question-1', null, 'custom-question-2'],
      );
      expect(GameSetup.fromJson(file.data!).customQuestionCategories.length, 2);
      final remote = content.snapshot.value!.categories.firstWhere(
        (c) => c.gameType == 'question',
      );
      expect(
        await store.createCustomQuestionCategory(remote.name, pair()),
        isNull,
      );
      final word = content.snapshot.value!.categories.firstWhere(
        (c) => c.gameType == 'word',
      );
      expect(
        await store.createCustomQuestionCategory(word.name, pair()),
        isNotNull,
      );
    },
  );

  test(
    'combined eligibility and session snapshots survive refresh and offline restart',
    () async {
      final id = (await store.createCustomQuestionCategory('Local', pair()))!;
      expect(
        store
            .categoryCounts(family: false, gameType: 'question')
            .values
            .fold(0, (a, b) => a + b),
        store.eligibleQuestions(family: false).length,
      );
      await store.setCategories({id});
      final session = QuestionGameSession.create(store, random: Random(1))!;
      expect(session.categoryName, 'Local');
      content.snapshot.value = ContentSnapshot.fromJson({
        'categories': [],
        'words': [],
        'questions': [],
      }, 'vi');
      await store.pendingWrites;
      expect(store.setup.value.categoryIds, {id});
      content.snapshot.value = ContentSnapshot.fromJson({
        'categories': [],
        'words': [],
        'questions': [],
      }, 'vi');
      await store.restore();
      expect(
        QuestionGameSession.create(store)!.prompt.civilianQuestion,
        'Civilian?',
      );
      expect(session.prompt.imposterQuestion, 'Imposter?');
      await store.setGameType('word');
      expect(store.setup.value.categoryIds, isEmpty);
      expect(store.setup.value.customQuestionCategories.length, 1);
      expect(
        store.categoryCounts(family: false).keys.any((c) => c.id == id),
        false,
      );
      await store.setGameType('question');
      expect(store.eligibleQuestions(family: false).length, 1);
    },
  );

  test(
    'locale isolation and presets preserve both types; clear is atomic',
    () async {
      await store.setGameType('word');
      await store.createCustomWordCategory('Shared', ['word'], family: false);
      await store.setGameType('question');
      final id = (await store.createCustomQuestionCategory('Shared', pair()))!;
      final presetId = await store.createPreset('Group', store.setup.value);
      final preset = store.setup.value.presets.single;
      expect(preset.setup.customQuestionCategories, isEmpty);
      expect(preset.toJson().containsKey('customQuestionCategories'), false);
      await store.confirmDraft(preset.setup, presetId);
      await store.setCategories({id});
      file.data = {
        ...file.data!,
        'customQuestionCategories': [
          ...store.setup.value.customQuestionCategories.map((c) => c.toJson()),
          CustomQuestionCategory(
            id: 'custom-question-2',
            name: 'English',
            contentLocale: 'en',
            pairs: pair(),
          ).toJson(),
        ],
        'nextCustomQuestionCategoryId': 3,
      };
      await store.restore();
      expect(
        store
            .eligibleQuestions(family: false)
            .where((q) => q.contentLocale == 'en'),
        isEmpty,
      );
      expect(
        store.validCustomCategoryName('English', gameType: 'question'),
        true,
      );
      file.failWrite = true;
      expect(await store.clearCustomCategories(), false);
      expect(store.setup.value.hasCustomContent, true);
      expect(store.setup.value.categoryIds, {id});
      file.failWrite = false;
      expect(await store.clearCustomCategories(), true);
      expect(store.setup.value.hasCustomContent, false);
      expect(store.setup.value.categoryIds, isEmpty);
      expect(GameSetup.fromJson(file.data!).hasCustomContent, false);
    },
  );
}
