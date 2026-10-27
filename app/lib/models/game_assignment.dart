import 'dart:math';
import 'package:untitled/models/game_setup.dart';

class GameAssignment {
  final GameSetup setup;
  final Set<String> imposterIds;
  final String startingPlayerId;

  GameAssignment._(this.setup, this.imposterIds, this.startingPlayerId);

  static bool validSetup(GameSetup setup) =>
      setup.validRules &&
      setup.players.length >= 3 &&
      setup.players.length <= 100 &&
      setup.players.map((p) => p.id).toSet().length == setup.players.length &&
      setup.players.every((p) => p.id.isNotEmpty && p.name.trim().isNotEmpty);

  static GameAssignment create(GameSetup setup, Random random) {
    final players = setup.players;
    final startingPlayerId = players[random.nextInt(players.length)].id;
    final count = setup.randomImposters
        ? 1 + random.nextInt(setup.maxImposters)
        : setup.imposters;
    final candidates =
        players
            .where((p) => !setup.imposterNotFirst || p.id != startingPlayerId)
            .toList()
          ..shuffle(random);
    return GameAssignment._(
      setup.copyWith(
        players: List.unmodifiable(players),
        categoryIds: Set.unmodifiable(setup.categoryIds),
      ),
      Set.unmodifiable(candidates.take(count).map((p) => p.id)),
      startingPlayerId,
    );
  }
}
