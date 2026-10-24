import 'package:untitled/base/dependency/router/utils/route_name.dart';

class RouteInput {
  String routeName;
  Object? arguments;

  RouteInput({required this.routeName, this.arguments});

  RouteInput.howToPlay() : routeName = RouteName.howToPlay;
  RouteInput.setup() : routeName = RouteName.setup;
  RouteInput.categories() : routeName = RouteName.categories;
}
