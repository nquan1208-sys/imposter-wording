import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/word_image_cache.dart';
import 'fixtures.dart';

void main() {
  final file = File('env/.env.test');
  final env = DotEnv()
    ..loadFromString(
      envString: file.existsSync() ? file.readAsStringSync() : '',
      isOptional: true,
    );
  final simulationUrl =
      Platform.environment['SUPABASE_SIMULATION_URL'] ??
      env.env['SUPABASE_SIMULATION_URL'];
  for (final mode in [
    'ok',
    'middle',
    'json',
    'html',
    'malformed',
    'timeout',
    'renew',
    'imagefail',
  ]) {
    test(
      'real Supabase client against Postman: $mode',
      () async {
        final root = await Directory.systemTemp.createTemp('postman-images-');
        final client = SupabaseClient(
          '$simulationUrl/$mode',
          'sb_publishable_test',
        );
        final withImages = mode == 'renew' || mode == 'imagefail';
        final images = withImages
            ? WordImageCache(
                backendUrl: '$simulationUrl/$mode',
                directory: () async => root,
                inventory: () async => {},
                signedUrl: (path) => client.storage
                    .from('word-prompt-images')
                    .createSignedUrl(path, 300),
              )
            : null;
        final cache = MemoryStorage(fixture());
        final repo = ContentRepository(
          fetchPage: SupabaseContentSource(client).fetch,
          cache: cache,
          pageSize: 2,
          images: images,
          requestTimeout: mode == 'timeout'
              ? const Duration(milliseconds: 50)
              : const Duration(seconds: 15),
        );
        addTearDown(() async {
          repo.dispose();
          images?.dispose();
          await client.dispose();
          await root.delete(recursive: true);
        });
        await repo.load();
        if (['ok', 'renew', 'imagefail'].contains(mode)) {
          expect(repo.loadFailed.value, false);
          expect(repo.snapshot.value!.words.map((w) => w.id), [
            'one',
            'two',
            'three',
          ]);
          expect(cache.writes, 1);
          expect(repo.categoryCounts(family: true).values, [3]);
          expect(repo.eligibleWords(family: true).map((w) => w.id), [
            'one',
            'two',
            'three',
          ]);
        } else {
          expect(repo.loadFailed.value, true);
          expect(repo.cached.value, true);
          expect(repo.snapshot.value!.words.first.id, '1');
          expect(cache.writes, 0);
        }
        if (images != null) {
          await images.pending;
          expect(
            images.file('one/image.png'),
            mode == 'renew' ? isNotNull : isNull,
          );
          expect(jsonEncode(cache.data), isNot(contains('token=')));
        }
        if (mode == 'timeout') {
          await Future<void>.delayed(const Duration(milliseconds: 350));
          expect(cache.writes, 0);
          expect(repo.snapshot.value!.words.first.id, '1');
        }
      },
      skip: simulationUrl == null
          ? 'Set SUPABASE_SIMULATION_URL or env/.env.test to run local Postman HTTP checks'
          : false,
    );
  }

  for (final environment in ['local', 'dev']) {
    test(
      'read-only anonymous $environment content and Storage',
      () async {
        final settings = DotEnv()
          ..loadFromString(
            envString: await File('env/.env.$environment').readAsString(),
          );
        final url = settings.env['SUPABASE_URL']!;
        final key = settings.env['SUPABASE_PUBLISHABLE_KEY']!;
        final client = SupabaseClient(url, key);
        addTearDown(client.dispose);
        final repo = ContentRepository(
          fetchPage: SupabaseContentSource(client).fetch,
          cache: MemoryStorage(),
        );
        addTearDown(repo.dispose);
        await repo.load();
        if (repo.loadFailed.value) {
          markTestSkipped(
            '$environment anonymous endpoint unavailable or rejected; no backend writes attempted',
          );
          return;
        }
        final snapshot = repo.snapshot.value!;
        // Constructors reject draft, wrong-locale, inactive and incompatible categories.
        expect(snapshot.contentLocale, 'vi');
        debugPrint(
          '$environment: ${snapshot.categories.length} categories, ${snapshot.words.length} words, ${snapshot.questions.length} question pairs',
        );
        for (final table in [
          'game_category_translations',
          'word_prompt_translations',
          'question_prompt_translations',
        ]) {
          final rows = await client.from(table).select('status').limit(1000);
          expect(
            rows.every((r) => r['status'] == 'published'),
            true,
            reason: '$table must expose published translations only',
          );
        }
        final paths = snapshot.words
            .map((w) => w.imagePath)
            .whereType<String>()
            .toSet();
        // Anonymous cross-locale join finds images eligible only outside vi, if any.
        final all = await client
            .from('word_prompts')
            .select(
              'id,image_path,t:word_prompt_translations!inner(locale,status),c:game_categories!inner(id,t:game_category_translations!inner(locale,status))',
            );
        String? otherLocalePath;
        for (final row in all) {
          if (row['image_path'] == null || paths.contains(row['image_path'])) {
            continue;
          }
          final locales = (row['t'] as List)
              .where((t) => t['status'] == 'published')
              .map((t) => t['locale'])
              .toSet();
          final categoryLocales = (row['c']['t'] as List)
              .where((t) => t['status'] == 'published')
              .map((t) => t['locale'])
              .toSet();
          if (locales.intersection(categoryLocales).any((l) => l != 'vi')) {
            otherLocalePath = row['image_path'] as String;
            break;
          }
        }
        final selected = <String>{
          if (paths.isNotEmpty) paths.first,
          ?otherLocalePath,
        };
        for (final path in selected) {
          final signed = await client.storage
              .from('word-prompt-images')
              .createSignedUrl(path, 300);
          final http = HttpClient();
          try {
            final response = await (await http.getUrl(
              Uri.parse(signed),
            )).close().timeout(const Duration(seconds: 15));
            expect(response.statusCode, 200);
            expect(
              await response.fold<int>(0, (n, bytes) => n + bytes.length),
              greaterThan(0),
            );
          } finally {
            http.close(force: true);
          }
        }
        try {
          await client.storage
              .from('word-prompt-images')
              .createSignedUrl('phase-7-missing/image.png', 300);
          fail('Anonymous signing must reject an unreferenced/missing object');
        } on StorageException {
          /* Expected: read-only negative access check. */
        }
        debugPrint(
          '$environment: ${selected.length} image downloads; other-locale-only image ${otherLocalePath == null ? 'unavailable in current data' : 'verified'}',
        );
      },
      skip: Platform.environment['PHASE7_LIVE_CHECKS'] != '1'
          ? 'Opt-in read-only checks: PHASE7_LIVE_CHECKS=1'
          : false,
    );
  }
}
