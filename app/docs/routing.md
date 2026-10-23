# Routing

Navigation uses Flutter's imperative `Navigator` API wrapped in `RouterService`. There is no `go_router` and no bottom-tab shell; `MaterialApp` owns a single navigator stack.

---

## Components

```
base/dependency/router/
  router_provider.dart     # Holds NavigatorKey, implements push/pop
  router_service.dart      # Thin wrapper — inject this in stores/screens
  utils/
    route_name.dart        # String constants for route names
    route_input.dart       # Typed destinations passed to push()
    route_page.dart        # onGenerateRoute
    route_screen.dart      # PageRoute builders per screen
```

Current routes: `RouteName.landing` (initial), `RouteName.howToPlay`, `RouteName.unknown`.

---

## Pushing a Route

```dart
final router = ref.watch(AppService.router);
router.push(RouteInput.howToPlay());
```

Add a named `RouteInput.<feature>()` constructor per destination; never push raw strings from feature code.

---

## Route Generation

`RoutePage.onGenerateRoute` maps names to `RouteScreen` builders. A feature with a store initializes its provider in the builder:

```dart
static PageRoute featurePageRoute(RouteSettings settings) {
  StoreProvider.feature = createAutoDisposeStore((ref) => FeatureStore(ref));
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => const FeatureScreen(),
  );
}
```

Static screens skip the store step (see `howToPlayPageRoute`).

---

## Unknown Route

Unrecognized names fall back to `UnknownScreen` (`lib/features/unknown/unknown_screen.dart`).
