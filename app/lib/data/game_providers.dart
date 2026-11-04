import 'package:untitled/data/content_language_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/data/local_image_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/config/app_config.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/hive_local_storage.dart';
import 'package:untitled/data/word_image_cache.dart';
import 'package:untitled/features/setup/setup_store.dart';

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());
final localImageStoreProvider = Provider<LocalImageStore>((ref) {
  final store = LocalImageStore(
    inventory: ref.watch(localStorageProvider).localImageReferences,
  );
  store.cleanup();
  return store;
});

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

final contentLanguageRepositoryProvider = Provider<ContentLanguageRepository>((
  ref,
) {
  final repository = ContentLanguageRepository(
    fetchPage: SupabaseLanguageSource(Supabase.instance.client).fetch,
    cache: ref
        .watch(localStorageProvider)
        .scoped(
          environment: AppConfig.current.environment,
          backendUrl: AppConfig.current.supabaseUrl,
          locale: '',
          name: 'languages',
        ),
  );
  ref.onDispose(repository.dispose);
  repository.load();
  return repository;
});

final contentRepositoryProvider = Provider.family<ContentRepository, String>((
  ref,
  locale,
) {
  final repository = ContentRepository(
    contentLocale: locale,
    images: ref.watch(wordImageCacheProvider),
    fetchPage: SupabaseContentSource(Supabase.instance.client).fetch,
    cache: ref
        .watch(localStorageProvider)
        .scoped(
          environment: AppConfig.current.environment,
          backendUrl: AppConfig.current.supabaseUrl,
          locale: locale,
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
    images: ref.watch(localImageStoreProvider),
    content: ref.watch(contentRepositoryProvider('vi')),
    repositoryForLocale: (locale) =>
        ref.read(contentRepositoryProvider(locale)),
    languages: ref.watch(contentLanguageRepositoryProvider),
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
