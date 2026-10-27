import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/config/app_config.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/hive_local_storage.dart';
import 'package:untitled/data/word_image_cache.dart';
import 'package:untitled/features/setup/setup_store.dart';

final localStorageProvider = Provider<HiveLocalStorage>((ref) {
  final storage = HiveLocalStorage();
  ref.onDispose(storage.close);
  return storage;
});

final wordImageCacheProvider = Provider<WordImageCache>((ref) {
  final storage = ref.watch(localStorageProvider);
  final cache = WordImageCache(
    backendUrl: AppConfig.current.supabaseUrl,
    signedUrl: (path) => Supabase.instance.client.storage
        .from('word-prompt-images')
        .createSignedUrl(path, 300),
    inventory: () => storage.imageReferences(AppConfig.current.supabaseUrl),
  );
  ref.onDispose(cache.dispose);
  return cache;
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final repository = ContentRepository(
    images: ref.watch(wordImageCacheProvider),
    fetchPage: SupabaseContentSource(Supabase.instance.client).fetch,
    cache: ref
        .watch(localStorageProvider)
        .scoped(
          environment: AppConfig.current.environment,
          backendUrl: AppConfig.current.supabaseUrl,
          locale: 'vi',
          name: 'snapshot',
        ),
  );
  ref.onDispose(repository.dispose);
  repository.load();
  return repository;
});

final setupStoreProvider = Provider<SetupStore>((ref) {
  final storage = ref.watch(localStorageProvider);
  final store = SetupStore(
    content: ref.watch(contentRepositoryProvider),
    file: storage.scoped(
      environment: AppConfig.current.environment,
      backendUrl: AppConfig.current.supabaseUrl,
      locale: 'vi',
      name: 'setup',
    ),
  );
  ref.onDispose(() {
    store.dispose();
    storage.waitBeforeClose(store.pendingWrites);
  });
  store.restore();
  return store;
});
