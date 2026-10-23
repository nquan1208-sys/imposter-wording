# How to Add a New Feature

`lib/features/landing/` and `lib/features/how_to_play/` show static screens. For a feature with state, follow the store pattern in [state-management.md](state-management.md).

---

## Step 1 — Create the feature folder

```
lib/features/<name>/
  <name>_screen.dart
  <name>_store.dart     # only when the feature has state
```

## Step 2 — Create the store (if needed)

Extend `StoreBase`, hold state in signals managed by `AutoDisposeManager`, expose mutation methods, and call `cancelAll()` then `super.dispose()` in `dispose()`. See [state-management.md](state-management.md).

Add `static late Provider<<Name>Store> <name>;` to `StoreProvider` (`lib/base/store/store_provider.dart`).

## Step 3 — Create the screen

Use `ConsumerWidget`. Read the store with `ref.watch(StoreProvider.<name>)`, wrap reactive parts in `SignalBuilder`, and take colors/text styles from `Theme.of(context)` / `AppColors` and spacing from `AppSpacing` / `AppEdgeInsets`.

## Step 4 — Add a route

1. `RouteName.<name>` in `route_name.dart`.
2. `RouteInput.<name>()` in `route_input.dart`.
3. `RouteScreen.<name>PageRoute` in `route_screen.dart` (assign `StoreProvider.<name>` there if the feature has a store).
4. A case in `RoutePage.onGenerateRoute` (`route_page.dart`).

## Step 5 — Add localization strings

Add each key to both `lib/l10n/arb/app_en.arb` and `lib/l10n/arb/app_vi.arb`, then run `flutter gen-l10n`. Read strings in widgets with:

```dart
final l10n = AppLocalizations.of(context);
Text(l10n.myNewString);
```

`AppLocalizations.of(context)` rebuilds when `AppStore.setLocale` changes the locale.

## Step 6 — Run code generation (if needed)

```sh
dart run build_runner build --delete-conflicting-outputs   # freezed / json
dart run flutter_gen run                                     # new assets
```

## Step 7 — Verify

```sh
flutter analyze
flutter test
```
