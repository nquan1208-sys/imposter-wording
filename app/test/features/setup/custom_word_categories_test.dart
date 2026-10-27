import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/features/word_game/word_game_store.dart';
import 'package:untitled/models/content.dart';
import 'package:untitled/models/custom_word_category.dart';
import 'package:untitled/models/game_setup.dart';
import '../../data/fixtures.dart';

class LastRandom implements Random {
  int? firstBound;
  @override
  int nextInt(int max) {
    firstBound ??= max;
    return max - 1;
  }

  @override
  bool nextBool() => true;
  @override
  double nextDouble() => 0.9;
}

void main() {
  late ContentRepository content;
  late SetupStore store;
  late MemoryStorage file;
  setUp(() async {
    content = ContentRepository(
      cache: MemoryStorage(),
      fetchPage: (t, l, f, e) => fixturePage(fixture(), t, l, f, e),
    );
    file = MemoryStorage();
    store = SetupStore(content: content, file: file);
    await content.load();
    await store.restore();
  });
  tearDown(() {
    store.dispose();
    content.dispose();
  });

  test(
    'batch trims, skips blanks and keeps the first case-preserving word',
    () {
      expect(uniqueWords(['  Táo ', '', 'TÁO', ' Bánh mì ', '  ', 'bánh mì']), [
        'Táo',
        'Bánh mì',
      ]);
    },
  );

  test('legacy setup defaults to no custom content; invalid records fail', () {
    final old = GameSetup.defaults().toJson()
      ..remove('customWordCategories')
      ..remove('nextCustomWordCategoryId');
    expect(GameSetup.fromJson(old).customWordCategories, isEmpty);
    expect(
      () => CustomWordCategory(
        id: 'a',
        name: 'Name',
        contentLocale: 'vi',
        isFamilyFriendly: false,
        words: ['word'],
      ),
      throwsFormatException,
    );
    expect(
      () => CustomWordCategory(
        id: 'custom-word-1',
        name: 'Name',
        contentLocale: 'vi',
        isFamilyFriendly: false,
        words: ['word', 'WORD'],
      ),
      throwsFormatException,
    );
  });

  test(
    'save validates names across remote and local categories, and empty words',
    () async {
      expect(
        await store.createCustomWordCategory(' category B ', [
          'x',
        ], family: true),
        isNull,
      );
      expect(
        await store.createCustomWordCategory(' ', ['x'], family: false),
        isNull,
      );
      expect(
        await store.createCustomWordCategory('Office', [' '], family: false),
        isNull,
      );
      final id = await store.createCustomWordCategory(' Office ', [
        ' A ',
        'a',
        '',
        'B',
      ], family: false);
      expect(id, 'custom-word-1');
      expect(
        await store.createCustomWordCategory('OFFICE', ['x'], family: true),
        isNull,
      );
      expect(store.setup.value.customWordCategories.single.words, ['A', 'B']);
      expect(store.setup.value.customWordCategories.single.name, 'Office');
      expect(
        store.setup.value.categoryIds,
        isEmpty,
        reason: 'picker selection is a separate draft',
      );
    },
  );

  test(
    'failed and concurrent saves do not publish partial categories or reuse IDs',
    () async {
      file.failWrite = true;
      expect(
        await store.createCustomWordCategory('One', ['x'], family: false),
        isNull,
      );
      expect(store.setup.value.customWordCategories, isEmpty);
      expect(store.setup.value.nextCustomWordCategoryId, 1);
      file.failWrite = false;
      final ids = await Future.wait([
        store.createCustomWordCategory('One', ['x'], family: false),
        store.createCustomWordCategory('Two', ['y'], family: true),
      ]);
      expect(ids, ['custom-word-1', 'custom-word-2']);
      expect(
        store.eligibleWords(family: false).map((w) => w.id).toSet().length,
        5,
      );
      expect(GameSetup.fromJson(file.data!).customWordCategories.length, 2);
    },
  );

  test(
    'family, game and locale filters share counts and eligible words',
    () async {
      final regular = await store.createCustomWordCategory('Office', [
        'x',
        'y',
      ], family: false);
      final family = await store.createCustomWordCategory('Family', [
        'z',
      ], family: true);
      expect(
        store.categoryCounts(family: false).values.fold(0, (a, b) => a + b),
        6,
      );
      expect(
        store.categoryCounts(family: true).values.fold(0, (a, b) => a + b),
        3,
      );
      expect(
        store.eligibleWords(family: true, categoryIds: {regular!}),
        isEmpty,
      );
      expect(
        store.eligibleWords(family: true, categoryIds: {family!}).single.text,
        'z',
      );
      expect(
        store
            .categoryCounts(family: false, gameType: 'question')
            .keys
            .map((c) => c.id),
        ['q'],
      );
      final en = CustomWordCategory(
        id: 'custom-word-3',
        name: 'English',
        contentLocale: 'en',
        isFamilyFriendly: true,
        words: ['English'],
      );
      file.data = {
        ...file.data!,
        'customWordCategories': [
          ...store.setup.value.customWordCategories.map((c) => c.toJson()),
          en.toJson(),
        ],
        'nextCustomWordCategoryId': 4,
      };
      await store.restore();
      expect(store.categories.any((c) => c.id == en.id), false);
      expect(
        store.eligibleWords(family: false).any((w) => w.text == 'English'),
        false,
      );
    },
  );

  test(
    'combined pool is sampled per prompt and category name is captured',
    () async {
      await store.createCustomWordCategory('Office', [
        'Alpha',
        'Beta',
      ], family: false);
      final random = LastRandom();
      final session = WordGameSession.create(store, random: random)!;
      expect(random.firstBound, 5);
      expect(session.prompt.text, 'Beta');
      expect(session.categoryName, 'Office');
      expect(session.prompt.imagePath, isNull);
      expect(session.contentLocale, 'vi');
      content.snapshot.value = ContentSnapshot.fromJson({
        'categories': [],
        'words': [],
        'questions': [],
      }, 'vi');
      await store.pendingWrites;
      expect(session.prompt.text, 'Beta');
      expect(store.eligibleWords(family: false).length, 2);
    },
  );

  test(
    'custom-only offline setup plays, restores and survives game switching',
    () async {
      final id = (await store.createCustomWordCategory('Solo', [
        'Only word',
      ], family: true))!;
      await store.setCategories({id}, family: true);
      content.snapshot.value = null;
      await store.restore();
      expect(store.setup.value.categoryIds, {id});
      expect(WordGameSession.create(store)!.prompt.text, 'Only word');
      await store.setGameType('question');
      expect(store.setup.value.categoryIds, isEmpty);
      expect(store.setup.value.customWordCategories.length, 1);
      await store.setGameType('word');
      expect(store.eligibleWords(family: false).length, 1);
      expect(
        (await store.createCustomWordCategory('Next', ['next'], family: false)),
        'custom-word-2',
      );
    },
  );

  test(
    'refresh validates remote selections without removing custom selection',
    () async {
      final id = (await store.createCustomWordCategory('Office', [
        'x',
      ], family: false))!;
      await store.setCategories({'a', id});
      content.snapshot.value = ContentSnapshot.fromJson({
        'categories': [],
        'words': [],
        'questions': [],
      }, 'vi');
      await store.pendingWrites;
      expect(store.setup.value.categoryIds, {id});
      expect(store.selectionRemoved.value, true);
      await store.setFamily(true);
      expect(store.setup.value.categoryIds, isEmpty);
      expect(store.setup.value.customWordCategories.length, 1);
    },
  );

  test(
    'presets exclude custom content and applying roster preserves it',
    () async {
      final id = await store.createCustomWordCategory('Office', [
        'x',
      ], family: false);
      final presetId = await store.createPreset('Group', store.setup.value);
      final preset = store.setup.value.presets.single;
      expect(preset.setup.customWordCategories, isEmpty);
      expect(preset.toJson().containsKey('customWordCategories'), false);
      await store.confirmDraft(preset.setup, presetId);
      expect(store.setup.value.customWordCategories.single.id, id);
    },
  );

  test(
    'cleanup commits only after success and preserves settings and remote IDs',
    () async {
      final id = (await store.createCustomWordCategory('Office', [
        'x',
      ], family: false))!;
      await store.setCategories({'a', id});
      await store.setPlayerCount(5);
      file.failWrite = true;
      expect(await store.clearCustomWordCategories(), false);
      expect(store.setup.value.categoryIds, {'a', id});
      expect(store.setup.value.customWordCategories.length, 1);
      file.failWrite = false;
      expect(await store.clearCustomWordCategories(), true);
      expect(store.setup.value.categoryIds, {'a'});
      expect(store.setup.value.customWordCategories, isEmpty);
      expect(store.setup.value.players.length, 5);
      expect(GameSetup.fromJson(file.data!).customWordCategories, isEmpty);
      expect(
        await store.createCustomWordCategory('Next', ['x'], family: false),
        'custom-word-2',
      );
    },
  );
}
