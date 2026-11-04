import 'package:flutter/material.dart';
import 'package:untitled/base/dependency/router/utils/route_screen.dart';

import 'package:untitled/base/dependency/router/utils/route_name.dart';

class RoutePage {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteName.splash:
        return RouteScreen.splashPageRoute(settings);
      case RouteName.customWords:
        return RouteScreen.customWordsPageRoute(settings);
      case RouteName.questionGame:
        return RouteScreen.questionGamePageRoute(settings);
      case RouteName.wordGame:
        return RouteScreen.wordGamePageRoute(settings);
      case RouteName.landing:
        return RouteScreen.landingPageRoute(settings);
      case RouteName.howToPlay:
        return RouteScreen.howToPlayPageRoute(settings);
      case RouteName.playerPresets:
        return RouteScreen.playerPresetsPageRoute(settings);
      case RouteName.playerNames:
        return RouteScreen.playerNamesPageRoute(settings);
      case RouteName.setup:
        return RouteScreen.setupPageRoute(settings);
      case RouteName.settings:
        return RouteScreen.settingsPageRoute(settings);
      case RouteName.contentLanguage:
        return RouteScreen.contentLanguagePageRoute(settings);
      case RouteName.categories:
        return RouteScreen.categoriesPageRoute(settings);
    }
    return RouteScreen.unknownPageRoute(settings);
  }
}
