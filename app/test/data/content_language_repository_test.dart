import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/data/content_language_repository.dart';
import 'fixtures.dart';

void main() {
  test('all pages, DB names, deterministic order, and offline retry', () async {
    final cache = MemoryStorage();
    var offline = false;
    final calls = <(int, int)>[];
    final repo = ContentLanguageRepository(
      cache: cache,
      pageSize: 2,
      fetchPage: (from, to) async {
        calls.add((from, to));
        if (offline) throw const SocketException('offline');
        return [
          {'code': 'ja', 'display_name': '日本語', 'sort_order': 1},
          {'code': 'vi', 'display_name': 'Tiếng Việt', 'sort_order': 0},
          {'code': 'en', 'display_name': 'English', 'sort_order': 1},
        ].skip(from).take(to - from + 1).toList();
      },
    );
    addTearDown(repo.dispose);
    await repo.load();
    expect(calls, [(0, 1), (2, 3)]);
    expect(repo.languages.value!.map((l) => l.code), ['vi', 'en', 'ja']);
    expect(repo.name('ja'), '日本語');
    expect(repo.contains('fr'), false);
    offline = true;
    final restored = ContentLanguageRepository(
      cache: cache,
      fetchPage: repo.fetchPage,
    );
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.cached.value, true);
    expect(restored.loadFailed.value, true);
    expect(restored.name('ja'), '日本語');
    offline = false;
    await restored.load();
    expect(restored.loadFailed.value, false);
    expect(restored.cached.value, false);
  });

  test(
    'failed/invalid loads preserve last good cache; empty success replaces list',
    () async {
      final cache = MemoryStorage();
      var rows = [
        {'code': 'vi', 'display_name': 'Việt', 'sort_order': 0},
      ];
      final repo = ContentLanguageRepository(
        cache: cache,
        fetchPage: (from, to) async => rows,
      );
      addTearDown(repo.dispose);
      await repo.load();
      final good = cache.data;
      rows = [rows.first, rows.first];
      await repo.load();
      expect(repo.loadFailed.value, true);
      expect(cache.data, same(good));
      expect(repo.contains('vi'), true);
      rows = [];
      await repo.load();
      expect(repo.languages.value, isEmpty);
      expect(repo.loadFailed.value, false);
    },
  );

  test(
    'disk failure still exposes DB list; timeout and disposed responses are safe',
    () async {
      final gate = Completer<List<Map<String, dynamic>>>();
      final repo = ContentLanguageRepository(
        cache: MemoryStorage()..failWrite = true,
        fetchPage: (from, to) async => [
          {'code': 'en', 'display_name': 'English', 'sort_order': 0},
        ],
      );
      addTearDown(repo.dispose);
      await repo.load();
      expect(repo.contains('en'), true);
      expect(repo.cacheWarning.value, true);
      final cache = MemoryStorage();
      final timed = ContentLanguageRepository(
        cache: cache,
        requestTimeout: const Duration(milliseconds: 5),
        fetchPage: (_, _) => gate.future,
      );
      await timed.load();
      expect(timed.loadFailed.value, true);
      timed.dispose();
      gate.complete([]);
      await Future<void>.delayed(Duration.zero);
      expect(cache.writes, 0);
    },
  );

  test(
    'SDK requests only language columns with ordered inclusive pagination',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requests = <Uri>[];
      server.listen((request) async {
        requests.add(request.uri);
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode([]));
        await request.response.close();
      });
      final client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'anon-test',
      );
      addTearDown(client.dispose);
      await SupabaseLanguageSource(client).fetch(2, 3);
      final query = requests.single.queryParameters;
      expect(requests.single.path, '/rest/v1/content_languages');
      expect(query['select'], 'code,display_name,sort_order');
      expect(query['order'], 'sort_order.asc.nullslast,code.asc.nullslast');
      expect(query['offset'], '2');
      expect(query['limit'], '2');
    },
  );
}
