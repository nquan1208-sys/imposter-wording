# Routing

Navigation uses Flutter's imperative `Navigator` API wrapped in a service layer. There is no `go_router` or `Navigator 2.0` — routes are pushed/popped programmatically through `RouterService`.

---

## Components

```
base/dependency/router/
  router_provider.dart     # Holds NavigatorKey, implements push/pop
  router_service.dart      # Thin wrapper — inject this in blocs/services
  utils/
    route_name.dart        # String constants for all route names
    route_page.dart        # onGenerateRoute factories per tab
    route_screen.dart      # PageRoute builders per screen
    route_input.dart       # Input objects passed to push()
```

---

## Route Names

All route name strings are constants on `RouteName` (`lib/base/dependency/router/utils/route_name.dart`):

```dart
RouteName.root
RouteName.home
RouteName.counter
RouteName.settings
RouteName.unknown
RouteName.login
RouteName.location
RouteName.notification
```

Always use these constants — never hardcode strings.

---

## Pushing a Route

Inject `RouterService` via `AppService.router` and call `push`:

```dart
final router = ref.read(AppService.router);
router.push(RouteInput(name: RouteName.counter));
```

`RouteInput` carries the route name and any arguments to pass to the destination screen.

---

## Route Generation

`RouteScreen` (`lib/base/dependency/router/utils/route_screen.dart`) maps route names to `PageRoute` instances. For feature routes that use a bloc, `RouteScreen` also initializes the feature's bloc provider:

```dart
static PageRoute counterPageRoute(RouteSettings settings) {
  BlocProvider.counter = createAutoDisposeBloc((ref) => CounterBloc(ref));
  return MaterialPageRoute(builder: (_) => const CounterScreen());
}
```

---

## Bottom Tab Navigation

The app shell (`lib/features/root/root_screen.dart`) renders one nested `Navigator` per bottom tab. Each tab has its own navigation stack.

Tab definitions live in `NavigatorBottomTabEnum` (`lib/features/root/enums/navigation_bottom_tab_enum.dart`). Each enum value declares its `initialRoute`.

`RoutePage` (`lib/base/dependency/router/utils/route_page.dart`) provides `onGenerateRoute` handlers — one per tab — that `RootScreen` wires to the per-tab `Navigator`.

Active tab state is owned by `AppBloc.selectedBottomTabSubject`.

---

## Unknown Route

Any unrecognized route name renders `UnknownScreen` (`lib/features/unknown/unknown_screen.dart`). Register it as the fallback in your `onGenerateRoute` handlers.
