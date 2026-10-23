import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static late final AppConfig current;

  final String environment;
  final String supabaseUrl;
  final String supabasePublishableKey;

  const AppConfig._(
    this.environment,
    this.supabaseUrl,
    this.supabasePublishableKey,
  );

  static Future<AppConfig> load({
    String environment = const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'local',
    ),
  }) async {
    if (!const ['local', 'dev', 'prod'].contains(environment)) {
      throw StateError('APP_ENV must be local, dev or prod.');
    }

    final file = 'env/.env.$environment';
    final env = DotEnv();
    try {
      await env.load(fileName: file);
    } on FileNotFoundError {
      throw StateError(
        'Missing $file. Copy $file.example and fill in its values.',
      );
    } on EmptyEnvFileError {
      throw StateError(
        '$file is empty. Fill in the Supabase URL and publishable key.',
      );
    }

    final url = env.env['SUPABASE_URL']?.trim() ?? '';
    final key = env.env['SUPABASE_PUBLISHABLE_KEY']?.trim() ?? '';
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !const ['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw StateError(
        '$file: SUPABASE_URL must be an HTTP(S) URL with a host.',
      );
    }
    if (!key.startsWith('sb_publishable_') ||
        key.length <= 'sb_publishable_'.length) {
      throw StateError(
        '$file: SUPABASE_PUBLISHABLE_KEY must be a publishable key.',
      );
    }

    return AppConfig._(environment, url, key);
  }
}
