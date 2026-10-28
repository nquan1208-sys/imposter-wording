import 'dart:convert';
import 'package:untitled/models/custom_question_category.dart';
import 'package:untitled/models/content.dart';
import 'package:untitled/models/custom_word_category.dart';

class SetupPlayer {
  final String id, name;
  const SetupPlayer(this.id, this.name);
  JsonMap toJson() => {'id': id, 'name': name};
}

class PlayerPreset {
  final String id, name;
  final GameSetup setup;
  const PlayerPreset(this.id, this.name, this.setup);
  JsonMap toJson() => {'id': id, 'name': name, ...setup.rosterJson()};
  factory PlayerPreset.fromJson(JsonMap json) {
    if (GameSetup.defaults().rosterJson().keys.any(
      (key) => !json.containsKey(key) || json[key] == null,
    )) {
      throw const FormatException('Incomplete preset');
    }
    return PlayerPreset(
      requiredText(json, 'id'),
      requiredText(json, 'name'),
      GameSetup.fromJson({
        ...json,
        'mode': 'classic',
        'gameType': 'word',
        'categoryIds': <String>[],
        'contentLocale': 'vi',
        'presets': <dynamic>[],
        'activePresetId': null,
        'nextPresetId': 1,
      }),
    );
  }
}

class GameSetup {
  Set<String> get localImageIds => {
    for (final category in customWordCategories) ...category.imageIds.values,
    for (final category in customQuestionCategories)
      for (final pair in category.pairs)
        if (pair.imageId != null) pair.imageId!,
  };
  final List<CustomQuestionCategory> customQuestionCategories;
  final int nextCustomQuestionCategoryId;
  bool get hasCustomContent =>
      customWordCategories.isNotEmpty || customQuestionCategories.isNotEmpty;
  final List<CustomWordCategory> customWordCategories;
  final int nextCustomWordCategoryId;
  final List<PlayerPreset> presets;
  final String? activePresetId;
  final int nextPresetId;
  final String contentLocale;
  final String gameType;
  final List<SetupPlayer> players;
  final int nextPlayerId;
  final bool family, showWordImages;
  final int imposters;
  final bool randomImposters, imposterNotFirst, showCategory, knowEachOther;
  int get maxImposters => (players.length - 1) ~/ 2;
  bool get validRules => imposters >= 1 && imposters <= maxImposters;
  final Set<String> categoryIds;
  const GameSetup({
    this.customQuestionCategories = const [],
    this.nextCustomQuestionCategoryId = 1,
    this.customWordCategories = const [],
    this.nextCustomWordCategoryId = 1,
    this.presets = const [],
    this.activePresetId,
    this.nextPresetId = 1,
    this.contentLocale = 'vi',
    this.gameType = 'word',
    required this.players,
    required this.nextPlayerId,
    this.family = false,
    this.showWordImages = false,
    this.imposters = 1,
    this.randomImposters = false,
    this.imposterNotFirst = false,
    this.showCategory = false,
    this.knowEachOther = false,
    this.categoryIds = const {},
  });
  factory GameSetup.defaults() => GameSetup(
    players: List.generate(
      4,
      (i) => SetupPlayer('player-${i + 1}', 'Player ${i + 1}'),
    ),
    nextPlayerId: 5,
  );
  factory GameSetup.fromJson(JsonMap json) {
    final locale = json['contentLocale'] ?? 'vi';
    if (locale is! String ||
        locale.isEmpty ||
        locale != locale.trim() ||
        !const ['word', 'question'].contains(json['gameType'] ?? 'word') ||
        !const ['classic', 'family'].contains(json['mode'])) {
      throw const FormatException('Unsupported setup');
    }
    final players = (json['players'] as List)
        .map(
          (p) => SetupPlayer(
            requiredText(p as JsonMap, 'id'),
            requiredText(p, 'name'),
          ),
        )
        .toList();
    final ids = (json['categoryIds'] as List).cast<String>().toSet();
    final next = json['nextPlayerId'] as int;
    if (players.length < 3 ||
        players.length > 100 ||
        players.map((p) => p.id).toSet().length != players.length ||
        next < 4 ||
        ids.any((id) => id.trim().isEmpty)) {
      throw const FormatException('Invalid setup');
    }
    for (final player in players) {
      final number = int.tryParse(player.id.replaceFirst('player-', ''));
      if (!RegExp(r'^player-[1-9][0-9]*$').hasMatch(player.id) ||
          number == null ||
          number < 1 ||
          number >= next) {
        throw const FormatException('Invalid player ID');
      }
    }
    final presets =
        (json.containsKey('presets') ? json['presets'] as List : <dynamic>[])
            .map((p) => PlayerPreset.fromJson(p as JsonMap))
            .toList();
    final nextPresetId = json.containsKey('nextPresetId')
        ? json['nextPresetId'] as int
        : 1;
    final activePresetId = json['activePresetId'] as String?;
    if (nextPresetId < 1 ||
        presets.map((p) => p.id).toSet().length != presets.length ||
        presets.map((p) => p.name.trim().toLowerCase()).toSet().length !=
            presets.length ||
        presets.any(
          (p) =>
              !RegExp(r'^preset-[1-9][0-9]*$').hasMatch(p.id) ||
              int.parse(p.id.substring(7)) >= nextPresetId,
        ) ||
        (activePresetId != null &&
            !presets.any((p) => p.id == activePresetId))) {
      throw const FormatException('Invalid presets');
    }
    final setup = GameSetup(
      customQuestionCategories: List.unmodifiable(
        (json['customQuestionCategories'] as List? ?? []).map(
          (c) => CustomQuestionCategory.fromJson(c as JsonMap),
        ),
      ),
      nextCustomQuestionCategoryId:
          json['nextCustomQuestionCategoryId'] as int? ?? 1,
      customWordCategories: List.unmodifiable(
        (json['customWordCategories'] as List? ?? []).map(
          (c) => CustomWordCategory.fromJson(c as JsonMap),
        ),
      ),
      nextCustomWordCategoryId: json['nextCustomWordCategoryId'] as int? ?? 1,
      presets: presets,
      activePresetId: activePresetId,
      nextPresetId: nextPresetId,
      contentLocale: locale,
      gameType: json['gameType'] as String? ?? 'word',
      players: players,
      nextPlayerId: next,
      family:
          (json['gameType'] ?? 'word') == 'word' && json['mode'] == 'family',
      showWordImages: json['showWordImages'] as bool? ?? false,
      categoryIds: ids,
      imposters: json['imposters'] as int,
      randomImposters: json['randomImposters'] as bool? ?? false,
      imposterNotFirst: json['imposterNotFirst'] as bool? ?? false,
      showCategory: json['showCategory'] as bool? ?? false,
      knowEachOther: json['knowEachOther'] as bool? ?? false,
    );
    final questions = setup.customQuestionCategories;
    if (setup.nextCustomQuestionCategoryId < 1 ||
        questions.map((c) => c.id).toSet().length != questions.length ||
        questions
                .map((c) => (c.contentLocale, c.name.toLowerCase()))
                .toSet()
                .length !=
            questions.length ||
        questions.any(
          (c) =>
              int.parse(c.id.substring('custom-question-'.length)) >=
              setup.nextCustomQuestionCategoryId,
        )) {
      throw const FormatException('Invalid custom question categories');
    }
    if (!setup.validRules) throw const FormatException('Invalid rules');
    final custom = setup.customWordCategories;
    if (setup.nextCustomWordCategoryId < 1 ||
        custom.map((c) => c.id).toSet().length != custom.length ||
        custom
                .map((c) => (c.contentLocale, c.name.toLowerCase()))
                .toSet()
                .length !=
            custom.length ||
        custom.any(
          (c) =>
              int.parse(c.id.substring('custom-word-'.length)) >=
              setup.nextCustomWordCategoryId,
        )) {
      throw const FormatException('Invalid custom categories');
    }
    if (activePresetId != null &&
        jsonEncode(setup.rosterJson()) !=
            jsonEncode(
              presets
                  .firstWhere((p) => p.id == activePresetId)
                  .setup
                  .rosterJson(),
            )) {
      throw const FormatException('Active preset differs from setup');
    }
    return setup;
  }
  GameSetup copyWith({
    List<CustomQuestionCategory>? customQuestionCategories,
    int? nextCustomQuestionCategoryId,
    List<CustomWordCategory>? customWordCategories,
    int? nextCustomWordCategoryId,
    List<PlayerPreset>? presets,
    String? activePresetId,
    bool clearActivePreset = false,
    int? nextPresetId,
    String? contentLocale,
    String? gameType,
    List<SetupPlayer>? players,
    int? nextPlayerId,
    bool? family,
    bool? showWordImages,
    int? imposters,
    bool? randomImposters,
    bool? imposterNotFirst,
    bool? showCategory,
    bool? knowEachOther,
    Set<String>? categoryIds,
  }) => GameSetup(
    customQuestionCategories:
        customQuestionCategories ?? this.customQuestionCategories,
    nextCustomQuestionCategoryId:
        nextCustomQuestionCategoryId ?? this.nextCustomQuestionCategoryId,
    customWordCategories: customWordCategories ?? this.customWordCategories,
    nextCustomWordCategoryId:
        nextCustomWordCategoryId ?? this.nextCustomWordCategoryId,
    presets: presets ?? this.presets,
    activePresetId: clearActivePreset
        ? null
        : activePresetId ?? this.activePresetId,
    nextPresetId: nextPresetId ?? this.nextPresetId,
    contentLocale: contentLocale ?? this.contentLocale,
    gameType: gameType ?? this.gameType,
    players: players ?? this.players,
    nextPlayerId: nextPlayerId ?? this.nextPlayerId,
    family: (gameType ?? this.gameType) == 'word' && (family ?? this.family),
    showWordImages: showWordImages ?? this.showWordImages,
    imposters: imposters ?? this.imposters,
    randomImposters: randomImposters ?? this.randomImposters,
    imposterNotFirst: imposterNotFirst ?? this.imposterNotFirst,
    showCategory: showCategory ?? this.showCategory,
    knowEachOther: knowEachOther ?? this.knowEachOther,
    categoryIds: categoryIds ?? this.categoryIds,
  );
  GameSetup withRoster(GameSetup draft) => copyWith(
    players: draft.players
        .map((p) => SetupPlayer(p.id, p.name.trim()))
        .toList(),
    nextPlayerId: draft.nextPlayerId,
    imposters: draft.imposters.clamp(1, draft.maxImposters),
    randomImposters: draft.randomImposters,
    imposterNotFirst: draft.imposterNotFirst,
    showCategory: draft.showCategory,
    knowEachOther: draft.knowEachOther,
  );
  bool get validRoster {
    try {
      GameSetup.fromJson({
        ...rosterJson(),
        'mode': 'classic',
        'gameType': 'word',
        'contentLocale': 'vi',
        'categoryIds': <String>[],
        'presets': <dynamic>[],
        'activePresetId': null,
        'nextPresetId': 1,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  JsonMap rosterJson() => {
    'players': players.map((p) => p.toJson()).toList(),
    'nextPlayerId': nextPlayerId,
    'imposters': imposters,
    'randomImposters': randomImposters,
    'imposterNotFirst': imposterNotFirst,
    'showCategory': showCategory,
    'knowEachOther': knowEachOther,
  };
  JsonMap toJson() => {
    'customQuestionCategories': customQuestionCategories
        .map((c) => c.toJson())
        .toList(),
    'nextCustomQuestionCategoryId': nextCustomQuestionCategoryId,
    'customWordCategories': customWordCategories
        .map((c) => c.toJson())
        .toList(),
    'nextCustomWordCategoryId': nextCustomWordCategoryId,
    'presets': presets.map((p) => p.toJson()).toList(),
    'activePresetId': activePresetId,
    'nextPresetId': nextPresetId,
    ...rosterJson(),
    'mode': family ? 'family' : 'classic',
    'showWordImages': showWordImages,
    'categoryIds': categoryIds.toList(),
    'contentLocale': contentLocale,
    'gameType': gameType,
  };
}
