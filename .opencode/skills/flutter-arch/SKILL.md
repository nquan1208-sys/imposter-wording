---
name: Flutter Architecture
description: "Use when the user explicitly invokes @flutter-arch to build or review a feature in this repo's app/lib/features architecture, following the counter feature as the canonical example."
metadata:
  opencode/autoinvoke: false
---

# Flutter Feature Architecture

This skill is opt-in. Do not apply it to Flutter work unless the user explicitly invokes `@flutter-arch`.

Use `app/` as the Flutter package root. The canonical feature is:

```text
app/lib/features/counter/
  counter_screen.dart
  counter_store.dart
```

## Standard feature shape

Start with one screen and one store:

```text
app/lib/features/<feature>/
  <feature>_screen.dart
  <feature>_store.dart
```

Add feature-local `widgets/`, `services/`, or models only when the feature actually needs them. Keep shared code in the existing `app/lib/base`, `app/lib/constants`, `app/lib/providers`, or `app/lib/store` locations, and keep one consistent state-management pattern.

Use the package import name already used by the app:

```dart
import 'package:untitled/...';
```

## Store pattern

Feature state and mutations belong in a `StoreBase` subclass. Use signals for reactive state and register every owned reactive resource with `AutoDisposeManager`.

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

Rules:

- Keep business logic, async work, signal updates, and side effects in the store; keep screens mostly declarative.
- Use `signal`, `computed`, and `effect` from `signals_flutter` as needed.
- Call `.manageBy(_autoDisposeManager)` on every signal, computed value, effect disposer, stream subscription, or `ChangeNotifier` owned by the store.
- Dispose owned child stores before cancelling the manager.
- Use `ref` in the constructor to read injected dependencies such as `AppService`; do not manually construct app-level services at call sites.

## Screen pattern

Screens are normally `ConsumerWidget`s. Read the feature store from `StoreProvider`, and scope `SignalBuilder` to the smallest reactive subtree.

```dart
class FeatureScreen extends ConsumerWidget {
  const FeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(StoreProvider.feature);

    return Scaffold(
      appBar: AppBar(title: const Text('Feature')),
      body: SignalBuilder(
        builder: (context) => Text('${store.count.value}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: store.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- Use `ConsumerStatefulWidget` only when widget lifecycle or a `BuildContext`-dependent reaction is required.
- Read a signal's current value with `.value` inside `SignalBuilder`.
- Do not wrap an entire `Scaffold` in `SignalBuilder` when only a subtree is reactive.
- Use `ref.watch` to obtain a store used by the widget; use `ref.read` for one-off provider access or commands where appropriate.
- Prefer existing shared widgets, constants, `AppEdgeInsets`, and `AppSpacing` over new inline UI primitives or magic spacing values.

## Store registration and lifecycle

Add a screen provider to `app/lib/base/store/store_provider.dart`:

```dart
static late Provider<FeatureStore> feature;
```

Before a feature route is built, assign a fresh auto-dispose provider:

```dart
StoreProvider.feature = createAutoDisposeStore(
  (ref) => FeatureStore(ref),
);
```

`createAutoDisposeStore` calls `dispose()` when the route's provider scope is released. Do not reuse one screen-provider instance across visits. Global stores are different: use a `static final Provider<T>` and call `ref.onDispose(store.dispose)`, following `StoreProvider.app`.

## Routing

Register a stateful feature in the existing router layers:

1. Add a route constant to `app/lib/base/dependency/router/utils/route_name.dart`.
2. Add a typed `RouteInput.<feature>()` constructor in `route_input.dart` when the route needs a convenient destination object.
3. Add `RouteScreen.<feature>PageRoute`, initialize `StoreProvider.<feature>` there, and return the feature screen.
4. Add the route case to the relevant `RoutePage.onGenerate...Route` method.
5. Navigate through `ref.watch(AppService.router)` / `RouterService` with `RouteInput`; do not push raw route strings from feature code.

Follow `counterPageRoute` and `RouteInput.counter()` exactly for the smallest working example. A screen without state may omit the store/provider setup, as the existing `HomeScreen` does.

For a new bottom tab, also update `NavigatorBottomTabEnum`, `RootScreen.buildRouteFactory`, and `AppBottomNavigationBar`.

## App services and localization

- Use `AppService` for app-level dependencies and `ref.watch`/`ref.read` rather than constructing services manually.
- Read localized strings with `ref.watch(AppService.localization)` and use the generated localization API.
- Do not edit generated localization or other generated files.

## Verification

Before handing off a feature:

- Compare its screen/store/provider/route wiring with `app/lib/features/counter` and the existing router files.
- Search for an existing shared widget, service, constant, or provider before adding a new one.
- Run formatting and the narrowest relevant Flutter tests/analyzer from `app/`.
- Confirm store resources are managed and disposal calls both `cancelAll()` and `super.dispose()`.
