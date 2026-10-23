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

Mutations are public methods on the store. No `setState`, `notifyListeners` or `emit`.

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
