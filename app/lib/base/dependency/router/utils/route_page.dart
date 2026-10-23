import 'package:flutter/material.dart';
import 'package:untitled/base/dependency/router/utils/route_screen.dart';

import 'package:untitled/base/dependency/router/utils/route_name.dart';

class RoutePage {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteName.landing:
        return RouteScreen.landingPageRoute(settings);
      case RouteName.howToPlay:
        return RouteScreen.howToPlayPageRoute(settings);
    }
    return RouteScreen.unknownPageRoute(settings);
  }
}
