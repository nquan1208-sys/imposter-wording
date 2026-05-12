import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/base/store/store_provider.dart';
import 'package:untitled/base/dependency/router/router_provider.dart';
import 'package:untitled/base/dependency/router/router_service.dart';
import 'package:untitled/features/root/enums/navigation_bottom_tab_enum.dart';

final _bottomNavigationRouterFamily =
    Provider.autoDispose.family((ref, NavigatorBottomTabEnum tab) {
  final appStore = ref.watch(StoreProvider.app);
  final navigatorKey = appStore.navigatorKeysMap[tab];
  return RouterService(routerProvider: RouterProvider(key: navigatorKey));
});

class BottomNavigationProvider {
  static final home =
      _bottomNavigationRouterFamily(NavigatorBottomTabEnum.home);
  static final settings =
      _bottomNavigationRouterFamily(NavigatorBottomTabEnum.settings);

  BottomNavigationProvider._();
}
