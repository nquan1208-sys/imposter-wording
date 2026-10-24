import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/features/word_game/word_game_store.dart';
import 'package:untitled/models/content.dart';
import '../../data/fixtures.dart';

void main() {
  late ContentRepository content;
  late SetupStore setup;
  setUp(() async {
    content = ContentRepository(
      fetchPage: (t, l, f, e) => fixturePage(fixture(), t, l, f, e),
      cache: MemoryFile(),
    );
    setup = SetupStore(content: content, file: MemoryFile());
    await content.load();
    await setup.restore();
  });
  tearDown(() {
    setup.dispose();
    content.dispose();
  });
  WordGameSession session() =>
      WordGameSession.create(setup, random: Random(7))!;
  WordGameStore game() {
    final store = WordGameStore(session());
    addTearDown(store.dispose);
    return store;
  }

  void finish(WordGameStore store) {
    for (final p in store.session.setup.players) {
      store.selectPlayer(p.id);
      store.reveal();
      store.completePlayer();
    }
  }

  test('bounds, seeded selection and frozen setup/content', () {
    for (final count in [3, 100]) {
      setup.setPlayerCount(count);
      setup.setFamily(true);
      final first = session();
      final second = session();
      expect(first.prompt.id, '2');
      expect(first.imposterId, second.imposterId);
      expect(first.startingPlayerId, second.startingPlayerId);
      expect(
        first.setup.players.where((p) => p.id == first.imposterId),
        hasLength(1),
      );
      expect(
        first.setup.players.any((p) => p.id == first.startingPlayerId),
        true,
      );
      setup.setPlayerCount(4);
      content.snapshot.value = ContentSnapshot.fromJson(fixture(), 'vi');
      expect(first.setup.players, hasLength(count));
      expect(first.prompt.text, 'Word 2');
      expect(first.categoryName, 'Category a');
      expect(first.contentLocale, 'vi');
      expect(() => first.setup.players.clear(), throwsUnsupportedError);
      expect(() => first.setup.categoryIds.add('b'), throwsUnsupportedError);
    }
  });

  test('category filter, empty content and unreadable settings', () async {
    setup.setCategories({'b'});
    expect(session().prompt.id, '3');
    content.snapshot.value = ContentSnapshot.fromJson({
      'categories': [],
      'words': [],
      'questions': [],
    }, 'vi');
    expect(WordGameSession.create(setup), null);
    content.snapshot.value = ContentSnapshot.fromJson(fixture(), 'vi');
    (setup.file as MemoryFile).failRead = true;
    await setup.restore();
    expect(WordGameSession.create(setup), null);
  });

  test(
    'guards early vote, hidden completion, duplicate taps and completed cards',
    () {
      final store = game();
      final p = store.session.setup.players.first;
      store.confirmVote(p.id);
      expect(store.stage.value, WordGameStage.players);
      store.selectPlayer('missing');
      expect(store.currentPlayerId.value, null);
      store.selectPlayer(p.id);
      store.completePlayer();
      expect(store.completed.value, isEmpty);
      store.selectPlayer(store.session.setup.players.last.id);
      expect(store.currentPlayerId.value, p.id);
      store.reveal();
      store.conceal();
      store.completePlayer();
      expect(store.completed.value, isEmpty);
      store.reveal();
      store.completePlayer();
      store.completePlayer();
      store.selectPlayer(p.id);
      expect(store.currentPlayerId.value, null);
      expect(store.completed.value, {p.id});
      expect(store.stage.value, WordGameStage.players);
    },
  );

  test('card back is safe; votes determine winner once; new game resets', () {
    final store = game();
    store.selectPlayer(store.session.imposterId);
    store.reveal();
    store.leaveCard();
    expect(store.revealed.value, false);
    expect(store.completed.value, isEmpty);
    finish(store);
    expect(store.stage.value, WordGameStage.discussion);
    store.confirmVote('missing');
    expect(store.stage.value, WordGameStage.discussion);
    store.confirmVote(store.session.imposterId);
    expect(store.groupWon, true);
    final civilian = store.session.setup.players.firstWhere(
      (p) => p.id != store.session.imposterId,
    );
    store.confirmVote(civilian.id);
    expect(store.groupWon, true);
    final next = game();
    expect(next.completed.value, isEmpty);
    expect(next.votedPlayerId.value, null);
    expect(next.revealed.value, false);
    finish(next);
    next.confirmVote(civilian.id);
    expect(next.groupWon, false);
    expect(next.stage.value, WordGameStage.result);
  });
}
