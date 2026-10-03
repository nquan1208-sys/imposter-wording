# Architecture

Flutter mobile app with RxDart state management, Riverpod DI, and a feature-based structure.

## Tech Stack

| Layer | Package | Version |
|---|---|---|
| UI | Flutter | >= 3.41.0 |
| Language | Dart | >= 3.11.0 |
| State / streams | rxdart | ^0.28.0 |
| Dependency injection | flutter_riverpod / riverpod | ^3.3.1 / ^3.2.1 |
| Immutable models | freezed / freezed_annotation | ^3.2.5 / ^3.1.0 |
| JSON serialization | json_serializable / json_annotation | ^6.8.0 / ^4.9.0 |
| Asset code gen | flutter_gen | ^5.7.0 |
| Localization | flutter_localizations + intl | ^0.20.0 |

---

## Folder Structure

```
lib/
  main.dart
  base/                   # Core infrastructure — shared across all features
    bloc/                 # BlocBase class and provider factory
    dependency/           # App-level services and providers
      i18n/               # Localization service and provider
      router/             # Navigation service and provider
        utils/            # Route names, pages, screens, inputs
    rx/                   # ObsBuilder widget for reactive UI
  constants/              # App-wide constants (sizes, etc.)
  features/               # One folder per feature (self-contained)
    counter/
    home/
    root/                 # Shell screen with bottom navigation
    settings/
    unknown/              # Fallback/404 screen
  l10n/
    arb/                  # ARB translation source files
    gen_l10n/             # Generated localization output (do not edit)
  shared/
    bloc/                 # App-level blocs shared across features
    providers/            # Cross-feature providers
```

---

## Layer Responsibilities

### `base/`
Core infrastructure that features depend on but do not own.

- `base/bloc/bloc_base.dart` — abstract `BlocBase` class and `createAutoDisposeBloc` factory
- `base/bloc/bloc_provider.dart` — registry of all feature bloc providers
- `base/dependency/app_service.dart` — `AppService` and `AppProvider`: top-level Riverpod providers for router and i18n
- `base/rx/obs_builder.dart` — `ObsBuilder` widget: subscribes to streams and triggers rebuilds

### `features/`
Each feature folder contains its own screen(s) and bloc. Features are self-contained and access shared infrastructure through `base/`.

### `shared/`
Cross-feature blocs and providers. `shared/bloc/app_bloc.dart` owns global app state: selected bottom tab and navigator keys.

### `l10n/`
Source translations live in `lib/l10n/arb/app_en.arb`. Generated output goes to `lib/l10n/gen_l10n/` (configured in `l10n.yaml`). Never edit generated files.

---

## Dependency Injection

Riverpod is used exclusively as a DI container — not for state. Providers are declared as static constants on service/provider classes:

- `AppProvider` — raw providers for router and i18n
- `AppService` — derived providers that compose `AppProvider` dependencies
- `BlocProvider` — feature-scoped bloc providers, created with `createAutoDisposeBloc`

See `lib/base/dependency/app_service.dart` and `lib/base/bloc/bloc_provider.dart`.

---

## Code Generation

Three tools generate code that should not be edited manually:

| Tool | What it generates | Command |
|---|---|---|
| `freezed` | Immutable model classes | `dart run build_runner build` |
| `json_serializable` | `fromJson` / `toJson` methods | `dart run build_runner build` |
| `flutter_gen` | Type-safe asset references | `dart run flutter_gen run` |
| `flutter_localizations` | Localization classes | auto on `flutter run` / `flutter build` |

Generated files live alongside their source (`.freezed.dart`, `.g.dart`) or in `lib/l10n/gen_l10n/`.
