import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/features/question_game/question_game_store.dart';
import 'package:untitled/features/word_game/word_game_store.dart';
import 'package:untitled/models/content.dart';
import 'package:untitled/models/game_setup.dart';
import '../../data/fixtures.dart';
import '../word_game/word_game_store_test.dart' show BoundaryRandom;

void main() {
  late ContentRepository content;
  late SetupStore setup;
  late MemoryStorage file;

  setUp(() async {
    final data = fixture();
    data['categories'].add(category('q-adult', type: 'question'));
    final adult = question('adult', 'q-adult')..['is_family_friendly'] = false;
    data['questions'].add(adult);
    file = MemoryStorage();
    content = ContentRepository(
      fetchPage: (t, l, f, e) => fixturePage(data, t, l, f, e),
      cache: MemoryStorage(),
    );
    setup = SetupStore(content: content, file: file);
    await content.load();
    await setup.restore();
    setup.setGameType('question');
  });
  tearDown(() {
    setup.dispose();
    content.dispose();
  });

  QuestionGameSession session({Random? random}) =>
      QuestionGameSession.create(setup, random: random ?? Random(3))!;
  QuestionGameStore game() {
    final store = QuestionGameStore(session());
    addTearDown(store.dispose);
    return store;
  }

  test(
    'type persistence, category counts/filtering and old settings',
    () async {
      expect(
        content
            .categoryCounts(family: false, gameType: 'question')
            .values
            .fold(0, (a, b) => a + b),
        2,
      );
      expect(
        content
            .categoryCounts(family: true, gameType: 'question')
            .keys
            .single
            .id,
        'q',
      );
      setup.setCategories({'q-adult'});
      expect(session().prompt.id, 'adult');
      setup.setFamily(true);
      expect(setup.setup.value.categoryIds, isEmpty);
      expect(setup.selectionRemoved.value, true);
      expect(session().prompt.id, '4');
      expect(
        content.eligibleQuestions(family: false, categoryIds: {'a'}),
        isEmpty,
      );
      await setup.save();
      expect(GameSetup.fromJson(file.data!).gameType, 'question');
      expect(
        GameSetup.fromJson(
          GameSetup.defaults().toJson()..remove('gameType'),
        ).gameType,
        'word',
      );
      expect(
        () => GameSetup.fromJson({...file.data!, 'gameType': 'other'}),
        throwsFormatException,
      );
      expect(WordGameSession.create(setup), null);
      setup.setRules(showCategory: true, knowEachOther: true);
      setup.setGameType('word');
      expect(setup.setup.value.showCategory, true);
      expect(setup.setup.value.knowEachOther, true);
      expect(QuestionGameSession.create(setup), null);
      setup.setCategories({'a'});
      setup.setGameType('question');
      expect(setup.setup.value.categoryIds, isEmpty);
    },
  );

  test('fixed/random boundaries, duplicate names, exclusion and snapshot', () {
    for (final count in [3, 5, 100]) {
      setup.setPlayerCount(count);
      setup.setRoster(
        setup.setup.value.players.reversed
            .map((p) => SetupPlayer(p.id, 'Same'))
            .toList(),
        setup.setup.value.nextPlayerId,
      );
      setup.setRules(
        imposters: (count - 1) ~/ 2,
        imposterNotFirst: true,
        randomImposters: false,
      );
      final first = session();
      final again = session();
      expect(first.imposterIds, again.imposterIds);
      expect(first.startingPlayerId, again.startingPlayerId);
      expect(first.imposterIds, hasLength((count - 1) ~/ 2));
      expect(first.imposterIds, isNot(contains(first.startingPlayerId)));
      setup.setRules(randomImposters: true);
      for (final upper in [false, true]) {
        expect(
          session(random: BoundaryRandom(upper)).imposterIds,
          hasLength(upper ? (count - 1) ~/ 2 : 1),
        );
      }
      setup.setPlayerCount(4);
      content.snapshot.value = ContentSnapshot.fromJson(fixture(), 'vi');
      expect(first.setup.players.length, count);
      expect(first.contentLocale, 'vi');
      expect(() => first.imposterIds.clear(), throwsUnsupportedError);
      expect(() => first.setup.players.clear(), throwsUnsupportedError);
      expect(() => first.setup.categoryIds.add('x'), throwsUnsupportedError);
    }
  });

  test('private drafts, role questions, trim, duplicate submit and guards', () {
    final store = game();
    store.startDiscussion();
    store.revealResult();
    expect(store.stage.value, QuestionGameStage.players);
    store.selectPlayer('missing');
    expect(store.currentPlayerId.value, null);
    final a = store.session.setup.players.first.id;
    final b = store.session.setup.players.last.id;
    store.selectPlayer(a);
    store.updateDraft('hidden');
    expect(store.draft, '');
    expect(store.submit(), false);
    store.reveal();
    expect(
      store.question,
      store.session.imposterIds.contains(a)
          ? store.session.prompt.imposterQuestion
          : store.session.prompt.civilianQuestion,
    );
    store.updateDraft('  ');
    expect(store.submit(), false);
    store.updateDraft('  private A  ');
    store.conceal();
    expect(store.submit(), false);
    store.leaveCard();
    store.selectPlayer(b);
    expect(store.draft, '');
    store.reveal();
    store.updateDraft('private B');
    store.leaveCard();
    store.selectPlayer(a);
    expect(store.draft, '  private A  ');
    store.reveal();
    expect(store.submit(), true);
    expect(store.submit(), false);
    expect(store.answers.value, {a: 'private A'});
    expect(() => store.answers.value.clear(), throwsUnsupportedError);
    store.selectPlayer(a);
    expect(store.currentPlayerId.value, null);
    for (final p in store.session.setup.players.skip(1)) {
      store.selectPlayer(p.id);
      store.reveal();
      store.updateDraft(p.id);
      store.submit();
    }
    expect(store.stage.value, QuestionGameStage.commonQuestion);
    store.revealResult();
    expect(store.stage.value, QuestionGameStage.commonQuestion);
    store.startDiscussion();
    store.revealResult();
    expect(store.stage.value, QuestionGameStage.result);
    expect(game().answers.value, isEmpty);
    expect(game().draft, '');
  });

  test('unavailable content and unreadable setup prevent start', () async {
    content.snapshot.value = ContentSnapshot.fromJson({
      'categories': [],
      'words': [],
      'questions': [],
    }, 'vi');
    expect(QuestionGameSession.create(setup), null);
    content.snapshot.value = ContentSnapshot.fromJson(fixture(), 'vi');
    file.failRead = true;
    await setup.restore();
    expect(QuestionGameSession.create(setup), null);
  });
}
