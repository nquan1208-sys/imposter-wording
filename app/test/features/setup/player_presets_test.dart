import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/models/game_setup.dart';
import 'package:untitled/models/content.dart';
import '../../data/fixtures.dart';

class GatedStorage extends MemoryStorage {
  final gate = Completer<void>();
  @override
  Future<void> write(JsonMap data) async {
    await gate.future;
    await super.write(data);
  }
}

void main() {
  late ContentRepository content;
  late MemoryStorage file;
  late SetupStore store;
  setUp(() async {
    file = MemoryStorage();
    content = ContentRepository(
      cache: MemoryStorage(),
      fetchPage: (t, l, f, e) => fixturePage(fixture(), t, l, f, e),
    );
    await content.load();
    store = SetupStore(content: content, file: file);
    await store.restore();
  });
  tearDown(() {
    store.dispose();
    content.dispose();
  });

  test('legacy library defaults and complete record validation', () {
    final old = GameSetup.defaults().toJson()
      ..remove('presets')
      ..remove('activePresetId')
      ..remove('nextPresetId');
    expect(GameSetup.fromJson(old).presets, isEmpty);
    final p = PlayerPreset(
      'preset-1',
      'Friends',
      GameSetup.defaults(),
    ).toJson();
    for (final invalid in [
      {...old, 'activePresetId': 'preset-1'},
      {
        ...old,
        'presets': [p],
        'nextPresetId': 1,
      },
      {
        ...old,
        'presets': [
          p,
          {...p, 'id': 'preset-2', 'name': ' friends '},
        ],
        'nextPresetId': 3,
      },
      {
        ...old,
        'presets': [
          {...p, 'players': []},
        ],
        'nextPresetId': 2,
      },
    ]) {
      expect(() => GameSetup.fromJson(invalid), throwsA(anything));
    }
    expect(p.keys, isNot(contains('gameType')));
    expect(p.keys, isNot(contains('categoryIds')));
    expect(p.keys, isNot(contains('contentLocale')));
  });

  test(
    'create from draft, trim names, duplicate checks and stable IDs',
    () async {
      final original = store.setup.value;
      final draft = original.copyWith(
        players: original.players.reversed.toList(),
      );
      final a = await store.createPreset('  Friends  ', draft);
      expect(a, 'preset-1');
      expect(store.setup.value.activePresetId, null);
      expect(store.setup.value.players.first.id, original.players.first.id);
      expect(
        store.setup.value.presets.single.setup.players.first.id,
        draft.players.first.id,
      );
      expect(store.setup.value.presets.single.name, 'Friends');
      expect(store.validPresetName(' friends '), false);
      expect(await store.createPreset('FRIENDS', draft), null);
      expect(await store.createPreset(' ', draft), null);
      expect(
        await store.createPreset('Bad', draft.copyWith(nextPlayerId: 1)),
        null,
      );
      final b = await store.createPreset('Family', draft);
      expect(b, 'preset-2');
      await store.deletePreset(a!);
      expect(await store.createPreset('Friends', draft), 'preset-3');
      expect(store.setup.value.presets.map((p) => p.id), [b, 'preset-3']);
    },
  );

  test(
    'confirmation preserves type, mode, categories and selected group counters',
    () async {
      final small = GameSetup.defaults().copyWith(
        players: GameSetup.defaults().players.take(3).toList(),
        nextPlayerId: 4,
      );
      final id = await store.createPreset('Small', small);
      await store.setPlayerCount(100);
      await store.setGameType('question');
      await store.setFamily(true);
      await store.setCategories({'q'});
      expect(await store.confirmDraft(small, id), true);
      final s = store.setup.value;
      expect(s.nextPlayerId, 4);
      expect(s.activePresetId, id);
      expect(s.gameType, 'question');
      expect(s.family, true);
      expect(s.categoryIds, {'q'});
      expect(GameSetup.fromJson(file.data!).toJson(), s.toJson());
      await store.setPlayerCount(4);
      expect(store.setup.value.players.last.id, 'player-4');
    },
  );

  test(
    'active rules autosave atomically; unsaved association leaves group intact',
    () async {
      await store.setPlayerCount(5);
      final id = await store.createPreset('Friends', store.setup.value);
      await store.confirmDraft(store.setup.value, id);
      final before = file.writes;
      await store.setRules(
        imposters: 2,
        randomImposters: true,
        imposterNotFirst: true,
        showCategory: true,
        knowEachOther: true,
      );
      expect(file.writes, before + 1);
      expect(
        store.setup.value.presets.single.setup.rosterJson(),
        store.setup.value.rosterJson(),
      );
      final saved = store.setup.value.presets.single.setup.rosterJson();
      await store.confirmDraft(store.setup.value, null);
      await store.setRules(knowEachOther: false);
      expect(store.setup.value.activePresetId, null);
      expect(store.setup.value.presets.single.setup.rosterJson(), saved);
    },
  );

  test(
    'rename preserves IDs and stale draft; deletion cannot be undone by confirmation',
    () async {
      final draft = store.setup.value;
      final id = (await store.createPreset('Friends', draft))!;
      await store.confirmDraft(draft, id);
      expect(await store.renamePreset(id, '  Team  '), true);
      expect(store.setup.value.presets.single.id, id);
      expect(store.setup.value.presets.single.name, 'Team');
      await store.deletePreset(id);
      expect(store.setup.value.activePresetId, null);
      expect(store.setup.value.rosterJson(), draft.rosterJson());
      await store.confirmDraft(draft, id);
      expect(store.setup.value.presets, isEmpty);
      expect(store.setup.value.activePresetId, null);
    },
  );

  test(
    'failed write retains committed library and attempted rules for retry',
    () async {
      final id = await store.createPreset('Team', store.setup.value);
      await store.confirmDraft(store.setup.value, id);
      final committed = store.setup.value.toJson();
      file.failWrite = true;
      expect(await store.setRules(knowEachOther: true), false);
      expect(store.setup.value.toJson(), committed);
      expect(file.data, committed);
      file.failWrite = false;
      expect(await store.save(), true);
      expect(store.setup.value.knowEachOther, true);
      expect(store.setup.value.presets.single.setup.knowEachOther, true);
      file.failWrite = true;
      expect(await store.deletePreset(id!), false);
      expect(store.setup.value.activePresetId, id);
    },
  );

  test(
    'malformed or unreadable library blocks every write until retry',
    () async {
      final data = store.setup.value.toJson()
        ..['presets'] = [
          {'id': 'preset-1'},
        ];
      file.data = data;
      await store.restore();
      expect(store.readFailed.value, true);
      expect(await store.createPreset('Lost', GameSetup.defaults()), null);
      expect(await store.setRules(knowEachOther: true), false);
      expect(await store.save(), false);
      expect(file.data, same(data));
      expect(file.writes, 0);
      file.data = GameSetup.defaults().toJson();
      await store.restore();
      expect(await store.createPreset('Team', store.setup.value), 'preset-1');
    },
  );

  test(
    'category replacement queues behind an in-flight write and disposal preserves filtering',
    () async {
      final disk = GatedStorage();
      final queued = SetupStore(content: content, file: disk);
      await queued.restore();
      final selection = queued.setCategories({'a', 'b'});
      await Future<void>.delayed(Duration.zero);
      final data = fixture();
      (data['words'] as List).removeWhere((w) => w['category_id'] == 'b');
      content.snapshot.value = ContentSnapshot.fromJson(data, 'vi');
      final mode = queued.setFamily(true);
      queued.dispose();
      disk.gate.complete();
      expect(await selection, true);
      expect(await mode, true);
      await queued.pendingWrites;
      expect(GameSetup.fromJson(disk.data!).categoryIds, {'a'});
    },
  );

  test(
    'queued operations compute against last commit and drain after disposal',
    () async {
      final disk = GatedStorage();
      final queued = SetupStore(content: content, file: disk);
      await queued.restore();
      final a = queued.createPreset('A', GameSetup.defaults());
      final b = queued.createPreset('B', GameSetup.defaults());
      final rules = queued.setRules(knowEachOther: true);
      expect(queued.editable, false);
      expect(queued.setup.value.presets, isEmpty);
      queued.dispose();
      disk.gate.complete();
      expect(await a, 'preset-1');
      expect(await b, 'preset-2');
      expect(await rules, true);
      await queued.pendingWrites;
      final saved = GameSetup.fromJson(disk.data!);
      expect(saved.presets.map((p) => p.name), ['A', 'B']);
      expect(saved.knowEachOther, true);
    },
  );
}
