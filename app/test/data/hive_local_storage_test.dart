import 'package:untitled/features/setup/setup_store.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/config/app_config.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/game_providers.dart';
import 'package:hive_ce/hive.dart';
import 'package:untitled/data/hive_local_storage.dart';
import 'package:untitled/data/local_json_store.dart';
import 'package:untitled/data/scoped_json_file.dart';
import 'package:untitled/models/game_setup.dart';
import 'fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late HiveLocalStorage storage;
  ScopedJsonFile legacy(String name, {String locale = 'vi'}) => ScopedJsonFile(
    environment: 'local',
    backendUrl: 'https://EXAMPLE.com/',
    locale: locale,
    name: name,
    directory: () async => root,
  );
  LocalJsonStore local(
    String name, {
    String env = 'local',
    String url = 'https://example.com',
    String locale = 'vi',
  }) => storage.scoped(
    environment: env,
    backendUrl: url,
    locale: locale,
    name: name,
  );
  setUp(() async {
    root = await Directory.systemTemp.createTemp('hive-local-');
    storage = HiveLocalStorage(directory: () async => root);
  });
  tearDown(() async {
    await storage.close();
    await root.delete(recursive: true);
  });

  test(
    'inventory retains all backend locales and legacy references without importing',
    () async {
      await local('snapshot').write(fixture());
      final english = {
        'categories': [category('en', locale: 'en')],
        'words': [word('english', 'en', locale: 'en')],
        'questions': <dynamic>[],
      };
      await legacy('snapshot', locale: 'en').write(english);
      await local('snapshot', url: 'https://other.com').write({
        'categories': [category('other')],
        'words': [word('other', 'other')],
        'questions': <dynamic>[],
      });
      expect(await storage.imageReferences('https://EXAMPLE.com/'), {
        '1/image.png',
        '2/image.png',
        '3/image.png',
        'english/image.png',
      });
      expect(Hive.box<String>('content_cache').length, 2);
    },
  );

  test('inventory refuses corrupt Hive and legacy snapshots', () async {
    await local('snapshot').write(fixture());
    final box = Hive.box<String>('content_cache');
    final scope = legacy('snapshot').scope;
    final original = box.get(scope)!;
    await box.put(scope, 'broken');
    await expectLater(
      storage.imageReferences('https://example.com'),
      throwsA(anything),
    );
    await box.put(scope, original);
    await legacy('snapshot', locale: 'en').write({'words': []});
    await expectLater(
      storage.imageReferences('https://example.com'),
      throwsA(anything),
    );
    expect(box.length, 1);
  });

  test(
    'write, close and reopen; isolates boxes, environment, backend and locale',
    () async {
      await local('snapshot').write(fixture());
      await local('setup').write(GameSetup.defaults().toJson());
      await storage.close();
      storage = HiveLocalStorage(directory: () async => root);
      expect(
        await local('snapshot', url: 'https://EXAMPLE.com/').read(),
        fixture(),
      );
      expect(await local('setup').read(), GameSetup.defaults().toJson());
      expect(await local('snapshot', env: 'prod').read(), null);
      expect(await local('snapshot', url: 'https://other.com').read(), null);
      expect(await local('snapshot', locale: 'en').read(), null);
    },
  );

  test(
    'legacy setup migrates; preset library and association survive real close/reopen',
    () async {
      final old = GameSetup.defaults().toJson()
        ..remove('presets')
        ..remove('activePresetId')
        ..remove('nextPresetId');
      await legacy('setup').write(old);
      final legacyBytes = await (await legacy('setup').file).readAsString();
      final content = ContentRepository(
        cache: MemoryStorage(),
        fetchPage: (t, l, f, e) => fixturePage(fixture(), t, l, f, e),
      );
      addTearDown(content.dispose);
      final setup = SetupStore(content: content, file: local('setup'));
      await setup.restore();
      expect(setup.setup.value.presets, isEmpty);
      final id = await setup.createPreset('Team', setup.setup.value);
      await setup.confirmDraft(setup.setup.value.presets.single.setup, id);
      await setup.setRules(
        knowEachOther: true,
        randomImposters: true,
        showCategory: true,
      );
      await setup.renamePreset(id!, 'Friends');
      final expected = setup.setup.value.toJson();
      setup.dispose();
      storage.waitBeforeClose(setup.pendingWrites);
      await storage.close();
      storage = HiveLocalStorage(directory: () async => root);
      final reopened = SetupStore(content: content, file: local('setup'));
      addTearDown(reopened.dispose);
      await reopened.restore();
      expect(reopened.setup.value.toJson(), expected);
      expect(reopened.setup.value.presets.single.setup.knowEachOther, true);
      expect(await (await legacy('setup').file).readAsString(), legacyBytes);
      await reopened.deletePreset(id);
      final afterDelete = reopened.setup.value.toJson();
      await storage.close();
      storage = HiveLocalStorage(directory: () async => root);
      expect(await local('setup').read(), afterDelete);
      expect(GameSetup.fromJson(afterDelete).activePresetId, null);
    },
  );

  test(
    'migration rejects a malformed preset without importing or altering JSON',
    () async {
      final malformed = GameSetup.defaults().toJson()
        ..['presets'] = [
          {'id': 'preset-1', 'name': 'Incomplete'},
        ]
        ..['nextPresetId'] = 2;
      await legacy('setup').write(malformed);
      final before = await (await legacy('setup').file).readAsString();
      await expectLater(local('setup').read(), throwsA(anything));
      expect(Hive.box<String>('settings').isEmpty, true);
      expect(await (await legacy('setup').file).readAsString(), before);
    },
  );

  test(
    'concurrent operations share open; close drains accepted writes',
    () async {
      var opens = 0;
      final gate = Completer<Directory>();
      await storage.close();
      storage = HiveLocalStorage(
        directory: () {
          opens++;
          return gate.future;
        },
      );
      final first = local('setup').write(GameSetup.defaults().toJson());
      final newer = GameSetup.defaults().copyWith(family: true).toJson();
      final second = local('setup').write(newer);
      final closed = storage.close();
      gate.complete(root);
      await Future.wait([first, second, closed]);
      expect(opens, 1);
      await expectLater(local('setup').read(), throwsStateError);
      storage = HiveLocalStorage(directory: () async => root);
      expect(await local('setup').read(), newer);
    },
  );

  test('close waits for the disposed setup owner write queue', () async {
    final gate = Completer<void>();
    final newer = GameSetup.defaults().copyWith(family: true).toJson();
    final writes = gate.future
        .then((_) => local('setup').write(GameSetup.defaults().toJson()))
        .then((_) => local('setup').write(newer));
    storage.waitBeforeClose(writes);
    final closing = storage.close();
    gate.complete();
    await closing;
    storage = HiveLocalStorage(directory: () async => root);
    expect(await local('setup').read(), newer);
  });

  test(
    'provider disposal drains queued setup writes before closing storage',
    () async {
      AppConfig.current = await AppConfig.load();
      final content = ContentRepository(
        cache: MemoryStorage(),
        fetchPage: (t, l, f, e) => fixturePage(fixture(), t, l, f, e),
      );
      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWith((ref) {
            ref.onDispose(storage.close);
            return storage;
          }),
          contentRepositoryProvider.overrideWith((ref) {
            ref.onDispose(content.dispose);
            return content;
          }),
        ],
      );
      final setup = container.read(setupStoreProvider);
      await setup.restore();
      setup.setPlayerCount(6);
      setup.setPlayerCount(8);
      setup.setRules(showCategory: true);
      container.dispose();
      await storage.close();
      storage = HiveLocalStorage(directory: () async => root);
      final restored = await local(
        'setup',
        env: AppConfig.current.environment,
        url: AppConfig.current.supabaseUrl,
      ).read();
      expect(restored!['players'], hasLength(8));
      expect(restored['showCategory'], true);
    },
  );

  test(
    'Hive filesystem open failure can retry after directory repair',
    () async {
      final blocker = await File('${root.path}/hive').writeAsString('blocked');
      await expectLater(local('setup').read(), throwsA(anything));
      await blocker.delete();
      await local('setup').write(GameSetup.defaults().toJson());
      expect(await local('setup').read(), GameSetup.defaults().toJson());
    },
  );

  test(
    'failed put preserves previously committed data across restart',
    () async {
      final original = GameSetup.defaults().toJson();
      await local('setup').write(original);
      await Hive.box<String>('settings').close();
      await expectLater(
        local(
          'setup',
        ).write(GameSetup.defaults().copyWith(family: true).toJson()),
        throwsA(anything),
      );
      await storage.close();
      storage = HiveLocalStorage(directory: () async => root);
      expect(await local('setup').read(), original);
    },
  );

  test('failed open can retry', () async {
    await storage.close();
    var fail = true;
    storage = HiveLocalStorage(
      directory: () async {
        if (fail) throw const FileSystemException('unavailable');
        return root;
      },
    );
    await expectLater(
      local('setup').read(),
      throwsA(isA<FileSystemException>()),
    );
    fail = false;
    await local('setup').write(GameSetup.defaults().toJson());
    expect(await local('setup').read(), GameSetup.defaults().toJson());
  });

  for (final name in ['setup', 'snapshot']) {
    test(
      '$name migrates once, preserves JSON and prefers newer Hive on restart',
      () async {
        final data = name == 'setup'
            ? GameSetup.defaults().toJson()
            : fixture();
        await legacy(name).write(data);
        final target = await legacy(name).file;
        final original = await target.readAsString();
        expect(await local(name).read(), data);
        final newer = name == 'setup'
            ? GameSetup.defaults().copyWith(family: true).toJson()
            : {'categories': [], 'words': [], 'questions': []};
        await local(name).write(newer);
        expect(await target.readAsString(), original);
        await storage.close();
        storage = HiveLocalStorage(directory: () async => root);
        expect(await local(name).read(), newer);
      },
    );
    test('$name missing JSON returns null without creating a key', () async {
      expect(await local(name).read(), null);
      expect(
        Hive.box<String>(
          name == 'setup' ? 'settings' : 'content_cache',
        ).isEmpty,
        true,
      );
    });
    for (final corruption in ['version', 'scope', 'data', 'json']) {
      test(
        '$name rejects legacy $corruption and retries after repair',
        () async {
          final file = legacy(name);
          final data = name == 'setup'
              ? GameSetup.defaults().toJson()
              : fixture();
          await file.write(data);
          final target = await file.file;
          final envelope = {'version': 1, 'scope': file.scope, 'data': data};
          envelope[corruption] = corruption == 'data'
              ? <String, dynamic>{}
              : 'wrong';
          final broken = corruption == 'json' ? 'broken' : jsonEncode(envelope);
          await target.writeAsString(broken);
          await expectLater(local(name).read(), throwsA(anything));
          expect(await target.readAsString(), broken);
          expect(
            Hive.box<String>(
              name == 'setup' ? 'settings' : 'content_cache',
            ).isEmpty,
            true,
          );
          await file.write(data);
          expect(await local(name).read(), data);
        },
      );
    }
  }

  test(
    'failed migration put leaves JSON and no marker; restart retries',
    () async {
      final data = GameSetup.defaults().toJson();
      await legacy('setup').write(data);
      await storage.close();
      final readingLegacy = Completer<void>();
      final release = Completer<void>();
      var calls = 0;
      storage = HiveLocalStorage(
        directory: () async {
          if (++calls == 2) {
            readingLegacy.complete();
            await release.future;
          }
          return root;
        },
      );
      final migration = local('setup').read();
      final failed = expectLater(migration, throwsA(anything));
      await readingLegacy.future;
      await Hive.box<String>('settings').close();
      release.complete();
      await failed;
      expect(await legacy('setup').read(), data);
      await storage.close();
      storage = HiveLocalStorage(directory: () async => root);
      expect(await local('setup').read(), data);
    },
  );

  test(
    'corrupt Hive reports error without falling back to valid legacy JSON',
    () async {
      await legacy('setup').write(GameSetup.defaults().toJson());
      await local('setup').read();
      final box = Hive.box<String>('settings');
      for (final value in [
        'broken',
        jsonEncode({'version': 2, 'scope': legacy('setup').scope, 'data': {}}),
        jsonEncode({'version': 1, 'scope': 'other', 'data': {}}),
        jsonEncode({'version': 1, 'scope': legacy('setup').scope, 'data': {}}),
      ]) {
        await box.put(legacy('setup').scope, value);
        await expectLater(local('setup').read(), throwsA(anything));
        expect(box.get(legacy('setup').scope), value);
      }
    },
  );
}
