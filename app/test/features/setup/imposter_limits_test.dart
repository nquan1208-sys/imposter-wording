import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/models/game_setup.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/features/setup/setup_store.dart';
import '../../data/fixtures.dart';

void main() {
  GameSetup team(int n, {bool restricted = false}) =>
      GameSetup.defaults().copyWith(
        players: List.generate(n, (i) => SetupPlayer('player-${i + 1}', 'P$i')),
        nextPlayerId: n + 1,
        imposterNotFirst: restricted,
      );

  test('limits and legacy normalization preserve unrelated data', () {
    for (final n in [3, 4, 5, 6, 7, 100]) {
      expect(team(n).maxImposters, (n - 1) ~/ 2);
      final raw = team(n, restricted: true).copyWith(imposters: (n - 1) ~/ 2);
      expect(raw.maxImposters, (n - 2) ~/ 2);
      final restored = GameSetup.fromJson(raw.toJson());
      expect(restored.validRules, isTrue);
      expect(restored.imposterNotFirst, n >= 4);
      expect(restored.imposters, n == 3 ? 1 : (n - 2) ~/ 2);
      expect(
        restored.players.map((p) => p.name),
        raw.players.map((p) => p.name),
      );
      expect(GameSetup.fromJson(restored.toJson()).toJson(), restored.toJson());
    }
    expect(
      () => GameSetup.fromJson(team(5).copyWith(imposters: 3).toJson()),
      throwsFormatException,
    );
  });

  for (final fail in [false, true]) {
    test(
      'legacy settings and presets migrate with write failure=$fail',
      () async {
        final old = team(5, restricted: true).copyWith(imposters: 2);
        final data = old
            .copyWith(
              presets: [PlayerPreset('preset-1', 'Friends', old)],
              nextPresetId: 2,
              activePresetId: 'preset-1',
            )
            .toJson();
        GameSetup.fromJson(data);
        final file = MemoryStorage(data)..failWrite = fail;
        final store = SetupStore(
          content: ContentRepository(
            cache: MemoryStorage(),
            fetchPage: (t, l, f, e) => fixturePage(fixture(), t, l, f, e),
          ),
          file: file,
        );
        addTearDown(store.dispose);
        await store.restore();
        expect(store.readFailed.value, isFalse);
        expect(store.rulesAdjusted.value, isTrue);
        expect(store.setup.value.imposters, 1);
        expect(store.setup.value.presets.single.setup.imposters, 1);
        expect(store.writeFailed.value, fail);
        if (fail) {
          expect(file.data, data);
          file.failWrite = false;
          expect(await store.save(), isTrue);
        }
        expect(file.data!['imposters'], 1);
        expect(store.setup.value.activePresetId, 'preset-1');
      },
    );
  }

  test('roster reductions adjust rules and announce changes', () async {
    final store = SetupStore(
      content: ContentRepository(
        cache: MemoryStorage(),
        fetchPage: (t, l, f, e) => fixturePage(fixture(), t, l, f, e),
      ),
      file: MemoryStorage(),
    );
    addTearDown(store.dispose);
    await store.restore();
    await store.setPlayerCount(6);
    await store.setRules(imposters: 2, imposterNotFirst: true);
    await store.setPlayerCount(5);
    expect(store.setup.value.imposters, 1);
    expect(store.rulesAdjusted.value, isTrue);
    await store.setPlayerCount(4);
    await store.setPlayerCount(3);
    expect(store.setup.value.imposterNotFirst, isFalse);
    expect(store.rulesAdjusted.value, isTrue);
  });
}
