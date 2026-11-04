import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/data/content_language_repository.dart';
import 'package:untitled/data/content_repository.dart';
import 'fixtures.dart';

void main() {
  for (final environment in ['local', 'dev']) {
    test(
      'Phase 12 anonymous read-only $environment languages and translations',
      () async {
        final envFile = File('env/.env.$environment');
        if (!envFile.existsSync()) {
          markTestSkipped('$environment env unavailable');
          return;
        }
        final env = DotEnv()
          ..loadFromString(envString: envFile.readAsStringSync());
        final url = env.env['SUPABASE_URL']!;
        final client = SupabaseClient(
          url,
          env.env['SUPABASE_PUBLISHABLE_KEY']!,
        );
        addTearDown(client.dispose);
        final languages = ContentLanguageRepository(
          cache: MemoryStorage(),
          fetchPage: SupabaseLanguageSource(client).fetch,
          requestTimeout: const Duration(seconds: 5),
        );
        addTearDown(languages.dispose);
        await languages.load();
        if (languages.loadFailed.value) {
          markTestSkipped(
            '$environment $url anon language endpoint unavailable/rejected',
          );
          return;
        }
        debugPrint(
          '$environment $url: languages ${languages.languages.value!.map((l) => l.code).join(', ')}',
        );
        for (final language in languages.languages.value!) {
          final repo = ContentRepository(
            contentLocale: language.code,
            fetchPage: SupabaseContentSource(client).fetch,
            cache: MemoryStorage(),
            requestTimeout: const Duration(seconds: 5),
          );
          addTearDown(repo.dispose);
          await repo.load();
          expect(
            repo.loadFailed.value,
            false,
            reason: '$environment ${language.code}',
          );
          final snapshot = repo.snapshot.value!;
          expect(
            snapshot.words.every((p) => p.contentLocale == language.code),
            true,
          );
          expect(
            snapshot.questions.every((p) => p.contentLocale == language.code),
            true,
          );
          debugPrint(
            '$environment ${language.code}: ${snapshot.categories.length} categories, '
            '${snapshot.words.length} words (${repo.eligibleWords(family: true).length} family), '
            '${snapshot.questions.length} question pairs',
          );
        }
      },
      skip: Platform.environment['PHASE12_LIVE_CHECKS'] != '1'
          ? 'Opt-in anonymous read-only: PHASE12_LIVE_CHECKS=1'
          : false,
    );
  }
}
