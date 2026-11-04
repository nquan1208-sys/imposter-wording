import 'dart:convert';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/base/store/auto_dispose_manager.dart';
import 'package:untitled/base/store/store_base.dart';
import 'package:untitled/data/local_json_store.dart';
import 'package:untitled/data/word_image_cache.dart';
import 'package:untitled/models/content.dart';

typedef FetchContentPage =
    Future<List<JsonMap>> Function(
      String table,
      String locale,
      int from,
      int to,
    );

class SupabaseContentSource {
  final SupabaseClient client;
  SupabaseContentSource(this.client);
  Future<List<JsonMap>> fetch(
    String table,
    String locale,
    int from,
    int to,
  ) async {
    final category = table == 'game_categories';
    final translations = category
        ? 'game_category_translations'
        : table == 'word_prompts'
        ? 'word_prompt_translations'
        : 'question_prompt_translations';
    final columns = category
        ? 'id,game_type,slug,sort_order,is_active,is_family_friendly,t:$translations!inner(category_id,locale,name,description,status)'
        : 'id,category_id,difficulty,${table == 'word_prompts' ? 'image_path,' : ''}t:$translations!inner(prompt_id,locale,status,${table == 'word_prompts' ? 'text' : 'civilian_question,imposter_question'}),c:game_categories!inner(id,is_active,t:game_category_translations!inner(locale,status))';
    var query = client
        .from(table)
        .select(columns)
        .eq('t.locale', locale)
        .eq('t.status', 'published');
    if (category) {
      query = query.eq('is_active', true);
    } else {
      query = query
          .eq('c.is_active', true)
          .eq('c.t.locale', locale)
          .eq('c.t.status', 'published');
    }
    return await query.order('id', ascending: true).range(from, to);
  }
}

class ContentRepository extends StoreBase {
  final FetchContentPage fetchPage;
  final LocalJsonStore cache;
  final String contentLocale;
  final int pageSize;
  final Duration requestTimeout;
  final WordImageCache? images;
  final _disposers = AutoDisposeManager();
  late final snapshot = signal<ContentSnapshot?>(null).manageBy(_disposers);
  late final loading = signal(false).manageBy(_disposers);
  late final loadFailed = signal(false).manageBy(_disposers);
  late final cacheWarning = signal(false).manageBy(_disposers);
  late final cached = signal(false).manageBy(_disposers);
  Future<void>? _pending;
  bool _readCache = false;
  ContentRepository({
    required this.fetchPage,
    required this.cache,
    this.contentLocale = 'vi',
    this.pageSize = 500,
    this.requestTimeout = const Duration(seconds: 15),
    this.images,
  });
  Future<void> load() =>
      _pending ??= _load().whenComplete(() => _pending = null);
  Future<void> _load() async {
    var imagesStarted = false;
    void refreshImages() {
      final current = snapshot.value;
      if (current != null) {
        images?.refresh(current, retryFailures: !imagesStarted);
        imagesStarted = true;
      }
    }

    refreshImages();
    loading.value = true;
    loadFailed.value = false;
    if (!_readCache && snapshot.value == null) {
      try {
        final data = await cache.read();
        if (isDispose) return;
        if (data != null) {
          snapshot.value = ContentSnapshot.fromJson(data, contentLocale);
          cached.value = true;
          refreshImages();
        }
        _readCache = true;
        cacheWarning.value = false;
      } catch (_) {
        if (!isDispose) cacheWarning.value = true;
      }
    }
    try {
      final data = <String, dynamic>{};
      for (final entry in {
        'categories': 'game_categories',
        'words': 'word_prompts',
        'questions': 'question_prompts',
      }.entries) {
        final rows = <String, JsonMap>{};
        for (var from = 0; ; from += pageSize) {
          final page = await fetchPage(
            entry.value,
            contentLocale,
            from,
            from + pageSize - 1,
          ).timeout(requestTimeout);
          if (isDispose) return;
          for (final row in page) {
            final id = requiredText(row, 'id');
            // Validate repeated rows too; malformed duplicates must fail the load.
            switch (entry.key) {
              case 'categories':
                ContentCategory(row, contentLocale);
              case 'words':
                WordPrompt(row, contentLocale);
              case 'questions':
                QuestionPair(row, contentLocale);
            }
            if (rows.containsKey(id) &&
                jsonEncode(rows[id]) != jsonEncode(row)) {
              throw const FormatException('Conflicting duplicate ID');
            }
            rows.putIfAbsent(id, () => row);
          }
          if (page.length < pageSize) break;
        }
        data[entry.key] = rows.values.toList();
      }
      final complete = ContentSnapshot.fromJson(data, contentLocale);
      if (isDispose) return;
      snapshot.value = complete;
      refreshImages();
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
        cached.value = snapshot.value != null;
      }
    } finally {
      if (!isDispose) {
        loading.value = false;
        refreshImages();
      }
    }
  }

  List<WordPrompt> eligibleWords({
    required bool family,
    Set<String> categoryIds = const {},
  }) {
    final familyCategories =
        snapshot.value?.categories
            .where((c) => c.isFamilyFriendly)
            .map((c) => c.id)
            .toSet() ??
        <String>{};
    return snapshot.value?.words
            .where(
              (w) =>
                  (!family || familyCategories.contains(w.categoryId)) &&
                  (categoryIds.isEmpty || categoryIds.contains(w.categoryId)),
            )
            .toList() ??
        [];
  }

  List<QuestionPair> eligibleQuestions({
    required bool family,
    Set<String> categoryIds = const {},
  }) {
    final familyCategories =
        snapshot.value?.categories
            .where((c) => c.gameType == 'question' && c.isFamilyFriendly)
            .map((c) => c.id)
            .toSet() ??
        <String>{};
    return snapshot.value?.questions
            .where(
              (q) =>
                  (!family || familyCategories.contains(q.categoryId)) &&
                  (categoryIds.isEmpty || categoryIds.contains(q.categoryId)),
            )
            .toList() ??
        [];
  }

  Map<ContentCategory, int> categoryCounts({
    required bool family,
    String gameType = 'word',
  }) {
    final counts = <String, int>{};
    final ids = gameType == 'question'
        ? eligibleQuestions(family: family).map((q) => q.categoryId)
        : eligibleWords(family: family).map((w) => w.categoryId);
    for (final id in ids) {
      counts.update(id, (n) => n + 1, ifAbsent: () => 1);
    }
    final categories =
        snapshot.value?.categories
            .where((c) => counts.containsKey(c.id))
            .toList() ??
        [];
    categories.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
    return {for (final c in categories) c: counts[c.id]!};
  }

  @override
  void dispose() {
    super.dispose();
    _disposers.cancelAll();
  }
}
