import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/data/local_image_store.dart';
import 'image_fixture.dart';
import 'package:untitled/features/setup/setup_store.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/models/game_setup.dart';
import 'fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late File source;
  late LocalImageStore images;
  final persisted = <String>{};
  setUp(() async {
    persisted.clear();
    root = await Directory.systemTemp.createTemp('local-images-');
    source = await File(
      '${root.path}/library.png',
    ).writeAsBytes(imageFixture());
    images = LocalImageStore(
      directory: () async => root,
      inventory: () async => persisted,
    );
  });
  tearDown(() async {
    await images.cleanup();
    await root.delete(recursive: true);
  });

  test(
    'failed save and clear retain files; successful clear respects session pin',
    () async {
      final file = MemoryStorage();
      images = LocalImageStore(
        directory: () async => root,
        inventory: () async => file.data == null
            ? {}
            : GameSetup.fromJson(file.data!).localImageIds,
      );
      final content = ContentRepository(
        cache: MemoryStorage(),
        fetchPage: (t, l, f, e) async => [],
      );
      final setup = SetupStore(content: content, file: file, images: images);
      addTearDown(() {
        setup.dispose();
        content.dispose();
      });
      await setup.restore();
      final draft = Object(), session = Object();
      final id = await images.import(source, draft);
      file.failWrite = true;
      expect(
        await setup.createCustomWordCategory(
          'Local',
          ['A'],
          family: true,
          imageIds: {'A': id},
        ),
        isNull,
      );
      await images.cleanup();
      expect(await (await images.file(id)).exists(), true);
      file.failWrite = false;
      expect(
        await setup.createCustomWordCategory(
          'Local',
          ['A'],
          family: true,
          imageIds: {'A': id},
        ),
        'custom-word-1',
      );
      images.release(draft);
      await images.cleanup();
      expect(await (await images.file(id)).exists(), true);
      file.failWrite = true;
      expect(await setup.clearCustomCategories(), false);
      await images.cleanup();
      expect(await (await images.file(id)).exists(), true);
      images.retain(session, {id});
      file.failWrite = false;
      expect(await setup.clearCustomCategories(), true);
      await images.cleanup();
      expect(await (await images.file(id)).exists(), true);
      images.release(session);
      await images.cleanup();
      expect(await (await images.file(id)).exists(), false);
    },
  );

  test('queued save pins attachments before the draft is released', () async {
    final file = MemoryStorage();
    final gate = Completer<void>();
    images = LocalImageStore(
      directory: () async => root,
      inventory: () async =>
          file.data == null ? {} : GameSetup.fromJson(file.data!).localImageIds,
    );
    final content = ContentRepository(
      cache: MemoryStorage(),
      fetchPage: (t, l, f, e) async => [],
    );
    final setup = SetupStore(content: content, file: file, images: images);
    addTearDown(() {
      setup.dispose();
      content.dispose();
    });
    await setup.restore();
    final owner = Object();
    final id = await images.import(source, owner);
    final blocker = images.persist(() => gate.future);
    final saving = setup.createCustomWordCategory(
      'Local',
      ['A'],
      family: true,
      imageIds: {'A': id},
    );
    images.release(owner);
    final cleanup = images.cleanup();
    gate.complete();
    await blocker;
    await saving;
    await cleanup;
    expect(await (await images.file(id)).exists(), true);
    expect(setup.setup.value.localImageIds, {id});
  });

  test(
    'copies bytes atomically, pins drafts and sessions, preserves source',
    () async {
      final draft = Object(), session = Object();
      final id = await images.import(source, draft);
      expect(await (await images.file(id)).readAsBytes(), imageFixture());
      expect(await Directory('${root.path}/custom-images').list().length, 1);
      images.retain(session, {id});
      images.release(draft);
      await images.cleanup();
      expect(await (await images.file(id)).exists(), true);
      images.release(session);
      await images.cleanup();
      expect(await (await images.file(id)).exists(), false);
      expect(await source.exists(), true);
    },
  );
  test(
    'replacement releases old image but persisted references survive restart',
    () async {
      final owner = Object();
      final old = await images.import(source, owner);
      final replacement = await images.import(source, owner);
      images.retain(owner, {replacement});
      persisted.add(replacement);
      await images.cleanup();
      expect(await (await images.file(old)).exists(), false);
      images.release(owner);
      images = LocalImageStore(
        directory: () async => root,
        inventory: () async => persisted,
      );
      await images.cleanup();
      expect(await (await images.file(replacement)).exists(), true);
      persisted.clear();
      await images.cleanup();
      expect(await (await images.file(replacement)).exists(), false);
    },
  );
  test(
    'corrupt and oversized imports preserve previous reference and bytes',
    () async {
      final owner = Object();
      final id = await images.import(source, owner);
      final corrupt = await File(
        '${root.path}/corrupt',
      ).writeAsString('not an image');
      await expectLater(
        images.import(corrupt, owner),
        throwsA(isA<LocalImageException>()),
      );
      final oversized = File('${root.path}/large');
      final handle = await oversized.open(mode: FileMode.write);
      await handle.truncate(5 * 1024 * 1024 + 1);
      await handle.close();
      await expectLater(
        images.import(oversized, owner),
        throwsA(
          isA<LocalImageException>().having(
            (e) => e.oversized,
            'oversized',
            true,
          ),
        ),
      );
      await images.cleanup();
      expect(await (await images.file(id)).readAsBytes(), imageFixture());
    },
  );
  test('disk failure creates no reference and can retry', () async {
    await File('${root.path}/custom-images').writeAsString('blocked');
    await expectLater(
      images.import(source, Object()),
      throwsA(isA<FileSystemException>()),
    );
    await File('${root.path}/custom-images').delete();
    final owner = Object();
    final id = await images.import(source, owner);
    expect(await (await images.file(id)).exists(), true);
  });
  test('rejects absolute paths, traversal and non-opaque IDs', () async {
    for (final id in ['/tmp/x', '../x', 'a/../x', r'C:\x', 'photo.png']) {
      await expectLater(images.file(id), throwsFormatException);
      expect(() => images.retain(Object(), {id}), throwsFormatException);
    }
  });
  test('unreadable inventory skips pruning and retries after repair', () async {
    final owner = Object();
    final id = await images.import(source, owner);
    var broken = true;
    images = LocalImageStore(
      directory: () async => root,
      inventory: () async {
        if (broken) throw const FormatException('corrupt setup');
        return {};
      },
    );
    await images.cleanup();
    expect(await (await images.file(id)).exists(), true);
    broken = false;
    await images.cleanup();
    expect(await (await images.file(id)).exists(), false);
  });
  test(
    'serializes cleanup and imports without pruning newly imported draft',
    () async {
      final gate = Completer<Set<String>>();
      images = LocalImageStore(
        directory: () async => root,
        inventory: () => gate.future,
      );
      final cleanup = images.cleanup();
      final owner = Object();
      final importing = images.import(source, owner);
      gate.complete({});
      await cleanup;
      final id = await importing;
      await images.cleanup();
      expect(await (await images.file(id)).exists(), true);
      images.release(owner);
      await images.cleanup();
      expect(await (await images.file(id)).exists(), false);
    },
  );
}
