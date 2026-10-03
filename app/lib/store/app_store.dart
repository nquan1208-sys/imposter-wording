import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:untitled/base/store/auto_dispose_manager.dart';
import 'package:untitled/base/store/store_base.dart';
import 'package:untitled/base/dependency/app_service.dart';
import 'package:untitled/base/dependency/router/router_service.dart';
import 'package:untitled/features/root/enums/navigation_bottom_tab_enum.dart';

class AppStore extends StoreBase {
  final Ref ref;
  final _autoDisposeManager = AutoDisposeManager();

  late final RouterService routerService = ref.watch(AppService.router);

  late final selectedBottomTab = signal(
    NavigatorBottomTabEnum.home,
  ).manageBy(_autoDisposeManager);

  final navigatorKeysMap = NavigatorBottomTabEnum.values
      .fold<Map<NavigatorBottomTabEnum, GlobalKey<NavigatorState>>>(
    {},
    (previousValue, element) =>
        previousValue..[element] = GlobalKey<NavigatorState>(),
  );

  AppStore(this.ref);

  void onBottomTabChange(NavigatorBottomTabEnum currentTab) {
    selectedBottomTab.value = currentTab;
  }

  @override
  void dispose() {
    _autoDisposeManager.cancelAll();
    super.dispose();
  }
}
