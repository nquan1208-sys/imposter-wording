import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:untitled/base/store/store_base.dart';
import 'package:untitled/base/store/stream_subscription_manager.dart';
import 'package:untitled/base/dependency/app_service.dart';
import 'package:untitled/base/dependency/router/router_service.dart';
import 'package:untitled/features/root/enums/navigation_bottom_tab_enum.dart';

class AppStore extends StoreBase {
  final Ref ref;
  final _subscriptionManager = StreamSubscriptionManager();

  late final RouterService routerService = ref.watch(AppService.router);

  late final selectedBottomTabSubject =
      BehaviorSubject<NavigatorBottomTabEnum>.seeded(
    NavigatorBottomTabEnum.home,
  ).manageBy(_subscriptionManager);

  final navigatorKeysMap = NavigatorBottomTabEnum.values
      .fold<Map<NavigatorBottomTabEnum, GlobalKey<NavigatorState>>>(
    {},
    (previousValue, element) =>
        previousValue..[element] = GlobalKey<NavigatorState>(),
  );

  AppStore(this.ref);

  void onBottomTabChange(NavigatorBottomTabEnum currentTab) {
    selectedBottomTabSubject.value = currentTab;
  }

  @override
  void dispose() {
    _subscriptionManager.cancelAll();
    super.dispose();
  }
}
