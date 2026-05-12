import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/base/dependency/router/utils/route_page.dart';
import 'package:untitled/base/rx/obs_builder.dart';
import 'package:untitled/features/root/enums/navigation_bottom_tab_enum.dart';
import 'package:untitled/features/root/widgets/app_bottom_navigation_bar.dart';

class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStore = ref.watch(StoreProvider.app);
    return Scaffold(
      body: Stack(
        children: NavigatorBottomTabEnum.values.map((tab) {
          return ObsBuilder(
            streams: [appStore.selectedBottomTabSubject],
            builder: (ctx) => Offstage(
              offstage: tab != appStore.selectedBottomTabSubject.value,
              child: Navigator(
                key: appStore.navigatorKeysMap[tab],
                onGenerateRoute: buildRouteFactory(tab),
                initialRoute: tab.initialRoute,
              ),
            ),
          );
        }).toList(),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(),
    );
  }

  RouteFactory buildRouteFactory(NavigatorBottomTabEnum tab) {
    switch (tab) {
      case NavigatorBottomTabEnum.home:
        return RoutePage.onGenerateHomeRoute;
      case NavigatorBottomTabEnum.settings:
        return RoutePage.onGenerateSettingsRoute;
    }
  }
}
