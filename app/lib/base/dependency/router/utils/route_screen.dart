import 'package:untitled/features/player_presets/player_presets_screen.dart';
import 'package:untitled/features/question_game/question_game_screen.dart';
import 'package:untitled/features/question_game/question_game_store.dart';
import 'package:untitled/features/player_names/player_names_screen.dart';
import 'package:untitled/features/word_game/word_game_screen.dart';
import 'package:untitled/features/word_game/word_game_store.dart';
import 'package:flutter/material.dart';
import 'package:untitled/features/how_to_play/how_to_play_screen.dart';
import 'package:untitled/features/landing/landing_screen.dart';
import 'package:untitled/features/unknown/unknown_screen.dart';
import 'package:untitled/features/setup/setup_screen.dart';
import 'package:untitled/features/setup/category_screen.dart';

class RouteScreen {
  static PageRoute questionGamePageRoute(RouteSettings settings) =>
      MaterialPageRoute(
        settings: settings,
        builder: (_) => settings.arguments is QuestionGameSession
            ? QuestionGameScreen(
                session: settings.arguments as QuestionGameSession,
              )
            : const SetupScreen(),
      );
  static PageRoute wordGamePageRoute(RouteSettings settings) =>
      MaterialPageRoute(
        settings: settings,
        builder: (_) => settings.arguments is WordGameSession
            ? WordGameScreen(session: settings.arguments as WordGameSession)
            : const SetupScreen(),
      );
  static PageRoute playerPresetsPageRoute(RouteSettings settings) =>
      MaterialPageRoute(
        settings: settings,
        builder: (_) => const PlayerPresetsScreen(),
      );
  static PageRoute playerNamesPageRoute(RouteSettings settings) =>
      MaterialPageRoute(
        settings: settings,
        builder: (_) => const PlayerNamesScreen(),
      );
  static PageRoute setupPageRoute(RouteSettings settings) => MaterialPageRoute(
    settings: settings,
    builder: (_) => const SetupScreen(),
  );
  static PageRoute categoriesPageRoute(RouteSettings settings) =>
      MaterialPageRoute(
        settings: settings,
        builder: (_) => const CategoryScreen(),
      );
  static PageRoute landingPageRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const LandingScreen(),
    );
  }

  static PageRoute howToPlayPageRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const HowToPlayScreen(),
    );
  }

  static PageRoute unknownPageRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const UnknownScreen(),
    );
  }
}
