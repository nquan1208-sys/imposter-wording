import 'package:signals_flutter/signals_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/base/store/auto_dispose_manager.dart';
import 'package:untitled/base/store/store_base.dart';
import 'package:untitled/data/local_json_store.dart';
import 'package:untitled/models/content.dart';
import 'package:untitled/models/content_language.dart';

class SupabaseLanguageSource {
  final SupabaseClient client;
  SupabaseLanguageSource(this.client);
  Future<List<JsonMap>> fetch(int from, int to) async => await client
      .from('content_languages')
      .select('code,display_name,sort_order')
      .order('sort_order', ascending: true)
      .order('code', ascending: true)
      .range(from, to);
}

class ContentLanguageRepository extends StoreBase {
  final Future<List<JsonMap>> Function(int from, int to) fetchPage;
  final LocalJsonStore cache;
  final int pageSize;
  final Duration requestTimeout;
  final _disposers = AutoDisposeManager();
  late final languages = signal<List<ContentLanguage>?>(
    null,
  ).manageBy(_disposers);
  late final loading = signal(false).manageBy(_disposers);
  late final loadFailed = signal(false).manageBy(_disposers);
  late final cached = signal(false).manageBy(_disposers);
  late final cacheWarning = signal(false).manageBy(_disposers);
  Future<void>? _pending;

  ContentLanguageRepository({
    required this.fetchPage,
    required this.cache,
    this.pageSize = 500,
    this.requestTimeout = const Duration(seconds: 15),
  });

  bool contains(String code) =>
      languages.value?.any((l) => l.code == code) ?? false;
  String name(String code) =>
      languages.value?.where((l) => l.code == code).firstOrNull?.displayName ??
      code;

  Future<void> load() =>
      _pending ??= _load().whenComplete(() => _pending = null);
  Future<void> _load() async {
    loading.value = true;
    loadFailed.value = false;
    if (languages.value == null) {
      try {
        final data = await cache.read();
        if (isDispose) return;
        if (data != null) {
          languages.value = ContentLanguage.parse(data);
          cached.value = true;
        }
      } catch (_) {
        if (!isDispose) cacheWarning.value = true;
      }
    }
    try {
      final rows = <JsonMap>[];
      for (var from = 0; ; from += pageSize) {
        final page = await fetchPage(
          from,
          from + pageSize - 1,
        ).timeout(requestTimeout);
        if (isDispose) return;
        rows.addAll(page);
        if (page.length < pageSize) break;
      }
      final data = <String, dynamic>{'languages': rows};
      languages.value = ContentLanguage.parse(data);
      cached.value = false;
      try {
        await cache.write(data);
        if (!isDispose) cacheWarning.value = false;
      } catch (_) {
        if (!isDispose) cacheWarning.value = true;
      }
    } catch (_) {
      if (!isDispose) {
        loadFailed.value = true;
        cached.value = languages.value != null;
      }
    } finally {
      if (!isDispose) loading.value = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _disposers.cancelAll();
  }
}
