import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/config/app_config.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/scoped_json_file.dart';
import 'package:untitled/features/setup/setup_store.dart';

ScopedJsonFile scopedFile(String name) => ScopedJsonFile(
  environment: AppConfig.current.environment,
  backendUrl: AppConfig.current.supabaseUrl,
  locale: 'vi',
  name: name,
);

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final repository = ContentRepository(
    fetchPage: SupabaseContentSource(Supabase.instance.client).fetch,
    cache: scopedFile('snapshot'),
  );
  ref.onDispose(repository.dispose);
  repository.load();
  return repository;
});

final setupStoreProvider = Provider<SetupStore>((ref) {
  final store = SetupStore(
    content: ref.watch(contentRepositoryProvider),
    file: scopedFile('setup'),
  );
  ref.onDispose(store.dispose);
  store.restore();
  return store;
});
