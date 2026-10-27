import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/data/word_image_cache.dart';
import 'package:untitled/models/content.dart';
import 'fixtures.dart';
import 'image_fixture.dart';

void main() {
  late Directory root;
  late HttpServer server;
  var requests = 0, signs = 0;
  var status = 200;
  var invalid = false, empty = false, oversized = false, hang = false;
  var inventoryFails = false, failFirst = false;
  Set<String> references = {};
  ContentSnapshot snapshot([List<String> paths = const ['one.png']]) {
    final data = fixture();
    data['words'] = [
      for (var i = 0; i < paths.length; i++)
        word('$i', 'a')..['image_path'] = paths[i],
    ];
    return ContentSnapshot.fromJson(data, 'vi');
  }

  WordImageCache cache({
    String backend = 'https://one.example',
    Future<Set<String>> Function()? inventory,
  }) {
    final result = WordImageCache(
      backendUrl: backend,
      directory: () async => root,
      inventory:
          inventory ??
          () async {
            if (inventoryFails) {
              throw const FormatException('corrupt inventory');
            }
            return references;
          },
      requestTimeout: const Duration(milliseconds: 100),
      signedUrl: (path) async {
        signs++;
        return Uri(
          scheme: 'http',
          host:
              Platform.environment['TEST_HTTP_HOST'] ?? server.address.address,
          port: server.port,
          path: '/$path',
        ).toString();
      },
    );
    addTearDown(result.dispose);
    return result;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('word-images-');
    requests = signs = 0;
    status = 200;
    invalid = empty = oversized = hang = inventoryFails = false;
    references = {};
    failFirst = false;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests++;
      if (hang) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      request.response.statusCode = failFirst && request.uri.path == '/one.png'
          ? 500
          : status;
      final expired = status == 400;
      if (status == 401 || status == 400 || status == 403) status = 200;
      request.response.headers.contentType = ContentType('image', 'png');
      if (oversized) {
        request.response.contentLength = WordImageCache.maxBytes + 1;
      }
      if (expired) {
        request.response.write('jwt expired');
      } else if (!empty && !oversized) {
        request.response.add(invalid ? [1, 2, 3] : imageFixture());
      }
      try {
        await request.response.close();
      } catch (_) {}
    });
  });
  tearDown(() async {
    await server.close(force: true);
    await root.delete(recursive: true);
  });

  test(
    'deduplicates, survives restart, shares locales, isolates backends',
    () async {
      final first = cache();
      first.refresh(snapshot(['one.png', 'one.png']));
      first.refresh(snapshot());
      await first.pending;
      expect(requests, 1);
      final file = first.file('one.png')!;
      expect(await file.readAsBytes(), imageFixture());
      final restarted = cache(backend: 'https://one.example/');
      restarted.refresh(snapshot());
      await restarted.pending;
      expect(restarted.file('one.png')!.path, file.path);
      expect(requests, 1);
      final data = fixture();
      data['categories'] = [category('a', locale: 'en')];
      data['words'] = [
        word('1', 'a', locale: 'en')..['image_path'] = 'one.png',
      ];
      data['questions'] = [];
      restarted.refresh(ContentSnapshot.fromJson(data, 'en'));
      await restarted.pending;
      expect(requests, 1);
      final other = cache(backend: 'https://two.example');
      other.refresh(snapshot());
      await other.pending;
      expect(requests, 2);
      expect(other.file('one.png')!.path, isNot(file.path));
    },
  );

  test(
    'restores offline files before waiting for missing image downloads',
    () async {
      final initial = cache();
      initial.refresh(snapshot(['two.png']));
      await initial.pending;
      final gate = Completer<String>();
      final restored = Completer<void>();
      final restarted = WordImageCache(
        backendUrl: 'https://one.example',
        directory: () async => root,
        inventory: () async => {},
        signedUrl: (_) => gate.future,
      );
      addTearDown(restarted.dispose);
      restarted.addListener(() {
        if (restarted.file('two.png') != null && !restored.isCompleted) {
          restored.complete();
        }
      });
      restarted.refresh(snapshot(['missing.png', 'two.png']));
      await restored.future.timeout(const Duration(seconds: 2));
      expect(restarted.file('two.png'), isNotNull);
      gate.completeError(const SocketException('offline'));
      await restarted.pending;
      expect(restarted.file('missing.png'), null);
    },
  );

  for (final code in [400, 401, 403]) {
    test('renews signed URL once after $code', () async {
      status = code;
      final images = cache();
      images.refresh(snapshot());
      await images.pending;
      expect(signs, 2);
      expect(images.file('one.png'), isNotNull);
    });
  }

  for (final failure in [
    'invalid',
    'empty',
    'oversized',
    'server',
    'timeout',
    'write',
  ]) {
    test('$failure is isolated, waits for refresh, then recovers', () async {
      invalid = failure == 'invalid';
      empty = failure == 'empty';
      oversized = failure == 'oversized';
      hang = failure == 'timeout';
      if (failure == 'server') status = 500;
      final images = cache();
      final obstacle = File('${root.path}/word-images');
      if (failure == 'write') await obstacle.writeAsString('blocked');
      images.refresh(snapshot());
      await images.pending;
      expect(images.file('one.png'), null);
      expect(signs, 1);
      if (failure == 'write') await obstacle.delete();
      invalid = empty = oversized = hang = false;
      status = 200;
      images.refresh(snapshot());
      await images.pending;
      expect(images.file('one.png'), isNotNull);
      expect(signs, 2);
      expect(
        await root
            .list(recursive: true)
            .where((f) => f.path.endsWith('.tmp'))
            .isEmpty,
        true,
      );
    });
  }

  test('failed image does not block following images', () async {
    failFirst = true;
    final images = cache();
    images.refresh(snapshot(['one.png', 'two.png']));
    await images.pending;
    expect(images.file('one.png'), null);
    expect(images.file('two.png'), isNotNull);
  });

  test('corrupt file is redownloaded on next refresh', () async {
    final images = cache();
    images.refresh(snapshot());
    await images.pending;
    await images.file('one.png')!.writeAsString('broken');
    images.refresh(snapshot());
    await images.pending;
    expect(requests, 2);
    expect(await images.file('one.png')!.readAsBytes(), imageFixture());
    await images.file('one.png')!.delete();
    images.refresh(snapshot());
    await images.pending;
    expect(requests, 3);
    expect(await images.file('one.png')!.exists(), true);
  });

  test(
    'cleanup protects inventory and pins; corrupt inventory disables pruning',
    () async {
      final images = cache();
      images.refresh(snapshot(['one.png', 'two.png', 'three.png']));
      await images.pending;
      final one = images.file('one.png')!;
      final two = images.file('two.png')!;
      final three = images.file('three.png')!;
      references = {'one.png'};
      final release = images.pin('two.png');
      images.refresh(snapshot([]));
      await images.pending;
      expect(await one.exists(), true);
      expect(await two.exists(), true);
      expect(await three.exists(), false);
      inventoryFails = true;
      references = {};
      release();
      await images.pending;
      expect(await two.exists(), true);
      inventoryFails = false;
      images.refresh(snapshot([]));
      await images.pending;
      expect(await one.exists(), false);
      expect(await two.exists(), false);
    },
  );

  test('pin acquired while inventory is awaiting protects the file', () async {
    Completer<Set<String>>? gate;
    final images = cache(
      inventory: () async => gate == null ? {} : gate.future,
    );
    images.refresh(snapshot());
    await images.pending;
    final file = images.file('one.png')!;
    gate = Completer<Set<String>>();
    images.refresh(snapshot([]));
    await Future<void>.delayed(Duration.zero);
    final release = images.pin('one.png');
    gate.complete({});
    await images.pending;
    expect(await file.exists(), true);
    release();
    await images.pending;
    expect(await file.exists(), false);
  });
}
