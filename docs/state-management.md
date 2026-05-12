# State Management

State is managed with **RxDart streams** inside **BLoC classes**. Riverpod handles dependency injection only — it does not hold state directly.

---

## BlocBase

Every feature bloc extends `BlocBase` (`lib/base/bloc/bloc_base.dart`).

`BlocBase` provides:
- `isDispose` flag — set to `true` on disposal; check this in stream callbacks to avoid acting after dispose
- `dispose()` method — override to close streams

Blocs are created with `createAutoDisposeBloc`, which wraps a Riverpod `Provider.autoDispose` and calls `dispose()` when the provider scope is released.

---

## Streams as State

State is stored in **RxDart subjects**, typically `BehaviorSubject` (emits the latest value immediately to new subscribers).

Each piece of state is a separate subject on the bloc:

```dart
// lib/features/counter/counter_bloc.dart
final counterSubject = BehaviorSubject.seeded(0);
```

Mutations are methods on the bloc:

```dart
void increment() {
  counterSubject.value++;
}
```

No `setState`, no `notifyListeners`, no `emit`. State changes are stream events.

---

## ObsBuilder

`ObsBuilder` (`lib/base/rx/obs_builder.dart`) is the UI binding layer. It subscribes to a list of streams and rebuilds its subtree whenever any stream emits.

```dart
// lib/features/counter/counter_screen.dart
ObsBuilder(
  streams: [bloc.counterSubject],
  builder: (ctx) => Text('${bloc.counterSubject.value}'),
)
```

Key behaviors:
- By default, rebuilds only when the emitted value changes (uses `.distinct()`)
- Set `rebuildOnSameValueChange: true` to rebuild on every emission regardless

---

## Riverpod for DI

Screens are `ConsumerWidget`. They use `ref.watch` to get the bloc from `BlocProvider`:

```dart
// lib/features/counter/counter_screen.dart
final bloc = ref.watch(BlocProvider.counter);
```

Bloc providers are registered in `lib/base/bloc/bloc_provider.dart`. Feature blocs use `createAutoDisposeBloc` so they are disposed when the screen is removed from the tree.

---

## App-Level State

`AppBloc` (`lib/shared/bloc/app_bloc.dart`) owns state that spans multiple features:
- `selectedBottomTabSubject` — the active bottom nav tab
- `navigatorKeysMap` — per-tab `GlobalKey<NavigatorState>` instances

`AppBloc` is registered as `BlocProvider.app` — declared `static final` (initialized immediately), unlike feature blocs which are `static late` (initialized at navigation time).

---

## Pattern Summary

| Concern | Solution |
|---|---|
| State storage | `BehaviorSubject` on a bloc |
| State mutation | Public methods on the bloc |
| UI reactivity | `ObsBuilder` subscribing to subjects |
| Bloc lifetime | `createAutoDisposeBloc` via Riverpod |
| Accessing blocs | `ref.watch(BlocProvider.x)` in `ConsumerWidget` |
| Global state | `AppBloc` in `shared/bloc/` |
