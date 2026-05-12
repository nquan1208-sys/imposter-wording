import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class StoreBase {
  bool isDispose = false;

  void dispose() {
    isDispose = true;
  }
}

Provider<T> createAutoDisposeStore<T extends StoreBase>(
  T Function(Ref ref) storeFunction,
) {
  return Provider.autoDispose<T>((ref) {
    final store = storeFunction(ref);
    ref.onDispose(() {
      store.dispose();
    });
    return store;
  });
}
