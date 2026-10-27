import 'package:untitled/features/question_game/question_game_store.dart';
import 'package:untitled/features/word_game/word_game_store.dart';
import 'package:untitled/base/dependency/router/utils/route_name.dart';

class RouteInput {
  String routeName;
  Object? arguments;

  RouteInput({required this.routeName, this.arguments});

  RouteInput.howToPlay() : routeName = RouteName.howToPlay;
  RouteInput.playerPresets() : routeName = RouteName.playerPresets;
  RouteInput.playerNames() : routeName = RouteName.playerNames;
  RouteInput.setup() : routeName = RouteName.setup;
  RouteInput.settings() : routeName = RouteName.settings;
  RouteInput.settingsLanguage() : routeName = RouteName.settingsLanguage;
  RouteInput.wordGame(WordGameSession session)
    : routeName = RouteName.wordGame,
      arguments = session;
  RouteInput.questionGame(QuestionGameSession session)
    : routeName = RouteName.questionGame,
      arguments = session;
  RouteInput.categories() : routeName = RouteName.categories;
  RouteInput.customWords({required bool family, String gameType = 'word'})
    : routeName = RouteName.customWords,
      arguments = (family: family, gameType: gameType);
}
