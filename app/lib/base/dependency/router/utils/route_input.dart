import 'package:untitled/features/word_game/word_game_store.dart';
import 'package:untitled/base/dependency/router/utils/route_name.dart';

class RouteInput {
  String routeName;
  Object? arguments;

  RouteInput({required this.routeName, this.arguments});

  RouteInput.howToPlay() : routeName = RouteName.howToPlay;
  RouteInput.playerNames() : routeName = RouteName.playerNames;
  RouteInput.setup() : routeName = RouteName.setup;
  RouteInput.wordGame(WordGameSession session)
    : routeName = RouteName.wordGame,
      arguments = session;
  RouteInput.categories() : routeName = RouteName.categories;
}
