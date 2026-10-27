import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/models/content.dart';
import 'fixtures.dart';

void main() {
  ContentRepository repository(
    JsonMap data, {
    MemoryStorage? cache,
    int pageSize = 2,
  }) {
    final repo = ContentRepository(
      fetchPage: (t, l, f, e) => fixturePage(data, t, l, f, e),
      cache: cache ?? MemoryStorage(),
      pageSize: pageSize,
    );
    addTearDown(repo.dispose);
    return repo;
  }

  test(
    'loads every inclusive page, preserves metadata and counts category unions',
    () async {
      final repo = repository(fixture());
      await repo.load();
      expect(repo.loadFailed.value, false);
      expect(repo.snapshot.value!.words.map((w) => w.id), ['1', '2', '3']);
      expect(repo.snapshot.value!.words.first.imagePath, '1/image.png');
      expect(repo.snapshot.value!.contentLocale, 'vi');
      expect(repo.categoryCounts(family: false).values, [2, 1]);
      expect(repo.categoryCounts(family: true).values, [1]);
      expect(
        repo.eligibleWords(family: false, categoryIds: {'a', 'b'}).length,
        3,
      );
      expect(repo.eligibleWords(family: true, categoryIds: {'b'}), isEmpty);
      expect(
        repo.snapshot.value!.questions.single.imposterQuestion,
        'Worst food?',
      );
    },
  );

  test('deduplicates original IDs across pages', () async {
    final data = fixture();
    (data['words'] as List).insert(2, word('2', 'a', family: true));
    final repo = repository(data);
    await repo.load();
    expect(repo.eligibleWords(family: false).length, 3);
  });

  test('conflicting duplicate IDs fail without replacing cache', () async {
    final cache = MemoryStorage(fixture());
    final data = fixture();
    (data['words'] as List).add(word('1', 'b'));
    final repo = repository(data, cache: cache);
    await repo.load();
    expect(repo.loadFailed.value, true);
    expect(cache.writes, 0);
  });

  final mutations = <String, void Function(JsonMap)>{
    'inactive category': (d) => d['categories'][0]['is_active'] = false,
    'wrong game type': (d) => d['categories'][0]['game_type'] = 'question',
    'draft translation': (d) => d['words'][0]['t'][0]['status'] = 'draft',
    'wrong locale': (d) => d['words'][0]['t'][0]['locale'] = 'en',
    'missing translation': (d) => d['words'][0]['t'] = [],
    'unknown category': (d) => d['words'][0]['category_id'] = 'missing',
    'mixed question translations': (d) =>
        d['questions'][0]['t'].add({'imposter_question': 'Other'}),
    'missing question half': (d) =>
        d['questions'][0]['t'][0].remove('imposter_question'),
    'same question pair': (d) =>
        d['questions'][0]['t'][0]['imposter_question'] = 'Favorite food?',
    'mismatched translation ID': (d) =>
        d['words'][0]['t'][0]['prompt_id'] = 'other',
    'invalid difficulty': (d) => d['words'][0]['difficulty'] = 'unknown',
  };
  for (final mutation in mutations.entries) {
    test('${mutation.key} fails complete load and retains cache', () async {
      final cache = MemoryStorage(fixture());
      final data = fixture();
      mutation.value(data);
      final repo = repository(data, cache: cache);
      await repo.load();
      expect(repo.loadFailed.value, true);
      expect(repo.cached.value, true);
      expect(repo.snapshot.value!.words.length, 3);
      expect(cache.writes, 0);
    });
  }

  test(
    'interrupted page retains matching cache; simultaneous loads share request',
    () async {
      final gate = Completer<List<JsonMap>>();
      var calls = 0;
      final cache = MemoryStorage(fixture());
      final repo = ContentRepository(
        cache: cache,
        pageSize: 2,
        fetchPage: (t, l, f, e) async {
          calls++;
          if (f == 0) return gate.future;
          throw const SocketException('offline');
        },
      );
      addTearDown(repo.dispose);
      final first = repo.load();
      final second = repo.load();
      expect(identical(first, second), true);
      await Future<void>.delayed(Duration.zero);
      expect(repo.snapshot.value!.words.length, 3);
      expect(repo.loading.value, true);
      gate.complete([category('a'), category('b')]);
      await first;
      expect(calls, 2);
      expect(cache.writes, 0);
      expect(repo.loadFailed.value, true);
    },
  );

  test('successful empty response replaces cached snapshot', () async {
    final cache = MemoryStorage(fixture());
    final repo = repository({
      'categories': [],
      'words': [],
      'questions': [],
    }, cache: cache);
    await repo.load();
    expect(repo.snapshot.value!.words, isEmpty);
    expect(cache.data!['words'], isEmpty);
    expect(repo.cached.value, false);
  });

  test('cache write failure keeps downloaded content in memory', () async {
    final cache = MemoryStorage()..failWrite = true;
    final repo = repository(fixture(), cache: cache);
    await repo.load();
    expect(repo.snapshot.value!.words.length, 3);
    expect(repo.loadFailed.value, false);
    expect(repo.cacheWarning.value, true);
  });

  test(
    'offline retry reads cache again after a storage read failure',
    () async {
      final cache = MemoryStorage(fixture())..failRead = true;
      final repo = ContentRepository(
        cache: cache,
        fetchPage: (t, l, f, e) async => throw const SocketException('offline'),
      );
      addTearDown(repo.dispose);
      await repo.load();
      expect(repo.snapshot.value, null);
      expect(repo.cacheWarning.value, true);
      cache.failRead = false;
      await repo.load();
      expect(repo.snapshot.value!.words, hasLength(3));
      expect(repo.cached.value, true);
    },
  );

  test('malformed cache does not block successful download', () async {
    final repo = repository(fixture(), cache: MemoryStorage({'words': []}));
    await repo.load();
    expect(repo.snapshot.value!.words.length, 3);
    expect(repo.cacheWarning.value, false);
  });

  test(
    'Supabase requests use inner published locale joins, stable order and inclusive range',
    () async {
      final requests = <Uri>[];
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final subscription = server.listen((request) async {
        requests.add(request.uri);
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode([]));
        await request.response.close();
      });
      final client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'sb_publishable_test',
      );
      addTearDown(() async {
        await client.dispose();
        await subscription.cancel();
        await server.close(force: true);
      });
      final source = SupabaseContentSource(client);
      for (final table in [
        'game_categories',
        'word_prompts',
        'question_prompts',
      ]) {
        await source.fetch(table, 'vi', 500, 999);
      }
      for (final uri in requests) {
        expect(uri.queryParameters['t.locale'], 'eq.vi');
        expect(uri.queryParameters['t.status'], 'eq.published');
        expect(uri.queryParameters['select'], contains('!inner'));
        expect(uri.queryParameters['order'], startsWith('id.asc'));
        expect(uri.queryParameters['offset'], '500');
        expect(uri.queryParameters['limit'], '500');
      }
      expect(requests.first.queryParameters['is_active'], 'eq.true');
      expect(requests[1].queryParameters['c.t.status'], 'eq.published');
      expect(requests[1].queryParameters['c.is_active'], 'eq.true');
    },
  );
}
