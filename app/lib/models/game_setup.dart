import 'package:untitled/models/content.dart';

class SetupPlayer {
  final String id, name;
  const SetupPlayer(this.id, this.name);
  JsonMap toJson() => {'id': id, 'name': name};
}

class GameSetup {
  final List<SetupPlayer> players;
  final int nextPlayerId;
  final bool family;
  final int imposters;
  final bool randomImposters, imposterNotFirst, showCategory, knowEachOther;
  int get maxImposters => (players.length - 1) ~/ 2;
  bool get validRules => imposters >= 1 && imposters <= maxImposters;
  final Set<String> categoryIds;
  const GameSetup({
    required this.players,
    required this.nextPlayerId,
    this.family = false,
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
    if (json['contentLocale'] != 'vi' ||
        json['gameType'] != 'word' ||
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
        next < 5 ||
        ids.any((id) => id.trim().isEmpty)) {
      throw const FormatException('Invalid setup');
    }
    for (final player in players) {
      final number = int.tryParse(player.id.replaceFirst('player-', ''));
      if (!player.id.startsWith('player-') ||
          number == null ||
          number < 1 ||
          number >= next) {
        throw const FormatException('Invalid player ID');
      }
    }
    final setup = GameSetup(
      players: players,
      nextPlayerId: next,
      family: json['mode'] == 'family',
      categoryIds: ids,
      imposters: json['imposters'] as int,
      randomImposters: json['randomImposters'] as bool? ?? false,
      imposterNotFirst: json['imposterNotFirst'] as bool? ?? false,
      showCategory: json['showCategory'] as bool? ?? false,
      knowEachOther: json['knowEachOther'] as bool? ?? false,
    );
    if (!setup.validRules) throw const FormatException('Invalid rules');
    return setup;
  }
  GameSetup copyWith({
    List<SetupPlayer>? players,
    int? nextPlayerId,
    bool? family,
    int? imposters,
    bool? randomImposters,
    bool? imposterNotFirst,
    bool? showCategory,
    bool? knowEachOther,
    Set<String>? categoryIds,
  }) => GameSetup(
    players: players ?? this.players,
    nextPlayerId: nextPlayerId ?? this.nextPlayerId,
    family: family ?? this.family,
    imposters: imposters ?? this.imposters,
    randomImposters: randomImposters ?? this.randomImposters,
    imposterNotFirst: imposterNotFirst ?? this.imposterNotFirst,
    showCategory: showCategory ?? this.showCategory,
    knowEachOther: knowEachOther ?? this.knowEachOther,
    categoryIds: categoryIds ?? this.categoryIds,
  );
  JsonMap toJson() => {
    'players': players.map((p) => p.toJson()).toList(),
    'nextPlayerId': nextPlayerId,
    'mode': family ? 'family' : 'classic',
    'categoryIds': categoryIds.toList(),
    'contentLocale': 'vi',
    'gameType': 'word',
    'imposters': imposters,
    'randomImposters': randomImposters,
    'imposterNotFirst': imposterNotFirst,
    'showCategory': showCategory,
    'knowEachOther': knowEachOther,
  };
}
