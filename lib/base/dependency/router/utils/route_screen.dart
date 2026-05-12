import 'package:flutter/material.dart';
import 'package:untitled/base/store/store_base.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/features/counter/counter_store.dart';
import 'package:untitled/features/counter/counter_screen.dart';
import 'package:untitled/features/home/home_screen.dart';
import 'package:untitled/features/root/root_screen.dart';
import 'package:untitled/features/settings/settings_screen.dart';
import 'package:untitled/features/unknown/unknown_screen.dart';

class RouteScreen {
  static PageRoute rootPageRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const RootScreen(),
    );
  }

  static PageRoute counterPageRoute(RouteSettings settings) {
    StoreProvider.counter = createAutoDisposeStore(
      (ref) => CounterStore(ref),
    );
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const CounterScreen(),
    );
  }

  static PageRoute unknownPageRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const UnknownScreen(),
    );
  }

  static PageRoute homePageRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const HomeScreen(),
    );
  }

  static PageRoute settingPageRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const SettingsScreen(),
    );
  }
}
