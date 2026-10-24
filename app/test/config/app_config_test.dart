import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final files = <String, String>{};
  const valid =
      'SUPABASE_URL=https://example.supabase.co\n'
      'SUPABASE_PUBLISHABLE_KEY=sb_publishable_test';

  setUp(() {
    files.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final path = utf8.decode(
            message!.buffer.asUint8List(
              message.offsetInBytes,
              message.lengthInBytes,
            ),
          );
          final content = files[path];
          return content == null
              ? null
              : ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    rootBundle.clear();
  });

  for (final environment in ['local', 'dev', 'prod']) {
    test('loads only the selected $environment file', () async {
      files['env/.env.$environment'] = valid;
      final config = await AppConfig.load(environment: environment);

      expect(config.environment, environment);
      expect(config.supabaseUrl, 'https://example.supabase.co');
      expect(config.supabasePublishableKey, 'sb_publishable_test');
    });
  }

  test('defaults to local', () async {
    files['env/.env.local'] = valid;
    expect((await AppConfig.load()).environment, 'local');
  });

  test('HTTP is restricted to local development', () async {
    final http = valid.replaceFirst(
      'https://example.supabase.co',
      'http://127.0.0.1:54321',
    );
    files['env/.env.local'] = http;
    expect((await AppConfig.load()).supabaseUrl, 'http://127.0.0.1:54321');
    for (final environment in ['dev', 'prod']) {
      files['env/.env.$environment'] = http;
      await expectLater(
        AppConfig.load(environment: environment),
        throwsStateError,
      );
    }
  });

  test('rejects an unknown environment', () async {
    await expectLater(
      AppConfig.load(environment: '../prod'),
      throwsA(isA<StateError>()),
    );
  });

  test('missing selected file does not fall back to local', () async {
    files['env/.env.local'] = valid;
    await expectLater(
      AppConfig.load(environment: 'prod'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('env/.env.prod'),
        ),
      ),
    );
  });

  for (final invalid in [
    '',
    'SUPABASE_URL=https://example.supabase.co',
    'SUPABASE_PUBLISHABLE_KEY=sb_publishable_test',
    valid.replaceFirst('https://example.supabase.co', 'not-a-url'),
    valid.replaceFirst('https://example.supabase.co', 'https:///'),
    valid.replaceFirst('https://example.supabase.co', 'ftp://example.com'),
    valid.replaceFirst('sb_publishable_test', 'sb_secret_test'),
    valid.replaceFirst('sb_publishable_test', 'sb_publishable_'),
  ]) {
    test('rejects invalid configuration: $invalid', () async {
      files['env/.env.local'] = invalid;
      await expectLater(AppConfig.load(), throwsA(isA<StateError>()));
    });
  }
}
