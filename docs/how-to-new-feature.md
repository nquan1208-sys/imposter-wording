# How to Add a New Feature

This guide walks through adding a new feature end-to-end. The `counter` feature (`lib/features/counter/`) is the canonical reference — look there for a working example of every step.

---

## Step 1 — Create the feature folder

```
lib/features/<name>/
  <name>_bloc.dart
  <name>_screen.dart
```

---

## Step 2 — Create the BLoC

Extend `BlocBase`. Declare state as `BehaviorSubject` fields. Expose mutation methods. Close subjects in `dispose`.

```dart
// lib/features/<name>/<name>_bloc.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:untitled/base/bloc/bloc_base.dart';

class <Name>Bloc extends BlocBase {
  final Ref ref;
  final someStateSubject = BehaviorSubject.seeded(<initial>);

  <Name>Bloc(this.ref);

  @override
  void dispose() {
    someStateSubject.close();
    super.dispose();
  }

  void doSomething() {
    someStateSubject.value = <new value>;
  }
}
```

Reference: `lib/features/counter/counter_bloc.dart`

---

## Step 3 — Create the screen

Use `ConsumerWidget`. Watch the bloc via `BlocProvider.<name>`. Use `ObsBuilder` to subscribe to subjects.

```dart
// lib/features/<name>/<name>_screen.dart
class <Name>Screen extends ConsumerWidget {
  const <Name>Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bloc = ref.watch(BlocProvider.<name>);
    return Scaffold(
      body: ObsBuilder(
        streams: [bloc.someStateSubject],
        builder: (ctx) => Text('${bloc.someStateSubject.value}'),
      ),
    );
  }
}
```

Reference: `lib/features/counter/counter_screen.dart`

---

## Step 4 — Add a route

**4a. Add the route name** in `lib/base/dependency/router/utils/route_name.dart`:

```dart
static const <name> = '<name>';
```

**4b. Add a `PageRoute` builder** in `lib/base/dependency/router/utils/route_screen.dart`. This is also where the bloc provider is initialized and registered on `BlocProvider` (declared `static late` because it is assigned here at navigation time):

```dart
static PageRoute <name>PageRoute(RouteSettings settings) {
  BlocProvider.<name> = createAutoDisposeBloc((ref) => <Name>Bloc(ref));
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => const <Name>Screen(),
  );
}
```

Also add `static late Provider<<Name>Bloc> <name>;` to `BlocProvider` in `lib/base/bloc/bloc_provider.dart`.

**4c. Register the route** in the appropriate `onGenerateRoute` handler in `lib/base/dependency/router/utils/route_page.dart`.

---

## Step 5 — Add localization strings (if needed)

Add new keys to `lib/l10n/arb/app_en.arb`:

```json
{
  "myNewString": "Hello from <Name>",
  "@myNewString": {}
}
```

Then access it in the screen:

```dart
final appLocale = ref.watch(AppService.localization);
Text(appLocale.myNewString)
```

---

## Step 6 — Run code generation

After adding Freezed models, JSON serialization, or new assets:

```sh
# Freezed models and JSON serialization
dart run build_runner build --delete-conflicting-outputs

# Type-safe asset references (if new assets were added)
dart run flutter_gen run
```

Localization files are regenerated automatically on `flutter run` / `flutter build` when `generate: true` is set in `pubspec.yaml`.

---

## Step 7 — Add bottom tab entry (optional)

If the feature needs its own bottom tab:

1. Add an entry to `NavigatorBottomTabEnum` (`lib/features/root/enums/navigation_bottom_tab_enum.dart`) with its `initialRoute`
2. Add a case to `RootScreen.buildRouteFactory` (`lib/features/root/root_screen.dart`)
3. Add a tab item to `AppBottomNavigationBar` (`lib/features/root/widgets/app_bottom_navigation_bar.dart`)
