import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/models/content.dart';
import 'package:untitled/models/game_setup.dart';
import '../../data/fixtures.dart';

class SlowFile extends MemoryFile {
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

void main() {
  late ContentRepository content;
  late SetupStore store;
  late MemoryFile file;
  setUp(() async {
    final data = fixture();
    content = ContentRepository(
      cache: MemoryFile(),
      fetchPage: (t, l, f, e) => fixturePage(data, t, l, f, e),
    );
    file = MemoryFile();
    store = SetupStore(content: content, file: file);
    await content.load();
    await store.restore();
  });
  tearDown(() {
    store.dispose();
    content.dispose();
  });

  test(
    'defaults and player bounds retain IDs and never reuse removed IDs',
    () async {
      expect(store.setup.value.players.length, 4);
      final first = store.setup.value.players.first;
      store.setPlayerCount(2);
      expect(store.setup.value.players.length, 4);
      store.setPlayerCount(100);
      expect(store.setup.value.players.first, same(first));
      store.setPlayerCount(101);
      expect(store.setup.value.players.length, 100);
      store.setPlayerCount(3);
      store.setPlayerCount(4);
      expect(store.setup.value.players.last.id, 'player-101');
      await store.save();
      expect(GameSetup.fromJson(file.data!).players.last.id, 'player-101');
    },
  );

  test(
    'mode change removes unavailable categories, falls back to all and persists',
    () async {
      store.setCategories({'b'});
      store.setFamily(true);
      expect(store.setup.value.categoryIds, isEmpty);
      expect(store.selectionRemoved.value, true);
      await store.save();
      expect(file.data!['mode'], 'family');
      expect(file.data!['categoryIds'], isEmpty);
    },
  );

  test('replacement prunes selections and keeps surviving IDs', () {
    store.setCategories({'a', 'b'});
    final data = fixture();
    (data['words'] as List).removeWhere((w) => w['category_id'] == 'b');
    content.snapshot.value = ContentSnapshot.fromJson(data, 'vi');
    expect(store.setup.value.categoryIds, {'a'});
    content.snapshot.value = ContentSnapshot.fromJson({
      'categories': [],
      'words': [],
      'questions': [],
    }, 'vi');
    expect(store.setup.value.categoryIds, isEmpty);
  });

  test(
    'read failure blocks writes, retry restores; reset explicitly replaces',
    () async {
      file.data = GameSetup.defaults().copyWith(family: true).toJson();
      file.failRead = true;
      await store.restore();
      store.setPlayerCount(10);
      await store.save();
      expect(file.writes, 0);
      expect(store.editable, false);
      file.failRead = false;
      await store.restore();
      expect(store.setup.value.family, true);
      file.failRead = true;
      await store.restore();
      store.reset();
      await store.save();
      expect(file.data!['mode'], 'classic');
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

  test('write failure keeps visible setup and retry saves it', () async {
    file.failWrite = true;
    store.setPlayerCount(8);
    await store.save();
    expect(store.writeFailed.value, true);
    expect(store.setup.value.players.length, 8);
    file.failWrite = false;
    await store.save();
    expect(store.writeFailed.value, false);
    final restarted = SetupStore(content: content, file: file);
    addTearDown(restarted.dispose);
    await restarted.restore();
    expect(restarted.setup.value.players.length, 8);
  });

  test('writes serialize and last committed setup wins', () async {
    final slow = SlowFile();
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
