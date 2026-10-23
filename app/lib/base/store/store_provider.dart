import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/store/app_store.dart';

class StoreProvider {
  static final app = Provider<AppStore>((ref) {
    final store = AppStore(ref);
    ref.onDispose(store.dispose);
    return store;
  });

  StoreProvider._();
}
