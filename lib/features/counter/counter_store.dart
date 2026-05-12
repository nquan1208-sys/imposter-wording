import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:untitled/base/store/store_base.dart';
import 'package:untitled/base/store/stream_subscription_manager.dart';

class CounterStore extends StoreBase {
  final _subscriptionManager = StreamSubscriptionManager();

  late final counterSubject =
      BehaviorSubject<int>.seeded(0).manageBy(_subscriptionManager);

  CounterStore(Ref ref);

  void increment() {
    counterSubject.value++;
  }

  @override
  void dispose() {
    _subscriptionManager.cancelAll();
    super.dispose();
  }
}
