import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/models/content.dart';
import 'package:untitled/models/game_setup.dart';
import '../../data/fixtures.dart';

class SlowStorage extends MemoryStorage {
  final gate = Completer<void>();
  int active = 0, maxActive = 0;
  @override
  Future<void> write(JsonMap data) async {
    active++;
    if (active > maxActive) maxActive = active;
    await gate.future;
    await super.write(data);
    active--;
  }
}

void main() async {
  late ContentRepository content;
  late SetupStore store;
  late MemoryStorage file;
  test(
    'category confirmation commits one write; failed draft cannot be retried after cancel',
    () async {
      final before = file.writes;
      file.failWrite = true;
      expect(
        await store.setCategories({'a'}, family: true, showWordImages: true),
        false,
      );
      expect(store.setup.value.family, false);
      expect(store.setup.value.categoryIds, isEmpty);
      expect(store.setup.value.showWordImages, false);
      file.failWrite = false;
      await store.save();
      expect(store.setup.value.family, false);
      expect(
        file.writes,
        before + 1,
        reason: 'cancelled category draft is never queued for retry',
      );
      expect(
        await store.setCategories({'a'}, family: true, showWordImages: true),
        true,
      );
      expect(file.writes, before + 2);
      expect(store.setup.value.family, true);
      expect(store.setup.value.categoryIds, {'a'});
      expect(store.setup.value.showWordImages, true);
    },
  );

  test(
    'legacy question family setup restores in regular mode while remembering images',
    () async {
      file.data = {
        ...GameSetup.defaults().toJson(),
        'gameType': 'question',
        'mode': 'family',
        'showWordImages': true,
      };
      await store.restore();
      expect(store.setup.value.family, false);
      expect(store.setup.value.showWordImages, true);
      await store.setGameType('word');
      expect(store.setup.value.family, false);
    },
  );
  setUp(() async {
    final data = fixture();
    content = ContentRepository(
      cache: MemoryStorage(),
      fetchPage: (t, l, f, e) => fixturePage(data, t, l, f, e),
    );
    file = MemoryStorage();
    store = SetupStore(content: content, file: file);
    await content.load();
    await store.restore();
  });
  tearDown(() async {
    store.dispose();
    content.dispose();
  });

  test(
    'roster trims names, permits duplicates, retains IDs/order and clamps rules',
    () async {
      await store.setPlayerCount(7);
      await store.setRules(
        imposters: 3,
        randomImposters: true,
        imposterNotFirst: true,
        showCategory: true,
        knowEachOther: true,
      );
      final players = store.setup.value.players.reversed
          .take(3)
          .map((p) => SetupPlayer(p.id, '  Same  '))
          .toList();
      expect(
        await store.setRoster(players, store.setup.value.nextPlayerId),
        true,
      );
      expect(
        store.setup.value.players.map((p) => p.id),
        players.map((p) => p.id),
      );
      expect(
        store.setup.value.players.map((p) => p.name),
        everyElement('Same'),
      );
      expect(store.setup.value.imposters, 1);
      await store.save();
      final restored = GameSetup.fromJson(file.data!);
      expect(restored.toJson(), store.setup.value.toJson());
      expect(restored.randomImposters, true);
      expect(restored.imposterNotFirst, false);
      expect(restored.showCategory, true);
      expect(restored.knowEachOther, true);
    },
  );

  test(
    'rejects empty names, invalid IDs, invalid count and duplicate IDs',
    () async {
      final current = store.setup.value;
      for (final players in [
        current.players.take(2).toList(),
        [const SetupPlayer('player-1', '  '), ...current.players.skip(1)],
        [
          current.players.first,
          ...current.players.skip(1),
          current.players.first,
        ],
        [const SetupPlayer('wrong', 'Name'), ...current.players.skip(1)],
      ]) {
        expect(await store.setRoster(players, current.nextPlayerId), false);
        expect(store.setup.value, same(current));
      }
      await store.setRules(imposters: 0);
      await store.setRules(imposters: 2);
      expect(store.setup.value, same(current));
      await store.setPlayerCount(100);
      await store.setRules(imposters: 49);
      expect(store.setup.value.imposters, 49);
      await store.setRules(imposters: 50);
      expect(store.setup.value.imposters, 49);
      await store.setPlayerCount(3);
      expect(store.setup.value.imposters, 1);
    },
  );

  test(
    'legacy settings default new options; malformed rules preserve saved data',
    () async {
      final legacy = GameSetup.defaults().toJson()
        ..remove('randomImposters')
        ..remove('imposterNotFirst')
        ..remove('showCategory')
        ..remove('knowEachOther')
        ..remove('showWordImages');
      expect(GameSetup.fromJson(legacy).randomImposters, false);
      expect(GameSetup.fromJson(legacy).showCategory, false);
      expect(GameSetup.fromJson(legacy).showWordImages, false);
      legacy['imposters'] = 2;
      file.data = legacy;
      await store.restore();
      expect(store.readFailed.value, true);
      await store.save();
      expect(file.data, same(legacy));
    },
  );

  test('new default names use available numbers and unique IDs', () async {
    final current = store.setup.value;
    await store.setRoster(
      current.players.map((p) => SetupPlayer(p.id, 'Guest')).toList(),
      current.nextPlayerId,
    );
    await store.setPlayerCount(5);
    expect(store.setup.value.players.last.name, 'Player 1');
    expect(store.setup.value.players.last.id, 'player-5');
  });

  test(
    'defaults and player bounds retain IDs and never reuse removed IDs',
    () async {
      expect(store.setup.value.players.length, 4);
      final first = store.setup.value.players.first;
      await store.setPlayerCount(2);
      expect(store.setup.value.players.length, 4);
      await store.setPlayerCount(100);
      expect(store.setup.value.players.first, same(first));
      await store.setPlayerCount(101);
      expect(store.setup.value.players.length, 100);
      await store.setPlayerCount(3);
      await store.setPlayerCount(4);
      expect(store.setup.value.players.last.id, 'player-101');
      await store.save();
      expect(GameSetup.fromJson(file.data!).players.last.id, 'player-101');
    },
  );

  test(
    'mode change removes unavailable categories, falls back to all and persists',
    () async {
      await store.setCategories({'b'});
      await store.setFamily(true);
      expect(store.setup.value.categoryIds, isEmpty);
      expect(store.selectionRemoved.value, true);
      await store.save();
      expect(file.data!['mode'], 'family');
      expect(file.data!['categoryIds'], isEmpty);
    },
  );

  test('replacement prunes selections and keeps surviving IDs', () async {
    await store.setCategories({'a', 'b'});
    final data = fixture();
    (data['words'] as List).removeWhere((w) => w['category_id'] == 'b');
    content.snapshot.value = ContentSnapshot.fromJson(data, 'vi');
    await store.pendingWrites;
    expect(store.setup.value.categoryIds, {'a'});
    content.snapshot.value = ContentSnapshot.fromJson({
      'categories': [],
      'words': [],
      'questions': [],
    }, 'vi');
    await store.pendingWrites;
    expect(store.setup.value.categoryIds, isEmpty);
  });

  test(
    'read failure blocks writes, retry restores; read failures never overwrite',
    () async {
      file.data = GameSetup.defaults().copyWith(family: true).toJson();
      file.failRead = true;
      await store.restore();
      await store.setPlayerCount(10);
      await store.save();
      expect(file.writes, 0);
      expect(store.editable, false);
      file.failRead = false;
      await store.restore();
      expect(store.setup.value.family, true);
      file.failRead = true;
      await store.restore();
      await store.save();
      expect(file.data!['mode'], 'family');
    },
  );

  test('invalid settings survive unchanged until confirmed reset', () async {
    final malformed = {'players': []};
    file.data = malformed;
    await store.restore();
    expect(store.readFailed.value, true);
    expect(file.data, same(malformed));
    await store.save();
    expect(file.writes, 0);
  });

  test(
    'word images default off, persist globally, and retry failed writes',
    () async {
      expect(store.setup.value.showWordImages, false);
      file.failWrite = true;
      expect(await store.setShowWordImages(true), false);
      expect(store.setup.value.showWordImages, false);
      expect(store.writeFailed.value, true);
      file.failWrite = false;
      expect(await store.save(), true);
      expect(store.writeFailed.value, false);
      expect(store.setup.value.showWordImages, true);
      for (final family in [true, false]) {
        await store.setFamily(family);
        for (final type in ['question', 'word']) {
          await store.setGameType(type);
          expect(store.setup.value.showWordImages, true);
        }
      }
      await store.restore();
      expect(store.setup.value.showWordImages, true);
      expect(await store.setShowWordImages(false), true);
      await store.restore();
      expect(store.setup.value.showWordImages, false);
    },
  );

  test('write failure keeps visible setup and retry saves it', () async {
    file.failWrite = true;
    await store.setPlayerCount(8);
    await store.save();
    expect(store.writeFailed.value, true);
    expect(store.setup.value.players.length, 4);
    file.failWrite = false;
    await store.save();
    expect(store.writeFailed.value, false);
    final restarted = SetupStore(content: content, file: file);
    addTearDown(restarted.dispose);
    await restarted.restore();
    expect(restarted.setup.value.players.length, 8);
  });

  test('writes serialize and last committed setup wins', () async {
    final slow = SlowStorage();
    final other = SetupStore(content: content, file: slow);
    addTearDown(other.dispose);
    await other.restore();
    other.setPlayerCount(6);
    other.setPlayerCount(8);
    other.setFamily(true);
    final saved = other.save();
    await Future<void>.delayed(Duration.zero);
    expect(slow.active, 1);
    slow.gate.complete();
    await saved;
    expect(slow.maxActive, 1);
    expect(slow.data!['players'], hasLength(8));
    expect(slow.data!['mode'], 'family');
  });
}
