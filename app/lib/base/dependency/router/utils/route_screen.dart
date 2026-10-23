import 'package:flutter/material.dart';
import 'package:untitled/features/how_to_play/how_to_play_screen.dart';
import 'package:untitled/features/landing/landing_screen.dart';
import 'package:untitled/features/unknown/unknown_screen.dart';

class RouteScreen {
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
