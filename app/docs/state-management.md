# State Management

State is held in **signals** (`signals_flutter`) on **store** classes. Riverpod provides stores and services; it does not hold state directly.

---

## StoreBase

Every store extends `StoreBase` (`lib/base/store/store_base.dart`), which provides an `isDispose` flag and `dispose()`.

Each store owns an `AutoDisposeManager`. Register every signal, computed, effect disposer or subscription with `.manageBy(_autoDisposeManager)` and call `cancelAll()` in `dispose()`:

```dart
class FeatureStore extends StoreBase {
  final _autoDisposeManager = AutoDisposeManager();

  late final count = signal(0).manageBy(_autoDisposeManager);

  FeatureStore(Ref ref);

  void increment() {
    count.value++;
  }

  @override
  void dispose() {
    _autoDisposeManager.cancelAll();
    super.dispose();
  }
}
```

Committed mutations are public methods on the store. Route-local drafts (the
category picker and player-count sheet) use `setState` and commit only on Confirm.

---

## UI binding

Wrap the smallest reactive subtree in `SignalBuilder` and read `.value` inside it:

```dart
final store = ref.watch(StoreProvider.feature);
SignalBuilder(builder: (context) => Text('${store.count.value}'));
```

---

## Lifetime

- Feature stores: `static late Provider<FeatureStore> feature;` on `StoreProvider`, assigned with `createAutoDisposeStore` in the route builder, disposed when the route's scope is released.
- Global store: `StoreProvider.app` (`AppStore`) is `static final` and lives for the app. It owns `locale` (default `vi`, `setLocale`). Persisting the locale is planned for phase 11.
- `contentRepositoryProvider` and `setupStoreProvider` in `data/game_providers.dart`
  are app-lifetime providers. The repository owns content/loading/cache signals;
  the setup store owns committed setup and persistence errors. Its managed effect
  revalidates selected IDs when content changes or settings restoration finishes.
  Settings read errors block mutations until retry or confirmed reset. Writes are
  serialized and preserve the visible setup on failure.

---

## Pattern Summary

| Concern | Solution |
|---|---|
| State storage | `signal` / `computed` on a store |
| State mutation | Public methods on the store |
| UI reactivity | `SignalBuilder` |
| Store lifetime | `createAutoDisposeStore` + `AutoDisposeManager` |
| Accessing stores | `ref.watch(StoreProvider.x)` in `ConsumerWidget` |
| Global state | `AppStore` in `lib/store/` |
