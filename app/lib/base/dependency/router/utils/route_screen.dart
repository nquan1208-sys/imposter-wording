import 'package:flutter/material.dart';
import 'package:untitled/features/how_to_play/how_to_play_screen.dart';
import 'package:untitled/features/landing/landing_screen.dart';
import 'package:untitled/features/unknown/unknown_screen.dart';
import 'package:untitled/features/setup/setup_screen.dart';
import 'package:untitled/features/setup/category_screen.dart';

class RouteScreen {
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
