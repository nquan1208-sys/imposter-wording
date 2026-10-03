import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/features/counter/counter_store.dart';
import 'package:untitled/store/app_store.dart';

class StoreProvider {
  static final app = Provider<AppStore>((ref) {
    final store = AppStore(ref);
    ref.onDispose(store.dispose);
    return store;
  });

  static late Provider<CounterStore> counter;

  StoreProvider._();
}
