import 'package:untitled/data/local_image_store.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/store/auto_dispose_manager.dart';
import 'package:untitled/base/store/store_base.dart';
import 'package:untitled/data/content_repository.dart';
import 'package:untitled/data/local_json_store.dart';
import 'package:untitled/models/game_setup.dart';
import 'package:untitled/models/content.dart';
import 'package:untitled/models/custom_word_category.dart';
import 'package:untitled/models/custom_question_category.dart';

class SetupStore extends StoreBase {
  final ContentRepository content;
  final LocalJsonStore file;
  final LocalImageStore? images;
  final _disposers = AutoDisposeManager();
  late final setup = signal(GameSetup.defaults()).manageBy(_disposers);
  late final reading = signal(true).manageBy(_disposers);
  late final readFailed = signal(false).manageBy(_disposers);
  late final writeFailed = signal(false).manageBy(_disposers);
  late final selectionRemoved = signal(false).manageBy(_disposers);
  Future<void> _writes = Future.value();
  Future<void>? _read;
  Future<void> get pendingWrites => _writes;
  bool get editable => !reading.value && !readFailed.value && !writing.value;
  final _availableCategories = <(String, bool), Set<String>>{};
  ContentSnapshot? _remoteSnapshot;

  SetupStore({required this.content, required this.file, this.images}) {
    effect(() {
      final snapshot = content.snapshot.value;
      _remoteSnapshot = snapshot;
      _availableCategories.clear();
      if (snapshot != null) {
        for (final gameType in ['word', 'question']) {
          for (final family in [false, true]) {
            _availableCategories[(gameType, family)] = content
                .categoryCounts(family: family, gameType: gameType)
                .keys
                .map((c) => c.id)
                .toSet();
          }
        }
      }
      final ready = !reading.value && !readFailed.value;
      if (snapshot != null && ready) untracked(revalidate);
    }).manageBy(_disposers);
  }

  Future<void> restore() =>
      _read ??= _restore().whenComplete(() => _read = null);
  Future<void> _restore() async {
    reading.value = true;
    await _writes;
    if (isDispose) return;
    try {
      final data = await file.read();
      if (isDispose) return;
      _committed = data == null
          ? GameSetup.defaults()
          : GameSetup.fromJson(data);
      setup.value = _committed;
      readFailed.value = false;
    } catch (_) {
      if (!isDispose) readFailed.value = true;
    } finally {
      if (!isDispose) reading.value = false;
    }
    await _writes;
  }

  GameSetup _committed = GameSetup.defaults();
  int _queued = 0;
  late final writing = signal(false).manageBy(_disposers);
  GameSetup Function(GameSetup)? _retry;

  Future<bool> _mutate(
    GameSetup Function(GameSetup) change, {
    bool retryable = false,
    bool skipUnchanged = false,
    Iterable<String> pinnedImages = const [],
  }) {
    if (isDispose || reading.value || readFailed.value) {
      return Future.value(false);
    }
    final imageOwner = Object();
    images?.retain(imageOwner, pinnedImages.where(validLocalImageId));
    _queued++;
    writing.value = true;
    final result = _writes.then((_) async {
      var validated = false;
      try {
        final value = _validatedCategories(change(_committed));
        if (skipUnchanged && identical(value, _committed)) return true;
        GameSetup.fromJson(value.toJson());
        images?.retain(imageOwner, value.localImageIds);
        validated = true;
        if (images == null) {
          await file.write(value.toJson());
        } else {
          await images!.persist(() => file.write(value.toJson()));
        }
        _committed = value;
        if (!isDispose) {
          setup.value = value;
          writeFailed.value = false;
          _retry = null;
        }
        return true;
      } catch (_) {
        if (!isDispose) {
          if (retryable && validated) {
            writeFailed.value = true;
            _retry = change;
          }
        }
        return false;
      } finally {
        images?.release(imageOwner);
        _queued--;
        if (!isDispose) writing.value = _queued != 0;
      }
    });
    _writes = result.then((_) {});
    return result;
  }

  Future<bool> save() async {
    await pendingWrites;
    if (isDispose || reading.value || readFailed.value) return false;
    final retry = _retry;
    return retry == null ? !writeFailed.value : _mutate(retry, retryable: true);
  }

  Future<bool> setPlayerCount(int count) => _mutate((current) {
    if (count < 3 || count > 100) throw const FormatException('Invalid count');
    var next = current.nextPlayerId;
    final players = current.players.take(count).toList();
    while (players.length < count) {
      var number = 1;
      while (players.any((p) => p.name == 'Player $number')) {
        number++;
      }
      players.add(SetupPlayer('player-${next++}', 'Player $number'));
    }
    return _updateActive(
      current.copyWith(
        players: players,
        nextPlayerId: next,
        imposters: current.imposters.clamp(1, (players.length - 1) ~/ 2),
      ),
    );
  }, retryable: true);

  Future<bool> setRoster(List<SetupPlayer> players, int nextPlayerId) {
    final roster = List<SetupPlayer>.of(players);
    if (roster.length < 3 || roster.length > 100) return Future.value(false);
    return _mutate((current) {
      final draft = current.copyWith(
        players: roster,
        nextPlayerId: nextPlayerId,
        imposters: current.imposters.clamp(1, (roster.length - 1) ~/ 2),
      );
      if (!draft.validRoster) throw const FormatException('Invalid roster');
      return _updateActive(current.withRoster(draft));
    });
  }

  Future<bool> confirmDraft(GameSetup draft, String? presetId) =>
      _mutate((current) {
        if (!draft.validRoster) throw const FormatException('Invalid roster');
        final exists = current.presets.any((p) => p.id == presetId);
        return _updateActive(
          current
              .withRoster(draft)
              .copyWith(
                activePresetId: exists ? presetId : null,
                clearActivePreset: !exists,
              ),
        );
      });

  GameSetup _updateActive(GameSetup current) => current.copyWith(
    presets: current.presets
        .map(
          (p) => p.id == current.activePresetId
              ? PlayerPreset(
                  p.id,
                  p.name,
                  GameSetup.defaults().withRoster(current),
                )
              : p,
        )
        .toList(),
  );

  Future<bool> setRules({
    int? imposters,
    bool? randomImposters,
    bool? imposterNotFirst,
    bool? showCategory,
    bool? knowEachOther,
  }) => _mutate(
    (current) => _updateActive(
      current.copyWith(
        imposters: imposters,
        randomImposters: randomImposters,
        imposterNotFirst: imposterNotFirst,
        showCategory: showCategory,
        knowEachOther: knowEachOther,
      ),
    ),
    retryable: true,
  );

  Future<bool> setFamily(bool family) =>
      _mutate((s) => s.copyWith(family: family), retryable: true);
  Future<bool> setShowWordImages(bool show) =>
      _mutate((s) => s.copyWith(showWordImages: show), retryable: true);
  Future<bool> setGameType(String type) =>
      _mutate((s) => s.copyWith(gameType: type), retryable: true);
  Future<bool> setCategories(
    Set<String> ids, {
    bool? family,
    bool? showWordImages,
  }) {
    final selected = Set<String>.of(ids);
    // Retry stays in the picker so leaving it discards a failed draft.
    return _mutate(
      (s) => s.copyWith(
        categoryIds: selected,
        family: family,
        showWordImages: showWordImages,
      ),
    );
  }

  bool validPresetName(String name, {String? exceptId}) =>
      name.trim().isNotEmpty &&
      !setup.value.presets.any(
        (p) =>
            p.id != exceptId &&
            p.name.trim().toLowerCase() == name.trim().toLowerCase(),
      );

  Future<String?> createPreset(String name, GameSetup draft) async {
    String? id;
    final success = await _mutate((current) {
      if (!draft.validRoster ||
          name.trim().isEmpty ||
          current.presets.any(
            (p) => p.name.toLowerCase() == name.trim().toLowerCase(),
          )) {
        throw const FormatException('Invalid preset');
      }
      id = 'preset-${current.nextPresetId}';
      return current.copyWith(
        nextPresetId: current.nextPresetId + 1,
        presets: [
          ...current.presets,
          PlayerPreset(
            id!,
            name.trim(),
            GameSetup.defaults().withRoster(draft),
          ),
        ],
      );
    });
    return success ? id : null;
  }

  Future<bool> renamePreset(String id, String name) => _mutate((current) {
    if (name.trim().isEmpty ||
        !current.presets.any((p) => p.id == id) ||
        current.presets.any(
          (p) =>
              p.id != id && p.name.toLowerCase() == name.trim().toLowerCase(),
        )) {
      throw const FormatException('Invalid preset name');
    }
    return current.copyWith(
      presets: current.presets
          .map((p) => p.id == id ? PlayerPreset(id, name.trim(), p.setup) : p)
          .toList(),
    );
  });

  Future<bool> deletePreset(String id) => _mutate(
    (current) => current.copyWith(
      presets: current.presets.where((p) => p.id != id).toList(),
      clearActivePreset: current.activePresetId == id,
    ),
  );

  GameSetup _validatedCategories(GameSetup current) {
    // Queued writes can finish after the content signals have been disposed.
    final remote = _availableCategories[(current.gameType, current.family)];
    final available = {
      ...?remote,
      if (current.gameType == 'question')
        for (final c in _customQuestions(current)) c.id,
      if (current.gameType == 'word')
        for (final c in _custom(current))
          if (!current.family || c.isFamilyFriendly) c.id,
    };
    final retained = current.categoryIds
        .where(
          (id) =>
              available.contains(id) ||
              (remote == null &&
                  !id.startsWith('custom-word-') &&
                  !id.startsWith('custom-question-')),
        )
        .toSet();
    if (retained.length == current.categoryIds.length) return current;
    if (!isDispose) selectionRemoved.value = true;
    return current.copyWith(categoryIds: retained);
  }

  Future<bool> revalidate() =>
      _mutate((current) => current, skipUnchanged: true, retryable: true);

  List<CustomWordCategory> _custom(GameSetup current) => current
      .customWordCategories
      .where((c) => c.contentLocale == content.contentLocale)
      .toList();

  List<CustomQuestionCategory> _customQuestions(GameSetup current) => current
      .customQuestionCategories
      .where((c) => c.contentLocale == content.contentLocale)
      .toList();

  List<QuestionPair> eligibleQuestions({Set<String> categoryIds = const {}}) =>
      [
        ...content.eligibleQuestions(categoryIds: categoryIds),
        for (final c in _customQuestions(setup.value))
          if (categoryIds.isEmpty || categoryIds.contains(c.id)) ...c.prompts,
      ];

  List<ContentCategory> get categories => [
    ..._customQuestions(setup.value).map((c) => c.category),
    ...?content.snapshot.value?.categories,
    ..._custom(setup.value).map((c) => c.category),
  ];

  List<WordPrompt> eligibleWords({
    required bool family,
    Set<String> categoryIds = const {},
  }) => [
    ...content.eligibleWords(family: family, categoryIds: categoryIds),
    for (final c in _custom(setup.value))
      if ((!family || c.isFamilyFriendly) &&
          (categoryIds.isEmpty || categoryIds.contains(c.id)))
        ...c.prompts,
  ];

  Map<ContentCategory, int> categoryCounts({
    required bool family,
    String gameType = 'word',
  }) => {
    ...content.categoryCounts(family: family, gameType: gameType),
    if (gameType == 'question')
      for (final c in _customQuestions(setup.value)) c.category: c.pairs.length,
    if (gameType == 'word')
      for (final c in _custom(setup.value))
        if (!family || c.isFamilyFriendly) c.category: c.words.length,
  };

  bool categoryHasImages(String id) =>
      setup.value.customWordCategories.any(
        (c) => c.id == id && c.imageIds.isNotEmpty,
      ) ||
      setup.value.customQuestionCategories.any(
        (c) => c.id == id && c.pairs.any((p) => p.imageId != null),
      );

  bool validCustomCategoryName(
    String name, {
    GameSetup? candidate,
    String gameType = 'word',
  }) {
    final normalized = name.trim().toLowerCase();
    final current = candidate ?? setup.value;
    final catalog = [
      ...?_remoteSnapshot?.categories,
      ..._custom(current).map((c) => c.category),
      ..._customQuestions(current).map((c) => c.category),
    ];
    return normalized.isNotEmpty &&
        !catalog.any(
          (c) =>
              c.gameType == gameType &&
              c.contentLocale == content.contentLocale &&
              c.name.trim().toLowerCase() == normalized,
        );
  }

  Future<String?> createCustomQuestionCategory(
    String name,
    List<CustomQuestionEntry> pairs,
  ) async {
    final entries = List<CustomQuestionEntry>.of(pairs);
    String? id;
    final saved = await _mutate((current) {
      if (current.gameType != 'question' ||
          !validCustomCategoryName(
            name,
            candidate: current,
            gameType: 'question',
          )) {
        throw const FormatException('Invalid custom category');
      }
      var next = current.nextCustomQuestionCategoryId;
      do {
        id = 'custom-question-${next++}';
      } while (current.customQuestionCategories.any((c) => c.id == id) ||
          (_remoteSnapshot?.categories ?? <ContentCategory>[]).any(
            (c) => c.id == id,
          ) ||
          (_remoteSnapshot?.questions ?? <QuestionPair>[]).any(
            (q) => q.id.startsWith('$id-pair-'),
          ));
      return current.copyWith(
        nextCustomQuestionCategoryId: next,
        customQuestionCategories: List.unmodifiable([
          ...current.customQuestionCategories,
          CustomQuestionCategory(
            id: id!,
            name: name.trim(),
            contentLocale: content.contentLocale,
            pairs: entries,
          ),
        ]),
      );
    }, pinnedImages: entries.map((p) => p.imageId).whereType<String>());
    return saved ? id : null;
  }

  Future<String?> createCustomWordCategory(
    String name,
    List<String> words, {
    required bool family,
    Map<String, String> imageIds = const {},
  }) async {
    final attachments = Map<String, String>.of(imageIds);
    final entries = uniqueWords(words);
    String? id;
    final saved = await _mutate((current) {
      if (current.gameType != 'word' ||
          entries.isEmpty ||
          !validCustomCategoryName(name, candidate: current)) {
        throw const FormatException('Invalid custom category');
      }
      var next = current.nextCustomWordCategoryId;
      do {
        id = 'custom-word-${next++}';
      } while (current.customWordCategories.any((c) => c.id == id) ||
          (_remoteSnapshot?.categories ?? <ContentCategory>[]).any(
            (c) => c.id == id,
          ) ||
          (_remoteSnapshot?.words ?? <WordPrompt>[]).any(
            (w) => w.id.startsWith('$id-word-'),
          ));
      return current.copyWith(
        nextCustomWordCategoryId: next,
        customWordCategories: List.unmodifiable([
          ...current.customWordCategories,
          CustomWordCategory(
            id: id!,
            name: name.trim(),
            contentLocale: content.contentLocale,
            isFamilyFriendly: family,
            words: entries,
            imageIds: attachments,
          ),
        ]),
      );
    }, pinnedImages: attachments.values);
    return saved ? id : null;
  }

  Future<bool> clearCustomCategories() => _mutate(
    (current) => current.copyWith(
      customWordCategories: const [],
      customQuestionCategories: const [],
      categoryIds: current.categoryIds
          .where(
            (id) =>
                !current.customWordCategories.any((c) => c.id == id) &&
                !current.customQuestionCategories.any((c) => c.id == id),
          )
          .toSet(),
    ),
  );

  @override
  void dispose() {
    super.dispose();
    _disposers.cancelAll();
  }
}
